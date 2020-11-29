const path = require('path');
const HDWalletProvider = require('@truffle/hdwallet-provider');
require('dotenv').config();

module.exports = {
	// See <http://truffleframework.com/docs/advanced/configuration>
	// to customize your Truffle configuration!
	contracts_build_directory: path.join(__dirname, 'client/src/contracts'),
	networks: {
		develop: {
			port: 8545,
		},
		ropsten: {
			provider: () => {
				return new HDWalletProvider(
					process.env['MNEMONIC'],
					`https://ropsten.infura.io/v3/${process.env['INFURA_API']}`
				);
			},
			network_id: 3,
		},
		rinkeby: {
			provider: () => {
				return new HDWalletProvider(
					process.env['MNEMONIC'],
					`https://rinkeby.infura.io/v3/${process.env['INFURA_API']}`
				);
			},
			network_id: 4,
		},
	},
	compilers: {
		solc: {
			version: '0.6.2',
		},
	},
	plugins: ['solidity-coverage', 'truffle-plugin-verify'],
	api_keys: {
		etherscan: process.env['ETHERSCAN_API'],
	},
};
