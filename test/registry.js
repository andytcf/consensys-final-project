const Registry = artifacts.require('Registry');

const { BN, constants, expectEvent, expectRevert } = require('@openzeppelin/test-helpers');

contract('ResidentialHome', async accounts => {
	const [ownerAddress, userOne, userTwo, userThree] = accounts;

	const streetName = 'Amphitheatre Parkway';
	const postCode = '94035';
	const city = 'Mountain View';
	const country = 'United States';
	const realtyId = new BN(0);
	const realtyType = 'Residential Home';

	describe('Registering', () => {
		let registry;
		beforeEach(async () => {
			registry = await Registry.new({
				from: ownerAddress,
			});
		});
		it('should allow an owner to register', async () => {
			const tx = await registry.register(
				streetName,
				postCode,
				city,
				country,
				realtyType,
				userOne,
				{
					from: ownerAddress,
				}
			);
			expectEvent(tx, 'RegistrationAdded', {
				registryId: realtyId,
				owner: userOne,
			});
			assert.equal(await registry.ownerOf.call(realtyId), userOne);
			const ownedRealty = await registry.realtyOwned.call(userOne, 0);
			assert.equal(ownedRealty.length, 1);
			const registeredRealtyStruct = await registry.idToRealty.call(realtyId);
			assert.equal(registeredRealtyStruct[0], streetName);
			assert.equal(registeredRealtyStruct[1], postCode);
			assert.equal(registeredRealtyStruct[2], city);
			assert.equal(registeredRealtyStruct[3], country);
			assert.equal(registeredRealtyStruct[4], realtyType);
		});
		it('should prevent a non-owner from registering', async () => {
			await expectRevert(
				registry.register(streetName, postCode, city, country, realtyType, userOne, {
					from: userTwo,
				}),
				'Ownable: caller is not the owner.'
			);
		});
	});
});
