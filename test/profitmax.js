// Import required libraries and the contract artifacts
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Profitmaxpresale Contract", function () {
  let profitmaxpresale, token;
  let owner, user1, user2, user3, user4, user5, user6;

  beforeEach(async function () {
    [owner, user1, user2, user3, user4, user5, user6] =
      await ethers.getSigners();

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
    await token.transfer(user1.address, "10000000000000000000000");
    await token.transfer(user2.address, "10000000000000000000000");
    await token.transfer(user3.address, "10000000000000000000000");

    await token.transfer(user4.address, "10000000000000000000000");
    await token.transfer(user5.address, "10000000000000000000000");
    await token.transfer(user6.address, "10000000000000000000000");

    console.log(
      "Balance of User 1 Afeter Transfer Token: ",
      await token.balanceOf(user1.address)
    );
    await token
      .connect(user1)
      .approve(profitmaxpresale.target, "5000000000000000000000");

    // Stake tokens
    // await profitmaxpresale
    //   .connect(user1)
    //   .stakeTokens("500000000000000000000", owner.address);
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

  // function sleep(ms) {
  //   return new Promise((resolve) => setTimeout(resolve, ms));
  // }
  async function advanceTimeAndBlock(time) {
    await network.provider.send("evm_increaseTime", [time]);
    await network.provider.send("evm_mine");
  }
  it("should calculate rewards correctly and allow withdrawal after some time", async function () {
    // await sleep(61000); // Update rewards
    // Check rewards
    await advanceTimeAndBlock(240);

    const rewards = await profitmaxpresale.userRewards(user1.address);
    console.log(
      "Total Reward Received: ",
      await profitmaxpresale.totalRewardsReceived(user1.address)
    );
    // expect(rewards.totalRewards).to.be.gt(0);
    console.log("Rewards: ", rewards);
    console.log(
      "Check Rewards: ",
      await profitmaxpresale.checkRewards(user1.address)
    );
    // Withdraw rewards
    console.log(
      "Withdrawable Balance: ",
      await profitmaxpresale.withdrawable(user1.address)
    );
    const initialBalance = await token.balanceOf(user1.address);
    await profitmaxpresale.connect(user1).withdraw("76");
    const finalBalance = await token.balanceOf(user1.address);
    console.log("Initial Balance :", initialBalance, finalBalance);
    // Check final balance
    expect(finalBalance).to.be.gt(initialBalance);
  });
  it("Should Multi Stacking and Show Data", async function () {
    // await sleep(61000); // Update rewards
    // Check rewards
    await advanceTimeAndBlock(240);

    await profitmaxpresale
      .connect(user1)
      .stakeTokens("100000000000000000000", owner.address);
    // });
    await profitmaxpresale
      .connect(user1)
      .stakeTokens("200000000000000000000", owner.address);
    // });
    // Retrieve the stakes for user1
    const stakes = await profitmaxpresale.getUserStakes(user1.address);
    //
    console.log("Stakes Data Coming from 3 stakes: ", stakes);
    // Check final balance
    // expect(finalBalance).to.be.gt(initialBalance);
  });

  it.only("Should Show Only Direct Referer Only ", async function () {
    // First
    await token
      .connect(user1)
      .approve(profitmaxpresale.target, "5000000000000000000000");

    await profitmaxpresale
      .connect(user1)
      .stakeTokens("100000000000000000000", owner.address);
    // });
    // Second
    await token
      .connect(user2)
      .approve(profitmaxpresale.target, "5000000000000000000000");
    await profitmaxpresale
      .connect(user2)
      .stakeTokens("200000000000000000000", user1.address);
    // });
    // // Third
    await token
      .connect(user3)
      .approve(profitmaxpresale.target, "5000000000000000000000");
    await profitmaxpresale
      .connect(user3)
      .stakeTokens("200000000000000000000", user1.address);
    // // });
    // // Fourth
    // await token
    //   .connect(user4)
    //   .approve(profitmaxpresale.target, "5000000000000000000000");
    // await profitmaxpresale
    //   .connect(user4)
    //   .stakeTokens("200000000000000000000", user1.address);
    // // });
    // //Fifth
    // await token
    //   .connect(user5)
    //   .approve(profitmaxpresale.target, "5000000000000000000000");
    // await profitmaxpresale
    //   .connect(user5)
    //   .stakeTokens("200000000000000000000", user2.address);
    // // });
    // // Sixth
    // await token
    //   .connect(user6)
    //   .approve(profitmaxpresale.target, "5000000000000000000000");
    // await profitmaxpresale
    //   .connect(user6)
    //   .stakeTokens("200000000000000000000", user2.address);
    // // });
    await advanceTimeAndBlock(240);

    // await profitmaxpresale.connect(user1).withdraw(10);
    console.log(
      "Referer for Owner: ",
      await profitmaxpresale.showAllDirectChild(owner.address),
      " Level Income: ",
      await profitmaxpresale.updateLevelIncome(owner.address),
      "USer1 and Owner: ",
      user1.address,
      owner.address
    );
    // console.log(
    //   "Referer for User1: ",
    //   await profitmaxpresale.showAllDirectChild(user1.address),
    //   " Level Income: ",
    //   await profitmaxpresale.updateLevelIncome(user1.address)
    // );
    // console.log(
    //   "Referer for User2: ",
    //   await profitmaxpresale.showAllDirectChild(user2.address),
    //   " Level Income: ",
    //   await profitmaxpresale.updateLevelIncome(user2.address)
    // );
    // console.log(
    //   "Referer for User 3: ",
    //   await profitmaxpresale.showAllDirectChild(user3.address),
    //   " Level Income: ",
    //   await profitmaxpresale.updateLevelIncome(user3.address)
    // );
  });
});
