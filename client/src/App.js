import React, { useEffect, useState } from 'react';
import RealtyRegistry from './contracts/RealtyRegistry.json';
import getWeb3 from './getWeb3';

import './App.css';
import Register from './Register';

const App = () => {
	const [web3, setWeb3] = useState(null);
	const [accounts, setAccounts] = useState(null);
	const [contract, setContract] = useState(null);
	const [realties, setRealties] = useState(null);

	const initWeb3 = async () => {
		try {
			// Get network provider and web3 instance.
			const web3 = await getWeb3();

			// Use web3 to get the user's accounts.
			const accounts = await web3.eth.getAccounts();

			// Get the contract instance.
			const networkId = await web3.eth.net.getId();
			const deployedNetwork = RealtyRegistry.networks[networkId];
			const instance = new web3.eth.Contract(
				RealtyRegistry.abi,
				deployedNetwork && deployedNetwork.address
			);

			let realtiesPromised = [];
			const id = await instance.methods.currentID().call();

			for (let i = 0; i < id; i++) {
				const realty = await instance.methods.idToRealty(i).call();
				realtiesPromised.push(realty);
			}

			const realtiesResolved = await Promise.all(realtiesPromised);

			setRealties(realtiesResolved);
			setWeb3(web3);
			setAccounts(accounts);
			setContract(instance);
		} catch (error) {
			// Catch any errors for any of the above operations.
			alert(`Failed to load web3, accounts, or contract. Check console for details.`);
			console.error(error);
		}
	};

	useEffect(
		() => {
			initWeb3();
		},
		[accounts]
	);

	const handleUnregister = async id => {
		try {
			await contract.methods.deregister(id).send({ from: accounts[0] });
		} catch (error) {
			console.log(error);
		}
	};

	const handlePurchase = async (id, price) => {
		try {
			await contract.methods
				.purchaseRegistration(id)
				.send({ from: accounts[0], value: price });
		} catch (error) {
			console.log(error);
		}
	};

	const handleChangeAvailability = async id => {
		try {
			await contract.methods.changeAvailability(id).send({ from: accounts[0] });
		} catch (error) {
			console.log(error);
		}
	};

	if (!web3) {
		return <div>Loading Web3, accounts, and contract...</div>;
	}
	return (
		<div className="App">
			<h1>Web3 Realty Registry</h1>
			<Register contract={contract} accounts={accounts} />
			<hr />
			<h4>All Realties</h4>
			<div style={{ display: 'flex', flexDirection: 'row', flexWrap: 'wrap', padding: 40 }}>
				{realties.map((e, i) => {
					return (
						<div
							key={i}
							style={{
								padding: 24,
								width: 200,
								borderWidth: 2,
								borderStyle: 'solid',
								borderColor: 'black',
							}}
						>
							<div>Street Name: {e.streetName}</div>
							<div>Post Code: {e.postCode}</div>
							<div>City: {e.city}</div>
							<div>Country: {e.country}</div>
							<div>Realty Type: {e.realtyType}</div>
							<div>Price: {e.price}</div>
							<div>For Sale: {e.state === '0' ? 'Available' : 'Not For Sale'}</div>
							<div style={{ display: 'flex', flexDirection: 'column' }}>
								<button
									onClick={() => handleUnregister(e.registryId)}
									style={{ margin: 4 }}
								>
									unregister
								</button>
								<button
									onClick={() => handlePurchase(e.registryId, e.price)}
									style={{ margin: 4 }}
								>
									purchase
								</button>
								<button
									onClick={() => handleChangeAvailability(e.registryId)}
									style={{ margin: 4 }}
								>
									change availability
								</button>
							</div>
						</div>
					);
				})}
			</div>
		</div>
	);
};

export default App;
