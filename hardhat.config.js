require("dotenv").config();
require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-etherscan");
require("@nomiclabs/hardhat-waffle");
require('hardhat-spdx-license-identifier');
require('hardhat-storage-layout');
require('hardhat-log-remover');
require('hardhat-contract-sizer');
/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.6.12",
        settings: {
          optimizer: {
            enabled: true,
            runs: 2000,
          },
          outputSelection: {
            "*": {
                "*": ["storageLayout"],
            },
          },
        },
      },
      {
	version: "0.8.7",
        settings: {
          optimizer: {
            enabled: true,
            runs: 2000,
          },
          outputSelection: {
            "*": {
                "*": ["storageLayout"],
            },
          },
        },
      }
    ],
  },
  networks: {
     hardhat: {
       forking: {
         url: process.env.mainnetRPC,
         blockNumber: 13042331,
       },
       initialBaseFeePerGas: 5,
       loggingEnabled: false, 
     },
     localhost: {
       url: "http://localhost:8545",
       timeout: 120000
     },
     mainnet: {
       url: process.env.mainnetRPC,
       accounts: [
	process.env.mainnetAccountPK,
       ],
       timeout: 2147483647
     },
     goerli: {
       url: process.env.goerliRPC,
       accounts: [
	process.env.goerliAccountPK,
       ],
       timeout: 2147483647,
     },
     rinkeby: {
       url: process.env.rinkebyRPC,
       accounts: [
	process.env.rinkebyAccountPK,
       ],
       timeout: 2147483647,
     },
   },
  mocha: { timeout: 9999999999 },
  spdxLicenseIdentifier: {
    overwrite: true,
    runOnCompile: true,
  },
  etherscan: {
    apiKey: process.env.etherscanAPIKey
  }
};

