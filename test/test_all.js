const { expect } = require("chai");
const { ethers } = require("hardhat");
const { BigNumber } = require("@ethersproject/bignumber");
const { propose } = require("../scripts/helper/propose_proposal.js");
const testcases = require("@ethersproject/testcases");
const seedbase = require("../resources/hdnode.json");
const mockBasefeeArtifacts = require("../artifacts/contracts/testing/BASEFEE_LOGIC.sol/BASEFEE_LOGIC.json");
const mockBasefeeBytecode = mockBasefeeArtifacts.bytecode;

describe("Start of tests", () => {
	let ProposalFactory;
	let ProposalContract;
	let LoopbackProxy;
	let GovernanceContract;
	let TornToken;
	let BasefeeLogicFactory;
	let BasefeeLogicContract;

	let Uni3LibraryFactory;
	let Uni3LibraryContract;

	let vrfCoordinator;
	let basefeeLogicImp;
	let tornadoMultisig;

	let MockProposalFactory;

	let proxy_address = "0x5efda50f22d34F262c29268506C5Fa42cB56A1Ce";

	let votingDelay;
	let votingPeriod;
	let proposalStartTime;
	let proposalEndTime;
	let executionExpiration;
	let executionDelay;
	let extendTime;
	let quorumVotes;
	let proposalThreshold;
	let closingPeriod;
	let voteExtendTime;

	let dore;
	let whale;

	let signerArray = [];
	let whales = [];

	let someHex = [];

	someHex[0] = BigNumber.from("0xfe16f5da5d734ce11cbb97f30ed3e5c3caccee9abd8d8e189adefcb4f9371d23");
	someHex[1] = BigNumber.from("0x639F0F6557EB7A959E2382B9583601442514DF8A951F24CBCE889B1F73B76146");
	someHex[2] = BigNumber.from("0x6F8ECDC9A8F8A8FCCA2054FE558D82164B0C0433A7F75E22B33165D919D2C4DC");
	let randN = Math.floor(Math.random() * 1023);
	let testseed = seedbase[randN].seed;

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

	let snapshotIdArray = [];

	const delay = ms => new Promise(resolve => setTimeout(resolve, ms))

	const ProposalState = {
		Pending: 0,
		Active: 1,
		Defeated: 2,
		Timelocked: 3,
		AwaitingExecution: 4,
		Executed: 5,
		Expired: 6,
	}

	before(async () => {
		signerArray = await ethers.getSigners();
		dore = signerArray[0];

		Uni3LibraryFactory = await ethers.getContractFactory("UniswapV3TWAP");
		Uni3LibraryContract = await Uni3LibraryFactory.deploy();

		BasefeeLogicFactory = await ethers.getContractFactory("contracts/testing/BASEFEE_LOGIC.sol:BASEFEE_LOGIC");
		BasefeeLogicContract = await BasefeeLogicFactory.deploy();

		MockProposalFactory = await ethers.getContractFactory("MockProposal1");

		ProposalFactory = await ethers.getContractFactory("LotteryAndPeriodProposal", {
			libraries: {
				UniswapV3TWAP: Uni3LibraryContract.address,
			},
		});

		ProposalContract = await ProposalFactory.deploy(260000, BasefeeLogicContract.address);

		LoopbackProxy = await ethers.getContractAt("./tornado-governance/contracts/LoopbackProxy.sol:LoopbackProxy", proxy_address);
		GovernanceContract = await ethers.getContractAt("./tornado-governance/contracts/Governance.sol:Governance", proxy_address);

		TornToken = await ethers.getContractAt("@openzeppelin/contracts/token/ERC20/IERC20.sol:IERC20", "0x77777FeDdddFfC19Ff86DB637967013e6C6A116C");

		votingDelay = await GovernanceContract.VOTING_DELAY();
		votingPeriod = await GovernanceContract.VOTING_PERIOD();

		proposalStartTime = BigNumber.from(await timestamp()).add(votingDelay);
		proposalEndTime = votingPeriod.add(proposalStartTime);

		executionExpiration = await GovernanceContract.EXECUTION_EXPIRATION();
		executionDelay = await GovernanceContract.EXECUTION_DELAY();

		extendTime = await GovernanceContract.VOTE_EXTEND_TIME();

		quorumVotes = await GovernanceContract.QUORUM_VOTES();
		proposalThreshold = await GovernanceContract.PROPOSAL_THRESHOLD();

		closingPeriod = await GovernanceContract.CLOSING_PERIOD();
		voteExtendTime = await GovernanceContract.VOTE_EXTEND_TIME();
	});

	describe("Test complete functionality", () => {
		describe("Imitation block", async () => {
			it("Basefee logic should successfully return basefee", async () => {
				const latestBlock = await ethers.provider.getBlock(
					await ethers.provider.getBlockNumber()
				);

				expect(await BasefeeLogicContract.RETURN_BASEFEE()).to.equal(latestBlock.baseFeePerGas.toString());
			});

			it("Should successfully imitiate chainlink VRF coordinator on mainnet", async () => {
				await sendr("hardhat_impersonateAccount", ["0xf0d54349aDdcf704F77AE15b96510dEA15cb7952"]);
				vrfCoordinator = await ethers.getSigner("0xf0d54349aDdcf704F77AE15b96510dEA15cb7952");
			});

			it("Should successfully imitiate tornado multisig", async () => {
				await sendr("hardhat_impersonateAccount", ["0xb04E030140b30C27bcdfaafFFA98C57d80eDa7B4"]);
				tornadoMultisig = await ethers.getSigner("0xb04E030140b30C27bcdfaafFFA98C57d80eDa7B4");
			});

			it("Should successfully imitate whale", async () => {
				await sendr("hardhat_impersonateAccount", ["0xA2b2fBCaC668d86265C45f62dA80aAf3Fd1dEde3"]);
				whale = await ethers.getSigner("0xA2b2fBCaC668d86265C45f62dA80aAf3Fd1dEde3");
				GovernanceContract = await GovernanceContract.connect(whale);

				let balance = await TornToken.balanceOf(whale.address);
				TornToken = await TornToken.connect(whale);

				await TornToken.approve(GovernanceContract.address, ethers.utils.parseEther("8000000000"));
				await expect(GovernanceContract.lockWithApproval(balance)).to.not.be.reverted;

				expect((await GovernanceContract.lockedBalance(whale.address)).toString()).to.equal(balance.toString());
				snapshotIdArray[0] = await sendr("evm_snapshot", []);
			});

		});

		describe("Proposal passing block", async () => {
			it("Should successfully pass the proposal", async () => {
				let response, id, state;
				[response, id, state] = await propose([whale, ProposalContract, "Lottery Upgrade"]);

				const { events } = await response.wait();
				const args = events.find(({ event }) => event == "ProposalCreated").args
				expect(args.id).to.be.equal(id);
				expect(args.proposer).to.be.equal(whale.address);
				expect(args.target).to.be.equal(ProposalContract.address);
				expect(args.description).to.be.equal("Lottery Upgrade");
				expect(state).to.be.equal(ProposalState.Pending);

				await minewait(
					(await GovernanceContract.VOTING_DELAY())
						.add(1)
						.toNumber()
				);
				await expect(GovernanceContract.castVote(id, true)).to.not.be.reverted;
				state = await GovernanceContract.state(id);
				expect(state).to.be.equal(ProposalState.Active);
				await minewait(
					(await GovernanceContract.VOTING_PERIOD())
						.add(await GovernanceContract.EXECUTION_DELAY()).add(86400).toNumber()
				);
				await expect(GovernanceContract.execute(id)).to.not.be.reverted;
				GovernanceContract = await ethers.getContractAt("GovernanceLotteryUpgrade", GovernanceContract.address);

				clog(await GovernanceContract.version());

				snapshotIdArray[1] = await sendr("evm_snapshot", []);
			});
		});

		describe("Mock rewards + proposal distribution with multiple accounts", async () => {
			it("Should start another proposal", async () => {
				ProposalContract = await MockProposalFactory.deploy();
				let response, id, state;
				[response, id, state] = await propose([whale, ProposalContract, "mock1"]);

				const { events } = await response.wait();
				const args = events.find(({ event }) => event == "ProposalCreated").args
				expect(args.id).to.be.equal(id);
				expect(args.proposer).to.be.equal(whale.address);
				expect(args.target).to.be.equal(ProposalContract.address);
				expect(args.description).to.be.equal("mock1");
				expect(state).to.be.equal(ProposalState.Pending);

				await minewait(
					(await GovernanceContract.VOTING_DELAY())
						.add(1)
						.toNumber()
				);
				clog("Whale address: ", whale.address, " Balance locked: ", (await GovernanceContract.lockedBalance(whale.address)).toString());
				GovernanceContract = await GovernanceContract.connect(whale);
				await expect(GovernanceContract.castVote(id, true)).to.not.be.reverted;
				state = await GovernanceContract.state(id);
				expect(state).to.be.equal(ProposalState.Active);
				await minewait(
					(await GovernanceContract.VOTING_PERIOD())
						.add(await GovernanceContract.EXECUTION_DELAY()).add(86400).toNumber()
				);

				await expect(GovernanceContract.execute(id)).to.not.be.reverted;
				clog((await GovernanceContract.VOTING_PERIOD()).toString());

				await sendr("evm_revert", [snapshotIdArray[1]]);
				snapshotIdArray[1] = await sendr("evm_snapshot", []);
			});

			let addrArray = [];
			it("Should impersonate multiple accounts", async () => {
				addrArray = [
					"0x6cC5F688a315f3dC28A7781717a9A798a59fDA7b",
					"0xF977814e90dA44bFA03b6295A0616a897441aceC",
					"0xA2b2fBCaC668d86265C45f62dA80aAf3Fd1dEde3",
					"0x055AD5E56c11c0eF55818155c69ed9BA2f4b3e90",
				]

				let balanceObj = {};
				function assignBalance(bal) {
					this.balance = bal;
				}

				for (i = 0; i < 4; i++) {
					await sendr("hardhat_impersonateAccount", [addrArray[i]]);
					whales[i] = await ethers.getSigner(addrArray[i]);
					balanceObj[i] = new assignBalance((await TornToken.balanceOf(addrArray[i])).toString());
				}

				for (i = 0; i < 3; i++) {//last test really unnecessary
					let torn = await TornToken.connect(whales[i]);
					await torn.approve(addrArray[i + 1], pE(1));
					await expect(() => torn.transfer(addrArray[i + 1], pE(1))).to.changeTokenBalance(torn, whales[i + 1], pE(1));
				}

				console.table(balanceObj);

				for (i = 0; i < 4; i++) {
					let torn = await TornToken.connect(whales[i]);
					let balance = await torn.balanceOf(whales[i].address);
					await expect(torn.approve(GovernanceContract.address, pE(800000))).to.not.be.reverted;
					let gov = await GovernanceContract.connect(whales[i]);
					await expect(gov.lockWithApproval(balance)).to.not.be.reverted;
				}

				snapshotIdArray[2] = await sendr("evm_snapshot", []);
			});

			it("Test multiple accounts proposal", async () => {
				ProposalContract = await MockProposalFactory.deploy();
				clog("Balance of governance contract: ", (await TornToken.balanceOf(GovernanceContract.address)).toString());
				////////////// STANDARD PROPOSAL ARGS TEST //////////////////////
				let response, id, state;
				[response, id, state] = await propose([whales[(rand(1, 9) % 4)], ProposalContract, "mock1"]);

				const { events } = await response.wait();
				const args = events.find(({ event }) => event == "ProposalCreated").args
				expect(args.id).to.be.equal(id);
				expect(args.target).to.be.equal(ProposalContract.address);
				expect(args.description).to.be.equal("mock1");
				expect(state).to.be.equal(ProposalState.Pending);

				////////////////////////INCREMENT TO VOTING TIME////////////////////////
				await minewait(
					(await GovernanceContract.VOTING_DELAY())
						.add(1)
						.toNumber()
				);


				/////////////////// PREPARE MULTISIG AND COMPENSATIONS
				let multiGov = await GovernanceContract.connect(tornadoMultisig);
				let multiTorn = await TornToken.connect(tornadoMultisig);
				await expect(multiGov.gasCompensation(pE(500))).to.not.be.reverted;

				///////////////////////////// VOTE ////////////////////////////
				for (i = 0; i < 4; i++) {
					let gov = await GovernanceContract.connect(whales[i]);
					let randN = rand(i * 5, i * 6);
					randN = randN % 2;
					if (randN > 0) {
						await expect(gov.castVote(id, true)).to.not.be.reverted;
					} else {
						await expect(gov.castVote(id, false)).to.not.be.reverted;
					}
				}

				//////////////////////////////// GET STATE ///////////////////////////////
				state = await GovernanceContract.state(id);
				expect(state).to.be.equal(ProposalState.Active);

				///////////////////////////// WHALE INFO ///////////////////////////////////
    				for (i = 0; i < 4; i++) {
    					const userData = (await GovernanceContract.getProposalDataForAccount(id, whales[i].address, true));
    					console.log(
    						"--------------------------------------\n",
    						`Whale ${i} data:\n`,
    						"Win chance: ", userData[4].toString(), "\n",
    						"Locked torn: ", (await GovernanceContract.lockedBalance(whales[i].address)).toString(), "\n",
    						"Position: ", userData[3].toString(), "\n",
    						"--------------------------------------\n"
    					)
    				}

				/////////////////////////////// PROPOSAL STATE /////////////////////////////////
				console.log(
					"--------------------------------------\n",
					"Proposal data: \n",
					"For votes: ", ((await GovernanceContract.proposals(id))[4]).toString(), "\n",
					"Against votes: ", ((await GovernanceContract.proposals(id))[5]).toString(), "\n",
					"--------------------------------------\n",
				)

				/////////////////////////////// CHECKS AND PREPARE GAS TX FOR MULTISIG ///////////////////////////////
				expect((await GovernanceContract.getProposalDataForAccount(id, whales[0].address, true))[0]).to.equal(0);

				const tx1 = {
					to: tornadoMultisig.address,
					value: pE(500)
				}
				await dore.sendTransaction(tx1);

				await expect(multiTorn.approve(GovernanceContract.address, pE(1000000))).to.not.be.reverted;

				// FAIL PREPARE
				await expect(multiGov.prepareProposalForPayouts(id, ethers.utils.parseUnits("16666", "szabo"))).to.be.reverted;

				/////////////////////////////// INCREMENT AGAIN //////////////////////////////////
				await minewait(
					(await GovernanceContract.VOTING_PERIOD())
						.add(await GovernanceContract.EXECUTION_DELAY()).add(10000).toNumber()
				);

				////////////// EXECUTE
				if (
					BigNumber.from(await GovernanceContract.state(id)).eq(ProposalState.Defeated)
				) {
					await expect(GovernanceContract.execute(id)).to.be.reverted;
				} else {
					await expect(GovernanceContract.execute(id)).to.not.be.reverted;
				}

				///////////////////////////////////////// PREPARE //////////////////////////////////////////////////////
				await expect(multiGov.prepareProposalForPayouts(id, ethers.utils.parseUnits("16666", "szabo"), BigNumber.from(4))).to.not.be.reverted;


				clog("Transfer per winner: ", (await GovernanceContract.getProposalDataForAccount(id, whales[0].address, true))[2].toString());

				expect((await GovernanceContract.getProposalDataForAccount(id, whales[0].address, true))[0]).to.equal(1);

				/////////////////////////////////// PREPARE CHAINLINK ////////////////////////////////
				let vrfGov = await GovernanceContract.connect(vrfCoordinator);
				await sendr("hardhat_setBalance", [vrfCoordinator.address, "0x1B1AE4D6E2EF500000"]);

				///////////////////// FULFILL
				const rId = await GovernanceContract.lastRequestId();
				await expect(vrfGov.rawFulfillRandomness(rId, someHex[1])).to.not.be.reverted;

				expect((await GovernanceContract.getProposalDataForAccount(id, whales[0].address, true))[0]).to.equal(2);

				clog(
					`Total sqrt (chance) sum: ${(await GovernanceContract.getProposalDataForAccount(id, whales[0].address, true))[1].toString()}`
				)

				for (i = 0; i < 4; i++) {
					let gov = await GovernanceContract.connect(whales[i]);
					await expect(gov.claimRewards(id)).to.not.be.reverted;
					let whaleChance = (await GovernanceContract.getProposalDataForAccount(id,whales[i].address, true))[4];
					let winningNumbers = (await GovernanceContract.getWinningNumbersForProposal(id));
					console.log(
						"--------------------------------------\n",
						"Whale chance: ", (await GovernanceContract.getProposalDataForAccount(id,whales[i].address, true))[4].toString(), "\n",
						"Whale TORN balance: ", (await TornToken.balanceOf(whales[i].address)).toString(), "\n",
						"Possible winning numbers: \n",  winningNumbers[0].toString(), "\n", 
						winningNumbers[1].toString(), "\n", winningNumbers[2].toString(), "\n",
						winningNumbers[3].toString(), "\n",
						"Test: ", await GovernanceContract._checkIfAccountHasWon(id, whales[i].address), "\n",
						"--------------------------------------\n",
					)
				}
			});
		});
	});
});