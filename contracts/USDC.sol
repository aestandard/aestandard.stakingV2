pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract USDC is ERC20 {
    constructor() ERC20("United States Dollor Coin", "USDC") {
        _mint(msg.sender, 10000 * (10 ** 18));
    }

    function Mint() public {
      _mint(msg.sender, 10000 * (10 ** 18));
    }
}
