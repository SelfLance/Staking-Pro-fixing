require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();
/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  // solidity: "0.8.24",
  solidity: {
    compilers: [
      {
        version: "0.8.24",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
      {
        version: "0.8.0",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
    ],
  },
  networks: {
    hardhat: {
      // Local Hardhat network
    },
    ethereum: {
      url: process.env.INFURA_PROJECT_ID, // Infura URL for Ethereum mainnet
      accounts: [process.env.PRIVATE_KEY],
    },
    bsc: {
      url: "https://bsc-dataseed.binance.org/", // BSC mainnet URL
      accounts: [process.env.PRIVATE_KEY],
    },
    bsc_test: {
      url: "https://data-seed-prebsc-1-s1.binance.org:8545/", // BSC Testnet URL
      accounts: [process.env.PRIVATE_KEY],
    },
    kbc: {
      url: "https://YOUR_KBC_CHAIN_RPC_URL", // Replace with actual KBC chain RPC URL
      accounts: [process.env.PRIVATE_KEY],
    },
    spoila_eth: {
      url: process.env.SEPOILA_TESTNET_RPC, // Infura URL for Rinkeby testnet
      accounts: [process.env.PRIVATE_KEY],
    },
    spoila_base: {
      url: process.env.SEPOILA_TESTNET_RPC, // Infura URL for Rinkeby testnet
      accounts: [process.env.PRIVATE_KEY],
    },
    shasta: {
      url: "https://api.shasta.trongrid.io",
      privateKey: process.env.PRIVATE_KEY,
    },
    mainnet: {
      url: "https://api.trongrid.io",
      privateKey: process.env.PRIVATE_KEY,
    },
    polygon_mainnet: {
      url: `https://polygon-mainnet.infura.io/v3/${process.env.INFURA_KEY}`,
      accounts: [process.env.PRIVATE_KEY],
    },
    fauji: {
      url: `https://avalanche-fuji.infura.io/v3/${process.env.INFURA_KEY}`,
      accounts: [process.env.PRIVATE_KEY],
    },
  },
  etherscan: {
    apiKey: process.env.ETH_API_KEY,
  },
  // etherscan: {
  //   apiKey: {
  //     snowtrace: "snowtrace", // apiKey is not required, just set a placeholder
  //   },
  //   customChains: [
  //     {
  //       network: "snowtrace",
  //       chainId: 43113,
  //       urls: {
  //         apiURL:
  //           "https://api.routescan.io/v2/network/testnet/evm/43113/etherscan",
  //         browserURL: "https://avalanche.testnet.localhost:8080",
  //       },
  //     },
  //   ],
  // },
};
