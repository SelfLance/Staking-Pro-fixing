// Import required libraries and the contract artifacts
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Profitmaxpresale Contract", function () {
  let profitmaxpresale, token;
  let owner, user1, user2;

  beforeEach(async function () {
    [owner, user1, user2] = await ethers.getSigners();

    // Deploy the token contract
    const Token = await ethers.getContractFactory("ERC20Token"); // Replace with actual token contract name
    token = await Token.deploy();
    console.log("Token is Deployed", token.target);
    // await token.deployed();

    // Deploy the Profitmaxpresale contract
    const Profitmaxpresale = await ethers.getContractFactory(
      "Profitmaxpresale"
    );
    profitmaxpresale = await Profitmaxpresale.deploy(token.target);
    // await profitmaxpresale.deployed();
    console.log("PreSale Deployed: ", profitmaxpresale.target);
    console.log(
      "Balance of User 1 Before Transfer Token: ",
      await token.balanceOf(user1.address)
    );

    // Transfer some tokens to user1
    await token.transfer(user1.address, "1000000000000000000000");
    console.log(
      "Balance of User 1 Afeter Transfer Token: ",
      await token.balanceOf(user1.address)
    );
  });

  it("should allow users to stake tokens", async function () {
    // Approve tokens for staking
    await token
      .connect(user1)
      .approve(profitmaxpresale.target, "500000000000000000000");

    console.log("Owner AddresS: ", owner.address, " Staker: ", user1.address);
    // Stake tokens
    await profitmaxpresale
      .connect(user1)
      .stakeTokens("500000000000000000000", owner.address);
    console.log("Staked Token Successfully: ");
    // Check the staked amount
    const stakedAmount = await profitmaxpresale.totalInvestedAmount(
      user1.address
    );
    console.log(
      "Balance of User 1 Afeter  Staked Token: ",
      await token.balanceOf(user1.address)
    );
    expect(stakedAmount).to.equal("500000000000000000000");
  });

  it("should calculate rewards correctly and allow withdrawal after some time", async function () {
    // Approve tokens for staking
    await token
      .connect(user1)
      .approve(profitmaxpresale.target, "500000000000000000000");

    // Stake tokens
    await profitmaxpresale
      .connect(user1)
      .stakeTokens("500000000000000000000", owner.address);

    // Wait for a few seconds
    await new Promise((resolve) => setTimeout(resolve, 5000)); // 5 seconds

    // Update rewards
    // await profitmaxpresale.connect(user1).updateRewards(user1.address);

    // Check rewards
    const rewards = await profitmaxpresale.userRewards(user1.address);
    console.log(
      "Total Reward Received: ",
      await profitmaxpresale.totalRewardsReceived(user1.address)
    );
    // expect(rewards.totalRewards).to.be.gt(0);
    console.log("Rewards: ", rewards);

    // Withdraw rewards
    const initialBalance = await token.balanceOf(user1.address);
    await profitmaxpresale.connect(user1).withdraw("100");
    const finalBalance = await token.balanceOf(user1.address);
    console.log("Initial Balance :", initialBalance, finalBalance);

    // Check final balance
    expect(finalBalance).to.be.gt(initialBalance);
  });
});
