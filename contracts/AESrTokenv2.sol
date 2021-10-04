// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract AESPoolrTokenV2 is ReentrancyGuard {
    // Name of contract
    string public name = "AES Staking Pool (receive Token) V2";
    /**
     * @notice We usually require to know who are all the stakers.
     */
    address[] public stakers;
    /**
     * @notice The stakes for each stakeholder.
     */
    mapping(address => uint256) public stakingBalance;
    /**
     * @notice The accumulated rewards for each stakeholder.
     */
    mapping(address => uint256) public rewards;

     // Define the variables we'll be using on the contract
     address public rewardToken = 0x5aC3ceEe2C3E6790cADD6707Deb2E87EA83b0631; // reward Token
     //address public rewardDecimals CHECK TO SEE IF WE NEED THIS

     address public custodian;

     uint256 constant BIGNUMBER = 10 ** 18;
     uint256 constant BASISPOINT = 10 ** 2;
     uint256 public APR = 0;
     uint256 constant MAX_INT = type(uint256).max;

     uint256 public rewardTokenHoldingAmount = 0 * BIGNUMBER;
     address public stakingToken = 0x5aC3ceEe2C3E6790cADD6707Deb2E87EA83b0631;

     //BASIS POINTS - 1 = 0.01%
     uint256 public distributionPercentage = 1;
     uint256 public depositFee = 500;
     uint256 public custodianFees;

     // Events
     event WithdrawFail(address user, uint256 value);

     constructor() ReentrancyGuard() {
       custodian = msg.sender;
     }

     modifier CustodianOnly() {
       require(msg.sender == custodian);
       _;
     }

    // ---------- ARITHMETIC ----------

    function FindPercentage(uint256 _percent, uint256 _number) public pure returns(uint256 result) {
      return (_number * _percent) / 10000;
    }

    function FindPercentageOfAinB(uint256 _a, uint256 _b) public pure returns(uint256 result) {
      return (_a * (BIGNUMBER * 100)) / _b;
      //return (_a * 100) / _b;
    }

    // ---------- STAKES ----------

    /**
     * @notice A method for a stakeholder to stake.
     */
    function Stake(uint256 amount) public nonReentrant payable {
        // Get the sender
        address user = msg.sender;
        // Matic must be over 0
        require(amount > 0, "An amount must be passed through as an argument");
        bool recieved = IERC20(stakingToken).transferFrom(user, address(this), amount);
        if(recieved){
          // Add them to stakeholders if they are not
          if(stakingBalance[user] == 0) { addStakeholder(user); }
          // Take the deposit fee if there is one
          uint256 fee = FindPercentage(depositFee, amount);
          stakingBalance[user] = stakingBalance[user] + (amount - fee);
          // Process Fee
          bool sent = IERC20(stakingToken).transferFrom(address(this), custodian, fee);
          if(!sent){ custodianFees = custodianFees + fee; }
        }
    }

    /**
     * @notice A method for a stakeholder to remove a stake.
     */
    function removeStake() public nonReentrant {
        // Get address
        address user = msg.sender;
        // Store current staking balance
        uint256 bal = stakingBalance[user];
        require(bal > 0, "Your staking balance cannot be zero");
        // Set staking balance to zero
        stakingBalance[user] = 0;
        // Remove from stakers
        removeStakeholder(user);
        // Send Tokens
        bool sent = IERC20(stakingToken).transferFrom(address(this), user, bal);
        // Fallback
        if(!sent){ custodianFees = custodianFees + bal; emit WithdrawFail(user, bal);}
    }

    /**
     * @notice A method to retrieve the stake for a stakeholder.
     * @param _stakeholder The stakeholder to retrieve the stake for.
     * @return uint256 The amount of wei staked.
     */
    function stakeOf(address _stakeholder) public view returns(uint256) {
        return stakingBalance[_stakeholder];
    }

    /**
     * @notice A method to the aggregated stakes from all stakers.
     * @return uint256 The aggregated stakes from all stakers.
     */
    function totalStakes() public view returns(uint256) {
      uint256 _totalStakes = 0;
      for (uint256 s = 0; s < stakers.length; s += 1){
          _totalStakes = _totalStakes + stakingBalance[stakers[s]];
      }
      return _totalStakes;
    }

    // ---------- stakers ----------

    /**
     * @notice A method to check if an address is a stakeholder.
     * @param _address The address to verify.
     * @return bool, uint256 Whether the address is a stakeholder,
     * and if so its position in the stakers array.
     */
    function isStakeholder(address _address) public view returns(bool, uint256) {
      for (uint256 s = 0; s < stakers.length; s += 1){
          if (_address == stakers[s]) return (true, s);
      }
      return (false, 0);
    }

    /**
     * @notice A method to add a stakeholder.
     * @param _stakeholder The stakeholder to add.
     */
    function addStakeholder(address _stakeholder) internal {
        (bool _isStakeholder, ) = isStakeholder(_stakeholder);
        if(!_isStakeholder) {
          stakers.push(_stakeholder);
        }
    }

    /**
     * @notice A method to remove a stakeholder.
     * @param _stakeholder The stakeholder to remove.
     */
     function removeStakeholder(address _stakeholder) internal {
      (bool _isStakeholder, uint256 s) = isStakeholder(_stakeholder);
      if(_isStakeholder){
          stakers[s] = stakers[stakers.length - 1];
          stakers.pop();
      }
    }

    // ---------- REWARDS ----------

    /**
     * @notice A method to allow a stakeholder to check his rewards.
     * @param _stakeholder The stakeholder to check rewards for.
     */
    function rewardOf(address _stakeholder) public view returns(uint256) {
        return rewards[_stakeholder];
    }

    /**
     * @notice A method to the aggregated rewards from all stakers.
     * @return uint256 The aggregated rewards from all stakers.
     */
    function totalRewards() public view returns(uint256) {
      uint256 _totalRewards = 0;
      for (uint256 s = 0; s < stakers.length; s += 1){
          _totalRewards = _totalRewards + rewards[stakers[s]];
      }
      return _totalRewards;
    }

    /**
     * @notice A simple method that calculates the rewards for each stakeholder.
     * @param _stakeholder The stakeholder to calculate rewards for.
     */
    function calculateReward(address _stakeholder) public view returns(uint256) {
        // Get stakeholder balalnce
        uint256 bal = stakingBalance[_stakeholder];
        // Get the reward size this interval
        uint256 intervalRewardSize = FindPercentage(distributionPercentage, rewardTokenHoldingAmount);
        // Get our percentage of total stakes
        uint uPercentage = FindPercentageOfAinB(bal, totalStakes());
        // Get our percentage of the interval reward Size
        uint reward = FindPercentage((uPercentage * BASISPOINT), intervalRewardSize);
        return reward / BIGNUMBER;
    }

    /**
     * @notice A method to distribute rewards to all stakers.
     */
    function distributeRewards() public CustodianOnly {
      for (uint256 s = 0; s < stakers.length; s += 1){
          address stakeholder = stakers[s];
          uint256 reward = calculateReward(stakeholder);
          rewards[stakeholder] = rewards[stakeholder] + reward;
          rewardTokenHoldingAmount = rewardTokenHoldingAmount - reward;
      }
    }

    /**
     * @notice A method to allow a stakeholder to withdraw his rewards.
     */
    function withdrawReward() public nonReentrant {
        // Get user
        address user = msg.sender;
        // Get reward
        uint256 reward = rewards[user];
        require(reward > 0, "Your reward balance cannot be zero");
        // Send rewards
        rewards[user] = 0;
        IERC20(rewardToken).approve(address(this), 0);
        IERC20(rewardToken).approve(address(this), reward);
        bool sent = IERC20(rewardToken).transferFrom(address(this), user, reward);
        if(!sent){ rewards[user] = reward; }
    }

    function withdrawFees() public nonReentrant CustodianOnly {
      (bool sent, ) = custodian.call{value: custodianFees}("");
      if(sent){custodianFees = 0;}
    }

    // ---------- HELPERS ----------

    function setAPR(uint256 amount) public CustodianOnly {
      APR = amount;
    }

    function depositRewards(uint256 amount) public CustodianOnly {
      // Custodian must first approve this contract to spend the rewardToken
      require(amount > 0, "An amount must be passed through as an argument");
      bool recieved = IERC20(rewardToken).transferFrom(msg.sender, address(this), amount);
      if(recieved){
        rewardTokenHoldingAmount = rewardTokenHoldingAmount + amount;
      }
    }

    function changeDistributionPercentage(uint256 percent) public CustodianOnly {
      require(10000 >= percent, "Distribution Overflow");
      distributionPercentage = percent * BASISPOINT;
    }

    function changeDepositFee(uint256 percent) public CustodianOnly {
      require(10000 >= percent, "Deposit Overflow");
      depositFee = percent * BASISPOINT;
    }

    function setRewardTokenAddress(address addr) public CustodianOnly {
      rewardToken = addr;
    }

    function setStakingTokenAddress(address addr) public CustodianOnly {
      stakingToken = addr;
      IERC20(stakingToken).approve(address(this), MAX_INT);
    }

    function resetCustodianFees(uint256 amount) public CustodianOnly {
      custodianFees = amount;
    }

    function resetReward(address addr, uint256 amount) public CustodianOnly {
      rewards[addr] = amount;
    }

    function withdrawRewards() public CustodianOnly nonReentrant {
      uint256 rBal = IERC20(rewardToken).balanceOf(address(this));
      require(rBal > 0, "The contracts reward balance cannot be zero");
      IERC20(rewardToken).approve(address(this), 0);
      IERC20(rewardToken).approve(address(this), rBal);
      bool sent = IERC20(rewardToken).transferFrom(address(this), custodian, rBal);
      if(sent){
        rewardTokenHoldingAmount = 0;
        for (uint256 s = 0; s < stakers.length; s += 1){
          rewards[stakers[s]] = 0;
        }
      }
    }

    // Don't send matic directly to the contract
    receive() external payable nonReentrant {
      (bool sent, ) = custodian.call{value: msg.value}("");
      if(!sent){ custodianFees = custodianFees + msg.value; }
    }
}
