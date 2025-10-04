require("dotenv").config();
require("@nomicfoundation/hardhat-toolbox");
require("@vechain/sdk-hardhat-plugin");
const { VET_DERIVATION_PATH } = require("@vechain/sdk-core");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.8.20",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          },
          evmVersion: "paris"
        }
      }
    ]
  },
  networks: {
    vechain_testnet: {
      url: "https://testnet.vechain.org",
      accounts: {
        mnemonic: process.env.MNEMONIC,
        path: VET_DERIVATION_PATH,
        count: 10,
        initialIndex: 0
      }
    },
    vechain_mainnet: {
      url: "https://mainnet.vechain.org",
      accounts: {
        mnemonic: process.env.MNEMONIC,
        path: VET_DERIVATION_PATH,
        count: 10,
        initialIndex: 0
      }
    }
  }
};
