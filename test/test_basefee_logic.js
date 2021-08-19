const { expect } = require("chai");
const { ethers } = require("hardhat");
const { BigNumber } = require("@ethersproject/bignumber")

describe("Start of tests", () => {

	let BasefeeLogicFactory;
	let BasefeeLogicContract;
	let BasefeeProxyFactory;
	let BasefeeProxyContract;

	let dore;

	let signerArray = [];

	let snapshotIdArray = [];

	let mine = async () => {
		await ethers.provider.send('evm_mine', []);
	}

	let minewait = async (time) => {
		await ethers.provider.send('evm_increaseTime', [time]);
		await ethers.provider.send('evm_mine', []);
	}

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

	let rand = (l, u) => {
		return testcases.randomNumber(testseed, l, u);
	}

	before(async () => {
		signerArray = await ethers.getSigners();
		dore = signerArray[0];

		BasefeeLogicFactory = await ethers.getContractFactory("BASEFEE_LOGIC");
		BasefeeLogicContract = await BasefeeLogicFactory.deploy();

		BasefeeProxyFactory = await ethers.getContractFactory("BASEFEE_PROXY");
		BasefeeProxyContract = await BasefeeProxyFactory.deploy(BasefeeLogicContract.address);

		snapshotIdArray[0] = await sendr("evm_snapshot", []);
	});

	describe("Test basefee contracts", () => {
		it("Both contracts should have variables set correctly", async () => {
			expect(await BasefeeProxyContract.logic()).to.equal(BasefeeLogicContract.address);
		});

		it("Logic should return the correct basefee", async () => {
			const block = await ethers.provider.getBlock();
			clog(block.baseFeePerGas);
			const basefee_Provider = block.baseFeePerGas;
			const basefee_Contract = await BasefeeLogicContract.RETURN_BASEFEE();
			clog(basefee_Contract);
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