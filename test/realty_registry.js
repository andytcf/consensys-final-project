const RealtyRegistry = artifacts.require('RealtyRegistry');

const { BN, constants, expectEvent, expectRevert, balance } = require('@openzeppelin/test-helpers');

contract('ResidentialHome', async accounts => {
	const [ownerAddress, userOne, userTwo, userThree, userFour] = accounts;
	const streetName = 'Amphitheatre Parkway';
	const postCode = '94035';
	const city = 'Mountain View';
	const country = 'United States';
	const realtyType = 'Residential Home';
	const price = new BN(10000);
	const registryId = '0';
	let registry;
	let tx;
	beforeEach(async () => {
		registry = await RealtyRegistry.new({
			from: ownerAddress,
		});
		tx = await registry.register(
			streetName,
			postCode,
			city,
			country,
			realtyType,
			price,
			userOne,
			{
				from: ownerAddress,
			}
		);
	});

	describe('Registering', () => {
		describe('when called by the contract owner', () => {
			it('should emit a registration event', () => {
				expectEvent(tx, 'RegistrationAdded', {
					registryId: registryId,
					owner: userOne,
				});
			});
			it('should update ownerOf state correctly', async () => {
				assert.equal(await registry.ownerOf.call(registryId), userOne);
			});
			it('should update realtyOwned state correctly', async () => {
				const ownedRealty = await registry.realtyOwned.call(userOne, 0);
				assert.equal(ownedRealty.toString(), registryId);
			});
			it('should update realtyOwned state correctly when adding more than one registration', async () => {
				let ownedRealty = await registry.realtyOwned.call(userOne, 0);
				assert.equal(ownedRealty.toString(), registryId);
				await registry.register(
					'Street Name',
					'22222',
					'NSW',
					'AU',
					'Commercial Business',
					new BN(100000),
					userOne,
					{
						from: ownerAddress,
					}
				);
				ownedRealty = await registry.realtyOwned.call(userOne, 1);
				assert.equal(ownedRealty.toString(), '1');
			});
			it('should update idtoRealty state correctly', async () => {
				const registeredRealtyStruct = await registry.idToRealty.call(registryId);
				assert.equal(registeredRealtyStruct[0], streetName);
				assert.equal(registeredRealtyStruct[1], postCode);
				assert.equal(registeredRealtyStruct[2], city);
				assert.equal(registeredRealtyStruct[3], country);
				assert.equal(registeredRealtyStruct[4], realtyType);
				assert.equal(registeredRealtyStruct[6], price.toString());
			});
			it('should update indexOfRealty state correctly', async () => {
				const indexOfRealty = await registry.indexOfRealty.call(registryId);
				assert.equal(indexOfRealty, 0);
			});
			it('should update totalRegistrations state correctly', async () => {
				const totalRegistrations = await registry.totalRegistrations.call();
				assert.equal(totalRegistrations, 1);
			});
			it('should update currentID state correctly', async () => {
				const currentID = await registry.currentID.call();
				assert.equal(currentID, 1);
			});
		});

		describe('when not called by the contract owner', () => {
			it('should revert', async () => {
				await expectRevert(
					registry.register(
						streetName,
						postCode,
						city,
						country,
						realtyType,
						price,
						userOne,
						{
							from: userTwo,
						}
					),
					'Ownable: caller is not the owner.'
				);
			});
		});
	});

	describe('Deregistering', () => {
		beforeEach(async () => {
			tx = await registry.deregister(registryId, { from: ownerAddress });
		});
		describe('when called by the contract owner', () => {
			it('should emit a deregistration event', () => {
				expectEvent(tx, 'RegistrationRemoved', {
					registryId: registryId,
				});
			});
			it('should update ownerOf state correctly', async () => {
				assert.equal(await registry.ownerOf.call(registryId), constants.ZERO_ADDRESS);
			});
			it('should update totalRegistrations state correctly', async () => {
				const totalRegistrations = await registry.totalRegistrations.call();
				assert.equal(totalRegistrations, 0);
			});
			it('should update currentID state correctly', async () => {
				const currentID = await registry.currentID.call();
				assert.equal(currentID, 1);
			});
		});
		describe('when not called by the contract owner', () => {
			it('should revert', async () => {
				await expectRevert(
					registry.deregister(registryId, {
						from: userTwo,
					}),
					'Ownable: caller is not the owner.'
				);
			});
		});
	});

	describe('Changing Realty state', () => {
		describe('Realty owner', () => {
			it('should emit an event', async () => {
				tx = await registry.changeAvailability(registryId, { from: userOne });
				expectEvent(tx, 'RealtyStateChanged', {
					registryId: registryId,
					newState: '0',
				});
				tx = await registry.changeAvailability(registryId, { from: userOne });
				expectEvent(tx, 'RealtyStateChanged', {
					registryId: registryId,
					newState: '1',
				});
			});
			it('should successfully update Realty state', async () => {
				tx = await registry.changeAvailability(registryId, { from: userOne });
				let realty = await registry.idToRealty.call(registryId, { from: userOne });
				assert(realty.state, '0');
				tx = await registry.changeAvailability(registryId, { from: userOne });
				realty = await registry.idToRealty.call(registryId, { from: userOne });
				assert(realty.state, '1');
			});
		});
		describe('Arbitrary user', () => {
			it('should revert', async () => {
				await expectRevert(
					registry.changeAvailability(registryId, {
						from: userTwo,
					}),
					'Msg sender is not the owner of the Realty.'
				);
			});
		});
	});

	describe('Changing Realty price', () => {
		const newPrice = new BN(8888);
		describe('Realty owner', () => {
			it('should emit an event', async () => {
				tx = await registry.changePrice(registryId, newPrice, { from: userOne });
				expectEvent(tx, 'RealtyPriceUpdated', {
					registryId: registryId,
					price: newPrice,
				});
			});
			it('should successfully update Realty state', async () => {
				tx = await registry.changePrice(registryId, newPrice, { from: userOne });
				let realty = await registry.idToRealty.call(registryId, { from: userOne });
				assert(realty.price, newPrice);
			});
		});
		describe('Arbitrary user', () => {
			it('should revert', async () => {
				await expectRevert(
					registry.changePrice(registryId, newPrice, {
						from: userTwo,
					}),
					'Msg sender is not the owner of the Realty.'
				);
			});
		});
	});

	describe('Purchasing', () => {
		describe('when Realty is set for sale', () => {
			beforeEach(async () => {
				await registry.changeAvailability(registryId, { from: userOne });
				tx = await registry.purchaseRegistration(registryId, {
					from: userTwo,
					value: price,
				});
			});
			it('should emit events', async () => {
				expectEvent(tx, 'RealtyPurchased', {
					registryId: registryId,
					price: price,
					purchaser: userTwo,
				});
				expectEvent(tx, 'RealtyTransferred', {
					registryId: registryId,
					from: userOne,
					to: userTwo,
				});
				expectEvent(tx, 'FundsDeposited', {
					amount: price,
					owner: userOne,
				});
			});
			it('should update ownerOf state correctly', async () => {
				assert.equal(await registry.ownerOf.call(registryId), userTwo);
			});
			it('should update realtyOwned state correctly', async () => {
				const ownedRealty = await registry.realtyOwned.call(userTwo, 0);
				assert.equal(ownedRealty.toString(), registryId);
			});
			it('should update realtyOwned state correctly when adding more than one registration', async () => {
				let ownedRealty = await registry.realtyOwned.call(userTwo, 0);
				assert.equal(ownedRealty.toString(), registryId);
				await registry.register(
					'Street Name',
					'22222',
					'NSW',
					'AU',
					'Commercial Business',
					new BN(100000),
					userTwo,
					{
						from: ownerAddress,
					}
				);
				ownedRealty = await registry.realtyOwned.call(userTwo, 1);
				assert.equal(ownedRealty.toString(), '1');
			});
			it('should update idtoRealty state correctly', async () => {
				const registeredRealtyStruct = await registry.idToRealty.call(registryId);
				assert.equal(registeredRealtyStruct[0], streetName);
				assert.equal(registeredRealtyStruct[1], postCode);
				assert.equal(registeredRealtyStruct[2], city);
				assert.equal(registeredRealtyStruct[3], country);
				assert.equal(registeredRealtyStruct[4], realtyType);
				assert.equal(registeredRealtyStruct[6], price.toString());
			});
			it('should update indexOfRealty state correctly', async () => {
				const indexOfRealty = await registry.indexOfRealty.call(registryId);
				assert.equal(indexOfRealty, 0);
			});
			it('should update totalRegistrations state correctly', async () => {
				const totalRegistrations = await registry.totalRegistrations.call();
				assert.equal(totalRegistrations, 1);
			});
			it('should update currentID state correctly', async () => {
				const currentID = await registry.currentID.call();
				assert.equal(currentID, 1);
			});
			it('should allow revert when value is less than price', async () => {
				await registry.changeAvailability(registryId, { from: userTwo });
				await expectRevert(
					registry.purchaseRegistration(registryId, {
						from: userThree,
						value: new BN(100),
					}),
					'Insufficient value sent to purchase realty.'
				);
			});
		});

		describe('when Realty is set not available', () => {
			it('should revert', async () => {
				await expectRevert(
					registry.purchaseRegistration(registryId, {
						from: userTwo,
						value: price,
					}),
					'Realty is not for sale.'
				);
			});
		});
	});

	describe('Withdrawing', () => {
		const moreThanEnoughPrice = new BN(10100);
		describe('when there are balances', () => {
			beforeEach(async () => {
				await registry.changeAvailability(registryId, { from: userOne });
				tx = await registry.purchaseRegistration(registryId, {
					from: userTwo,
					value: moreThanEnoughPrice,
				});
			});
			it('should allow seller to withdraw their funds', async () => {
				const tracker = await balance.tracker(userOne);
				tx = await registry.withdrawFunds({ from: userOne });
				assert(tracker.delta(), price);
				expectEvent(tx, 'FundsWithdrawn', {
					amount: price,
					withdrawer: userOne,
				});
			});
			it('should allow purchasee to withdraw their funds', async () => {
				const tracker = await balance.tracker(userTwo);
				tx = await registry.withdrawFunds({ from: userTwo });
				assert(tracker.delta(), '100');
				expectEvent(tx, 'FundsWithdrawn', {
					amount: '100',
					withdrawer: userTwo,
				});
			});
		});
		describe('when there is no balance', () => {
			it('should revert if there is no balance', async () => {
				await expectRevert(
					registry.withdrawFunds({
						from: userTwo,
					}),
					'Insufficient funds to withdraw.'
				);
			});
			it('should revert if there is no balance', async () => {
				await expectRevert(
					registry.withdrawFunds({
						from: userOne,
					}),
					'Insufficient funds to withdraw.'
				);
			});
		});
	});
});
