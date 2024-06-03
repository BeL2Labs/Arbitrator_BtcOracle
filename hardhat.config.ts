import "@nomicfoundation/hardhat-toolbox";
import { HardhatUserConfig } from "hardhat/config";
require('hardhat-deploy')
require('@openzeppelin/hardhat-upgrades');

import dotenv from "dotenv";
dotenv.config({ path: __dirname + '/.env' });

let { staging_key, prod_key,arbitrator } = process.env;
const config: HardhatUserConfig = {
  networks: {
    prod: {
      url: "https://api.elastos.io/esc",
      accounts: [...(prod_key ? [prod_key,arbitrator] : [])]
    },
    stage: {
      url: "https://api.elastos.io/esc",
      accounts: [...(staging_key ? [staging_key, arbitrator] : [])]
    },
    testnet: {
      url: "https://api-testnet.elastos.io/esc",
      accounts: [...(staging_key ? [staging_key, arbitrator] : [])]
    },

    hardhat: {
      chainId: 100,
      accounts: [
        ...(staging_key ? [{ privateKey: staging_key, balance: "10000000000000000000000" }] : []),
      ],
      blockGasLimit: 8000000
    }
  },

  solidity: {
    version: "0.8.20",
    settings: {
      optimizer: {
        enabled: true,
        runs: 800
      },
    },
  },
};

export default config;
