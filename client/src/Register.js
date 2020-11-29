import React, { useState } from 'react';

const Register = ({ contract, accounts }) => {
	const [streetName, setStreetName] = useState(null);
	const [postCode, setPostCode] = useState(null);
	const [city, setCity] = useState(null);
	const [country, setCountry] = useState(null);
	const [realtyType, setRealtyType] = useState(null);
	const [price, setPrice] = useState(null);
	const [owner, setOwner] = useState(null);

	const handleRegister = async event => {
		event.preventDefault();
		try {
			await contract.methods
				.register(streetName, postCode, city, country, realtyType, price, owner)
				.send({ from: accounts[0] });
		} catch (e) {
			console.log(e);
		}
	};

	return (
		<form
			style={{
				display: 'flex',
				flexDirection: 'column',
				maxWidth: 200,
				padding: 24,
				margin: 'auto',
			}}
			onSubmit={e => handleRegister(e)}
		>
			<h4>Register a Realty</h4>
			<input
				placeholder="Street Name"
				value={streetName}
				onChange={e => setStreetName(e.target.value)}
			/>
			<input
				placeholder="Post Code/ZIP"
				value={postCode}
				onChange={e => setPostCode(e.target.value)}
			/>
			<input placeholder="City" value={city} onChange={e => setCity(e.target.value)} />
			<input
				placeholder="Country"
				value={country}
				onChange={e => setCountry(e.target.value)}
			/>
			<input
				placeholder="RealtyType"
				value={realtyType}
				onChange={e => setRealtyType(e.target.value)}
			/>
			<input placeholder="Price" value={price} onChange={e => setPrice(e.target.value)} />
			<input placeholder="Owner" value={owner} onChange={e => setOwner(e.target.value)} />
			<button type="submit">register</button>
		</form>
	);
};

export default Register;
