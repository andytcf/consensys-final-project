const Registry = artifacts.require('Registry');

const { BN, constants, expectEvent, expectRevert } = require('@openzeppelin/test-helpers');

contract('ResidentialHome', async accounts => {
	const [ownerAddress, userOne, userTwo, userThree] = accounts;
	const streetName = 'Amphitheatre Parkway';
	const postCode = '94035';
	const city = 'Mountain View';
	const country = 'United States';
	const realtyType = 'Residential Home';
	const price = 10000;
	const registryId = '0';

	describe('Registering', () => {
		let registry;
		beforeEach(async () => {
			registry = await Registry.new({
				from: ownerAddress,
			});
		});

		describe('when called by the contract owner', () => {
			let tx;
			beforeEach(async () => {
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
		let registry;
		let tx;
		beforeEach(async () => {
			registry = await Registry.new({
				from: ownerAddress,
			});
			await registry.register(
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
});
