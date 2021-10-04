const { expect } = require("chai");
const { ethers } = require("hardhat");


describe("rTokenPool", function () {
  let rTokenPool, rTokenPoolContract, owner, wallet1, wallet2, wallet3;
  let tenUnits = ethers.utils.parseUnits("10");
  let fiveUnits = ethers.utils.parseUnits("5");
  let hundredUnits = ethers.utils.parseUnits("100");
  let thousandUnits = ethers.utils.parseUnits("1000");
  let eightyUnits = ethers.utils.parseUnits("80");
  let twentyUnits = ethers.utils.parseUnits("20");
  let twentyFiveUnits = ethers.utils.parseUnits("25");
  let fortyUnits = ethers.utils.parseUnits("40");
  let fiftyUnits = ethers.utils.parseUnits("50");
  let maxUnits = ethers.utils.parseUnits("10000000000000000000000");

  beforeEach(async () => {
    // Deploy Contracts before we start tests
    rTokenPool = await ethers.getContractFactory("AESPoolrTokenV2");
    rTokenPoolContract = await rTokenPool.deploy();
    aesToken = await ethers.getContractFactory("AES");
    aesTokenContract = await aesToken.deploy();
    usdcToken = await ethers.getContractFactory("USDC");
    usdcTokenContract = await usdcToken.deploy();
    [owner, wallet1, wallet2, wallet3] = await ethers.getSigners();
  });

  it("Should perform correct arithmetic", async function () {
    let result = await rTokenPoolContract.FindPercentage(ethers.utils.parseUnits("12.5"), ethers.utils.parseUnits("135.75"));
    expect(Number(ethers.utils.formatUnits(result, 34)).toFixed(4)).to.equal("16.9688");
    let resultB = await rTokenPoolContract.FindPercentageOfAinB(ethers.utils.parseUnits("13.75"), ethers.utils.parseUnits("57.5"));
    expect(Number(ethers.utils.formatUnits(resultB)).toFixed(4)).to.equal("23.9130");
    let resultC = await rTokenPoolContract.FindPercentage(ethers.utils.parseUnits("7.5"), ethers.utils.parseUnits("0.5"));
    //console.log(ethers.utils.formatUnits(resultC, 34));
  });

  it("Should calculate correctly, give correct rewards and unstake tokens (rToken)", async function () {
    // Set Reward Token Address
    await rTokenPoolContract.setRewardTokenAddress(aesTokenContract.address);
    // Set Staking Token Address
    await rTokenPoolContract.setStakingTokenAddress(usdcTokenContract.address);
    //console.log(ethers.utils.formatUnits(await aesTokenContract.balanceOf(owner.address)));
    // Transfer Reward Tokens
    await aesTokenContract.approve(rTokenPoolContract.address, maxUnits); // Max AES
    await rTokenPoolContract.depositRewards(ethers.utils.parseUnits("12750.0"));
    expect(ethers.utils.formatUnits(await rTokenPoolContract.rewardTokenHoldingAmount())).to.equal("12750.0");
    //console.log(ethers.utils.formatUnits(await rTokenPoolContract.rewardTokenHoldingAmount()));
    // Approve and Stake
    await usdcTokenContract.approve(rTokenPoolContract.address, maxUnits);
    await rTokenPoolContract.Stake(hundredUnits);
    //console.log(ethers.utils.formatUnits(await usdcTokenContract.balanceOf(owner.address)));
    // Mint USDC
    let walletOneUSDCContract = usdcTokenContract.connect(wallet1);
    await walletOneUSDCContract.Mint();
    // Approve and Stake w1
    await walletOneUSDCContract.approve(rTokenPoolContract.address, maxUnits);
    let temporaryContract = rTokenPoolContract.connect(wallet1);
    await temporaryContract.Stake(hundredUnits);
    // Distribute
    await rTokenPoolContract.distributeRewards();
    // Collect
    let resultB = await rTokenPoolContract.rewards(owner.address);
    expect(Number(ethers.utils.formatUnits(resultB)).toFixed(4)).to.equal("0.6375");
    await temporaryContract.withdrawReward();
    let resultC = Number(ethers.utils.formatUnits(await aesTokenContract.balanceOf(wallet1.address))).toFixed(4);
    expect(resultC).to.equal("0.6375");
    // Unstake
    let oldUSDCBal = Number(ethers.utils.formatUnits(await usdcTokenContract.balanceOf(wallet1.address))).toFixed();
    //console.log(oldUSDCBal);
    //console.log(Number(ethers.utils.formatUnits(await rTokenPoolContract.stakingBalance(wallet1.address))).toFixed());
    await temporaryContract.removeStake();
    let newUSDCBal =  Number(ethers.utils.formatUnits(await usdcTokenContract.balanceOf(wallet1.address))).toFixed();
    expect(newUSDCBal).to.equal("9995");
    //await
    //let aesBalOriginal = Math.round(ethers.utils.formatUnits(await aesTokenContract.balanceOf(owner.address)));
    //console.log(aesBalOriginal);
  });

});
