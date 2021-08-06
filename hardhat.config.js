require("dotenv").config();
require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-etherscan");
require("@nomiclabs/hardhat-waffle");
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
        },
      },
    ],
  },
  networks: {
     hardhat: {
       forking: {
         url: process.env.mainnetRPC,
         blockNumber: 12821535,
       },
       loggingEnabled: false,
     },
     localhost: {
       url: "http://localhost:8545",
       timeout: 120000
     },
     mainnet: {
       url: process.env.mainnetRPC,
       accounts: [
	       process.env.mainnetAccountPK
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
   },
  mocha: { timeout: 9999999999 },
};

