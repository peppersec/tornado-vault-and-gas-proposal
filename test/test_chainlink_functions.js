const { expect } = require("chai");
const { ethers, run } = require("hardhat");
const { BigNumber } = require("@ethersproject/bignumber")

describe("Start of tests", () => {

	let LRNCTestImplementationFactory;
	let LRNCTestImplementationContract;
	let ChainlinkToken;

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

	const delay = ms => new Promise(resolve => setTimeout(resolve, ms))

	before(async () => {
		signerArray = await ethers.getSigners();
		firstWallet = signerArray[0];

		ChainlinkToken = await ethers.getContractAt("@openzeppelin/contracts/token/ERC20/IERC20.sol:IERC20", "0x01BE23585060835E02B77ef475b0Cc51aA1e0709")

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
			let overrides = {
				gasPrice: BigNumber.from(15),
				gasLimit: BigNumber.from(300000)
			}
			await expect(LRNCTestImplementationContract.setIdForLatestRandomNumber(BigNumber.from(25), overrides)).to.not.be.reverted;

			const tTx = await ChainlinkToken.transfer(LRNCTestImplementationContract.address, pE(1));

			await LRNCTestImplementationContract.callGetRandomNumber(overrides);

			while((await LRNCTestImplementationContract.getRandomResult(BigNumber.from(25), overrides)).eq(0)) {
				delay(400);
				clog("waiting...");
			}

			const randomNumber = await LRNCTestImplementationContract.getRandomResult(BigNumber.from(25), overrides);
			clog("here");
			clog(randomNumber.toString());
		});
	});

});