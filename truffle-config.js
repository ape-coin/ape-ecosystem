require('dotenv').config()
var PrivateKeyProvider = require("truffle-privatekey-provider");

module.exports = {
  networks: {
    mainnet: {
      provider: () => new PrivateKeyProvider(process.env.PRIV_KEY, `https://mainnet.infura.io/v3/${process.env.INFURA_KEY}`),
      network_id: "1",       // Any network (default: none)
      gasPrice: "30000000000"
    }
  },

  mocha: {
    reporter: 'eth-gas-reporter',
  },

  compilers: {
    solc: {
      version: "0.6.12",    
      settings: {
        optimizer: {
          enabled: true,
          runs: 200
        },
        evmVersion: "byzantium"
      }
    }
  },
   plugins: [
    'truffle-plugin-verify'
  ],
  api_keys: {
    etherscan: process.env.ETHERSCAN_KEY
  }
}
