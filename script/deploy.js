const hre = require("hardhat");

async function main() {
  // Get the contract factories
  //   const [deployer] = await hre.ethers.getSigners();
  //   let deployer = "0x1640fc5781B960400b9B0cAE7Cd72b21B2E246e7";
  //   const WETH = await hre.ethers.getContractFactory("MockWETH");
  // const ERC20Token = await hre.ethers.getContractFactory("ERC20Token");

  //   let routerAddress = "0xE7C6301109bBc3C75127c6EDaFE78CcF822D81AE";
  // const erc20 = await ERC20Token.deploy();
  // console.log("Token Deployed To: ", erc20.target);

  const Staking = await hre.ethers.getContractFactory("Profitmaxpresale");
  const stake = await Staking.deploy(
    "0x5C2Db6D26D5A86392777368bFED9A8f1afC87A4F"
  );

  console.log("Staking Contract deployed to:", stake.target);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
