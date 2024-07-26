const { expect } = require("chai");
const { ethers } = require("hardhat");

async function advanceTimeAndBlock(time) {
  await ethers.provider.send("evm_increaseTime", [time]);
  await ethers.provider.send("evm_mine");
}

describe("Profitmaxpresale", function () {
  let Profitmaxpresale,
    profitmaxpresale,
    token,
    admin,
    user1,
    user2,
    user3,
    user4;

  beforeEach(async function () {
    [admin, user1, user2, user3, user4, _] = await ethers.getSigners();

    const Token = await ethers.getContractFactory("ERC20Mock"); // Replace with your ERC20 token contract
    token = await Token.deploy(
      "Mock Token",
      "MCK",
      admin.address,
      ethers.utils.parseEther("1000000")
    );
    await token.deployed();

    Profitmaxpresale = await ethers.getContractFactory("Profitmaxpresale");
    profitmaxpresale = await Profitmaxpresale.deploy(token.address);
    await profitmaxpresale.deployed();

    await token.transfer(user1.address, ethers.utils.parseEther("1000"));
    await token.transfer(user2.address, ethers.utils.parseEther("1000"));
    await token.transfer(user3.address, ethers.utils.parseEther("1000"));
    await token.transfer(user4.address, ethers.utils.parseEther("1000"));

    await token
      .connect(user1)
      .approve(profitmaxpresale.address, ethers.utils.parseEther("1000"));
    await token
      .connect(user2)
      .approve(profitmaxpresale.address, ethers.utils.parseEther("1000"));
    await token
      .connect(user3)
      .approve(profitmaxpresale.address, ethers.utils.parseEther("1000"));
    await token
      .connect(user4)
      .approve(profitmaxpresale.address, ethers.utils.parseEther("1000"));
  });

  describe("updateLevelIncome", function () {
    it("should correctly update level income for multiple levels", async function () {
      await profitmaxpresale
        .connect(user1)
        .stakeTokens(ethers.utils.parseEther("100"), admin.address);
      await advanceTimeAndBlock(60);
      await profitmaxpresale
        .connect(user2)
        .stakeTokens(ethers.utils.parseEther("100"), user1.address);
      await advanceTimeAndBlock(60);
      await profitmaxpresale
        .connect(user3)
        .stakeTokens(ethers.utils.parseEther("100"), user2.address);
      await advanceTimeAndBlock(60);
      await profitmaxpresale
        .connect(user4)
        .stakeTokens(ethers.utils.parseEther("100"), user3.address);
      await advanceTimeAndBlock(60);

      // Verify the level incomes at different levels
      const levelIncomeUser1 = await profitmaxpresale.updateLevelIncome(
        user1.address
      );
      const levelIncomeUser2 = await profitmaxpresale.updateLevelIncome(
        user2.address
      );
      const levelIncomeUser3 = await profitmaxpresale.updateLevelIncome(
        user3.address
      );

      console.log(
        "Level Income User 1:",
        ethers.utils.formatEther(levelIncomeUser1)
      );
      console.log(
        "Level Income User 2:",
        ethers.utils.formatEther(levelIncomeUser2)
      );
      console.log(
        "Level Income User 3:",
        ethers.utils.formatEther(levelIncomeUser3)
      );

      expect(levelIncomeUser1).to.be.gt(0);
      expect(levelIncomeUser2).to.be.gt(0);
      expect(levelIncomeUser3).to.be.gt(0);

      // Further checks can be added to ensure accuracy
    });

    it("should correctly handle updates over time", async function () {
      await profitmaxpresale
        .connect(user1)
        .stakeTokens(ethers.utils.parseEther("100"), admin.address);
      await advanceTimeAndBlock(60);
      await profitmaxpresale
        .connect(user2)
        .stakeTokens(ethers.utils.parseEther("100"), user1.address);
      await advanceTimeAndBlock(120);
      await profitmaxpresale
        .connect(user3)
        .stakeTokens(ethers.utils.parseEther("100"), user2.address);
      await advanceTimeAndBlock(180);
      await profitmaxpresale
        .connect(user4)
        .stakeTokens(ethers.utils.parseEther("100"), user3.address);
      await advanceTimeAndBlock(240);

      // Verify the level incomes after significant time has passed
      const levelIncomeUser1 = await profitmaxpresale.updateLevelIncome(
        user1.address
      );
      const levelIncomeUser2 = await profitmaxpresale.updateLevelIncome(
        user2.address
      );
      const levelIncomeUser3 = await profitmaxpresale.updateLevelIncome(
        user3.address
      );

      console.log(
        "Level Income User 1:",
        ethers.utils.formatEther(levelIncomeUser1)
      );
      console.log(
        "Level Income User 2:",
        ethers.utils.formatEther(levelIncomeUser2)
      );
      console.log(
        "Level Income User 3:",
        ethers.utils.formatEther(levelIncomeUser3)
      );

      expect(levelIncomeUser1).to.be.gt(0);
      expect(levelIncomeUser2).to.be.gt(0);
      expect(levelIncomeUser3).to.be.gt(0);

      // Further checks can be added to ensure accuracy
    });

    it("should calculate level income correctly after multiple stakes and updates", async function () {
      await profitmaxpresale
        .connect(user1)
        .stakeTokens(ethers.utils.parseEther("100"), admin.address);
      await advanceTimeAndBlock(60);
      await profitmaxpresale
        .connect(user1)
        .stakeTokens(ethers.utils.parseEther("200"), admin.address);
      await advanceTimeAndBlock(60);
      await profitmaxpresale
        .connect(user2)
        .stakeTokens(ethers.utils.parseEther("100"), user1.address);
      await advanceTimeAndBlock(60);
      await profitmaxpresale
        .connect(user3)
        .stakeTokens(ethers.utils.parseEther("100"), user2.address);
      await advanceTimeAndBlock(60);
      await profitmaxpresale
        .connect(user4)
        .stakeTokens(ethers.utils.parseEther("100"), user3.address);
      await advanceTimeAndBlock(60);

      // Verify the level incomes after multiple stakes
      const levelIncomeUser1 = await profitmaxpresale.updateLevelIncome(
        user1.address
      );
      const levelIncomeUser2 = await profitmaxpresale.updateLevelIncome(
        user2.address
      );
      const levelIncomeUser3 = await profitmaxpresale.updateLevelIncome(
        user3.address
      );

      console.log(
        "Level Income User 1:",
        ethers.utils.formatEther(levelIncomeUser1)
      );
      console.log(
        "Level Income User 2:",
        ethers.utils.formatEther(levelIncomeUser2)
      );
      console.log(
        "Level Income User 3:",
        ethers.utils.formatEther(levelIncomeUser3)
      );

      expect(levelIncomeUser1).to.be.gt(0);
      expect(levelIncomeUser2).to.be.gt(0);
      expect(levelIncomeUser3).to.be.gt(0);

      // Further checks can be added to ensure accuracy
    });
  });
});
