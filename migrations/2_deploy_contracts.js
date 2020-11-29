const RealtyRegistry = artifacts.require('RealtyRegistry');

module.exports = function(deployer, network, accounts) {
	deployer.deploy(RealtyRegistry, {
		from: accounts[0],
	});
};
