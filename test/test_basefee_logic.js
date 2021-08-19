const { expect } = require("chai");
const { ethers, run } = require("hardhat");

describe("Start of tests", () => {

	let BasefeeLogicFactory;
	let BasefeeLogicContract;
	let BasefeeProxyFactory;
	let BasefeeProxyContract;

	let firstWallet;

	let signerArray = [];

	let timestamp = async () => {
		return (await ethers.provider.getBlock('latest')).timestamp;
	}

	let sendr = async (method, params) => {
		return await ethers.provider.send(method, params);
	}

	let clog = (...x) => { console.log(x); }

	let pE = (x) => {
		return ethers.utils.parseEther(`${x}`);
	}

	before(async () => {
		signerArray = await ethers.getSigners();
		firstWallet = signerArray[0];

		BasefeeLogicFactory = await ethers.getContractFactory("BASEFEE_LOGIC");
		BasefeeLogicContract = await BasefeeLogicFactory.deploy();
		await BasefeeLogicContract.deployTransaction.wait(3);

		clog("Contract should be at address: ", BasefeeLogicContract.address);

		await run("verify:verify", {
			address: BasefeeLogicContract.address
		});

		BasefeeProxyFactory = await ethers.getContractFactory("BASEFEE_PROXY");
		BasefeeProxyContract = await BasefeeProxyFactory.deploy(BasefeeLogicContract.address);
		await BasefeeProxyContract.deployTransaction.wait(3);

		await run("verify:verify", {
			address: BasefeeProxyContract.address,
			contract: "contracts/basefee/BASEFEE_PROXY.sol:BASEFEE_PROXY",
			constructorArguments: [
				BasefeeLogicContract.address
			]
		});
	});

	describe("Test basefee contracts", () => {
		it("Both contracts should have variables set correctly", async () => {
			expect(await BasefeeProxyContract.logic()).to.equal(BasefeeLogicContract.address);
		});

		it("Logic should return the correct basefee", async () => {
			const basefee_Contract = await BasefeeLogicContract.RETURN_BASEFEE();
			const block = await ethers.provider.getBlock();
			const basefee_Provider = block.baseFeePerGas;
			expect(basefee_Contract).to.equal(basefee_Provider);
		});

		it("Proxy should return the correct basefee", async () => {
			const basefee_Contract = await BasefeeProxyContract.RETURN_BASEFEE();
			const block = await ethers.provider.getBlock();
			const basefee_Provider = block.baseFeePerGas;
			expect(basefee_Contract).to.equal(basefee_Provider);
		});
	});
});