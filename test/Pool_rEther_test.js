const { expect } = require("chai");
const { ethers } = require("hardhat");


describe("rEtherPool", function () {
  let rEtherPool, rEtherPoolContract, owner, wallet1, wallet2, wallet3;
  let tenUnits = ethers.utils.parseUnits("10");
  let fiveUnits = ethers.utils.parseUnits("5");
  let hundredUnits = ethers.utils.parseUnits("100");
  let thousandUnits = ethers.utils.parseUnits("1000");
  let eightyUnits = ethers.utils.parseUnits("80");
  let twentyUnits = ethers.utils.parseUnits("20");
  let twentyFiveUnits = ethers.utils.parseUnits("25");
  let fortyUnits = ethers.utils.parseUnits("40");
  let fiftyUnits = ethers.utils.parseUnits("50");

  beforeEach(async () => {
    // Deploy Contracts before we start tests
    rEtherPool = await ethers.getContractFactory("AESPoolrEtherV2");
    rEtherPoolContract = await rEtherPool.deploy();
    aesToken = await ethers.getContractFactory("AES");
    aesTokenContract = await aesToken.deploy();
    [owner, wallet1, wallet2, wallet3] = await ethers.getSigners();
  });

  it("Should perform correct arithmetic", async function () {
    let result = await rEtherPoolContract.FindPercentage(ethers.utils.parseUnits("12.5"), ethers.utils.parseUnits("135.75"));
    expect(Number(ethers.utils.formatUnits(result, 34)).toFixed(4)).to.equal("16.9688");
    let resultB = await rEtherPoolContract.FindPercentageOfAinB(ethers.utils.parseUnits("13.75"), ethers.utils.parseUnits("57.5"));
    expect(Number(ethers.utils.formatUnits(resultB)).toFixed(4)).to.equal("23.9130");
    let resultC = await rEtherPoolContract.FindPercentage(ethers.utils.parseUnits("7.5"), ethers.utils.parseUnits("0.5"));
    //console.log(ethers.utils.formatUnits(resultC, 34));

  });

  it("Should calculate correctly, give correct rewards and unstake ether (rEther)", async function () {

    // Set Reward Token Address
    await rEtherPoolContract.setRewardTokenAddress(aesTokenContract.address);
    //console.log(ethers.utils.formatUnits(await aesTokenContract.balanceOf(owner.address)));
    // Transfer Reward Tokens
    await aesTokenContract.approve(rEtherPoolContract.address, ethers.utils.parseUnits("10000000000000000000000")); // Max AES
    await rEtherPoolContract.depositRewards(ethers.utils.parseUnits("12750.0"));
    expect(ethers.utils.formatUnits(await rEtherPoolContract.rewardTokenHoldingAmount())).to.equal("12750.0");
    //console.log(ethers.utils.formatUnits(await rEtherPoolContract.rewardTokenHoldingAmount()));
    // Stake
    await rEtherPoolContract.Stake({ value: hundredUnits });
    let temporaryContract = rEtherPoolContract.connect(wallet1);
    await temporaryContract.Stake({ value: hundredUnits });
    // Distribute
    await rEtherPoolContract.distributeRewards();
    // Collect
    let resultB = await rEtherPoolContract.rewards(owner.address);
    expect(Number(ethers.utils.formatUnits(resultB)).toFixed(4)).to.equal("0.6375");
    await temporaryContract.withdrawReward();
    let resultC = Number(ethers.utils.formatUnits(await aesTokenContract.balanceOf(wallet1.address))).toFixed(4);
    expect(resultC).to.equal("0.6375");
    // Unstake
    let oldMaticBal = Number(ethers.utils.formatUnits(await wallet1.getBalance())).toFixed();
    //console.log(Number(ethers.utils.formatUnits(await rEtherPoolContract.stakingBalance(wallet1.address))).toFixed());
    await temporaryContract.removeStake();
    let newMaticBal = Number(ethers.utils.formatUnits(await wallet1.getBalance())).toFixed();
    expect(newMaticBal).to.equal("9995");
    //await
    //let aesBalOriginal = Math.round(ethers.utils.formatUnits(await aesTokenContract.balanceOf(owner.address)));
    //console.log(aesBalOriginal);
  });


});
