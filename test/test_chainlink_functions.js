const { expect } = require("chai");
const { ethers, run } = require("hardhat");
const { BigNumber } = require("@ethersproject/bignumber")

describe("Start of tests", () => {

	let LRNCTestImplementationFactory;
	let LRNCTestImplementationContract;

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

		LRNCTestImplementationFactory = await ethers.getContractFactory("LRNCTestImplementation");
		LRNCTestImplementationContract = await LRNCTestImplementationFactory.deploy();
		await LRNCTestImplementationContract.deployTransaction.wait(3);

		clog("Contract should be at address: ", LRNCTestImplementationContract.address);

		await run("verify:verify", {
			address: LRNCTestImplementationContract.address
		});
	});

	describe("Test chainlink contracts", () => {
		it("TestImplementation functions should work", async () => {
			await LRNCTestImplementationContract.setIdForLatestRandomNumber(BigNumber.from(25));
			const tx = await LRNCTestImplementationContract.callGetRandomNumber();
			await tx.wait();

			const randomNumber = await LRNCTestImplementationContract.getRandomResult(BigNumber.from(25));

			clog(randomNumber.toString());
		});
	});

});