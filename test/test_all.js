const { expect } = require("chai");
const { ethers } = require("hardhat");
const { BigNumber } = require("@ethersproject/bignumber");
const { propose } = require("../scripts/helper/propose_proposal.js");
const testcases = require("@ethersproject/testcases");
const seedbase = require("../resources/hdnode.json");
const accountList = require("../resources/accounts.json");
const EasyAuctionJson = require("@gnosis.pm/ido-contracts/build/artifacts/contracts/EasyAuction.sol/EasyAuction.json");

describe("Start of tests", () => {

	///// CONSTANTS
	let proxy_address = "0x5efda50f22d34F262c29268506C5Fa42cB56A1Ce";
	let someHex = [];
	someHex[0] = BigNumber.from("0xfe16f5da5d734ce11cbb97f30ed3e5c3caccee9abd8d8e189adefcb4f9371d23");
	someHex[1] = BigNumber.from("0x639F0F6557EB7A959E2382B9583601442514DF8A951F24CBCE889B1F73B76146");
	someHex[2] = BigNumber.from("0x6F8ECDC9A8F8A8FCCA2054FE558D82164B0C0433A7F75E22B33165D919D2C4DC");

	///////////////////////////// CONTRACTS
	let GovernanceContract;
	let TornToken;
	let WETH;
	let TornadoAuctionHandler;
	let GnosisEasyAuction;

	///////////////// PROPOSAL & DEPENDENCIES
	let BasefeeLogicFactory;
	let BasefeeLogicContract;
	let LPEHelperFactory;
	let LPEHelper;
	let LPUHelperFactory;
	let LPUHelper;
	let ProposalFactory;
	let ProposalContract;

	///////////////////// CHAINLINK
	let ChainlinkToken;
	let VRFRequestHelperFactory;
	let VRFRequestHelper;

	//////////////////// IMPERSONATED
	let vrfCoordinator;
	let tornadoMultisig;
	let linkMarine;

	//////////////////////////////// MOCK
	let MockProposalFactory;

	/////// GOV PARAMS
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
	const ProposalState = {
		Pending: 0,
		Active: 1,
		Defeated: 2,
		Timelocked: 3,
		AwaitingExecution: 4,
		Executed: 5,
		Expired: 6,
	}

	///// ACCOUNTS
	let dore;
	let whale;
	let signerArray = [];
	let whales = [];

	//////////////////////////////////// TESTING & UTILITY
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

	///////////////////////////////////////////////////////////////////////////7
	before(async () => {
		signerArray = await ethers.getSigners();
		dore = signerArray[0];

		BasefeeLogicFactory = await ethers.getContractFactory("contracts/testing/BASEFEE_LOGIC.sol:BASEFEE_LOGIC");
		BasefeeLogicContract = await BasefeeLogicFactory.deploy();

		LPEHelperFactory = await ethers.getContractFactory("LotteryProposalExtrasHelper");
		LPEHelper = await LPEHelperFactory.deploy(260000);

		LPUHelperFactory = await ethers.getContractFactory("LotteryProposalUpgradesHelper");
		LPUHelper = await LPUHelperFactory.deploy(BasefeeLogicContract.address);

		MockProposalFactory = await ethers.getContractFactory("MockProposal1");

		ProposalFactory = await ethers.getContractFactory("LotteryAndPeriodProposal");

		ProposalContract = await ProposalFactory.deploy(LPUHelper.address, LPEHelper.address);

		VRFRequestHelperFactory = await ethers.getContractFactory("VRFRequestHelper");
		VRFRequestHelper = await VRFRequestHelperFactory.deploy();

		GovernanceContract = await ethers.getContractAt("./contracts/virtualGovernance/Governance.sol:Governance", proxy_address);
		GnosisEasyAuction = await ethers.getContractAt(EasyAuctionJson.abi, "0x0b7fFc1f4AD541A4Ed16b40D8c37f0929158D101");

		TornToken = await ethers.getContractAt("@openzeppelin/contracts/token/ERC20/IERC20.sol:IERC20", "0x77777FeDdddFfC19Ff86DB637967013e6C6A116C");
		WETH = await ethers.getContractAt("IWETH", "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2");
		ChainlinkToken = await ethers.getContractAt("@chainlink/contracts/src/v0.6/interfaces/LinkTokenInterface.sol:LinkTokenInterface", "0x514910771AF9Ca656af840dff83E8264EcF986CA")

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

			it("Should successfully imitate chainlink VRF coordinator on mainnet", async () => {
				await sendr("hardhat_impersonateAccount", ["0xf0d54349aDdcf704F77AE15b96510dEA15cb7952"]);
				vrfCoordinator = await ethers.getSigner("0xf0d54349aDdcf704F77AE15b96510dEA15cb7952");
			});

			it("Should successfully imitate tornado multisig", async () => {
				await sendr("hardhat_impersonateAccount", ["0xb04E030140b30C27bcdfaafFFA98C57d80eDa7B4"]);
				tornadoMultisig = await ethers.getSigner("0xb04E030140b30C27bcdfaafFFA98C57d80eDa7B4");
			});

			it("Should successfully imitate a link marine", async () => {
				await sendr("hardhat_impersonateAccount", ["0x7Dff4e2AC3aafc613398cA2D42CcBCdFBC413A02"]);
				linkMarine = await ethers.getSigner("0x7Dff4e2AC3aafc613398cA2D42CcBCdFBC413A02");
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

				await dore.sendTransaction({to:whale.address, value: pE(10)})
				const executeResponse = await GovernanceContract.execute(id);
				const executeReceipt = await executeResponse.wait();

				console.log("______________________\n", "Gas used for execution: ", executeReceipt.cumulativeGasUsed.toString(), "\n-------------------------\n");
				const topic = '0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef';
				let handlerAddress;

				for(i = 0; i < executeReceipt.logs.length; i++) {
					if(executeReceipt.logs[i].topics[0] == topic) {
						handlerAddress = executeReceipt.logs[i].topics[1];
					}
				}

				TornadoAuctionHandler = await ethers.getContractAt("TornadoAuctionHandler", ("0x" + handlerAddress.slice(26)));
				GovernanceContract = await ethers.getContractAt("GovernanceLotteryUpgrade", GovernanceContract.address);

				clog(await GovernanceContract.version());
				const auctionCounter = await TornadoAuctionHandler.auctionCounter();
				const auctionData = await GnosisEasyAuction.auctionData(auctionCounter);
				expect(auctionData.auctioningToken).to.equal(TornToken.address);

				console.log("////////////////AUCTION/////////////////\n", "Started at: ", await timestamp(), ", Will end at: ", auctionData.auctionEndDate.toString(), "\n////////////////////////////////");

				snapshotIdArray[1] = await sendr("evm_snapshot", []);
			});
		});

		describe("Mock rewards + proposal distribution with multiple accounts", async () => {
			let addrArray = [];
			let signerArmy = [];

			it("Should impersonate and fund 50 accounts", async () => {
				addrArray = [
					"0x6cC5F688a315f3dC28A7781717a9A798a59fDA7b",
					"0xF977814e90dA44bFA03b6295A0616a897441aceC",
					"0xA2b2fBCaC668d86265C45f62dA80aAf3Fd1dEde3",
					"0x055AD5E56c11c0eF55818155c69ed9BA2f4b3e90",
				]

				for (i = 0; i < 4; i++) {
					await sendr("hardhat_impersonateAccount", [addrArray[i]]);
					whales[i] = await ethers.getSigner(addrArray[i]);
				}

				for (i = 1; i < 4; i++) {//last test really unnecessary
					const torn = await TornToken.connect(whales[i]);
					const whaleBalance = (await torn.balanceOf(whales[i].address));
					await torn.approve(addrArray[0], whaleBalance);
					await expect(() => torn.transfer(addrArray[0], whaleBalance)).to.changeTokenBalance(torn, whales[0], whaleBalance);
				}

				const whale0Balance = (await TornToken.balanceOf(whales[0].address));
				const toTransfer = whale0Balance.sub(pE(10000)).div(50);
				let torn0 = await TornToken.connect(whales[0]);
				let lockedSum = BigNumber.from(0);

				for (i = 0; i < 50; i++) {
					const accAddress = accountList[i+7].checksumAddress;
					await sendr("hardhat_impersonateAccount", [accAddress]);

					signerArmy[i] = await ethers.getSigner(accAddress);
					const tx = { to: signerArmy[i].address, value: pE(1)};

					await signerArray[0].sendTransaction(tx);

					await expect(() => torn0.transfer(signerArmy[i].address, toTransfer)).to.changeTokenBalance(torn0, signerArmy[i], toTransfer);
					let torn = await torn0.connect(signerArmy[i]);

					await expect(torn.approve(GovernanceContract.address, toTransfer)).to.not.be.reverted;
					const gov = await GovernanceContract.connect(signerArmy[i]);

					if(i > 20) {
						await expect(() => gov.lockWithApproval(toTransfer.div(i))).to.changeTokenBalance(torn, signerArmy[i], BigNumber.from(0).sub(toTransfer.div(i)));
						lockedSum = lockedSum.add(toTransfer.div(i));
					} else {
						await expect(() => gov.lockWithApproval(toTransfer)).to.changeTokenBalance(torn, signerArmy[i], BigNumber.from(0).sub(toTransfer));
						lockedSum = lockedSum.add(toTransfer);
					}

					const restBalance = await torn.balanceOf(signerArmy[i].address);
					await torn.transfer(whale.address, restBalance);
				}

				const TornVault = await GovernanceContract.userVault();
				expect(await TornToken.balanceOf(TornVault)).to.equal(lockedSum);

				const gov = await GovernanceContract.connect(whales[0]);
				await expect(torn0.approve(GovernanceContract.address, pE(10000))).to.not.be.reverted;
				await expect(() => gov.lockWithApproval(toTransfer)).to.changeTokenBalance(torn0, whales[0], BigNumber.from(0).sub(toTransfer));

				snapshotIdArray[2] = await sendr("evm_snapshot", []);
			});

			it("Should test if auction handler can convert ETH to gov", async () => {
				WETH = await WETH.connect(signerArray[4]);
				await WETH.deposit({value: pE(100)});
				await WETH.transfer(TornadoAuctionHandler.address, pE(100))
				await expect(() => TornadoAuctionHandler.convertAndTransferToGovernance()).to.changeEtherBalance(GovernanceContract, pE(100));
			});

			it("Should test if auction will transfer ETH with handler properly", async () => {
				const smallBidder = signerArray[1];
				const largeBidder = signerArray[2];
				const mediumBidder = signerArray[3];

				GnosisEasyAuction = await GnosisEasyAuction.connect(largeBidder);

				WETH = await WETH.connect(largeBidder);
				await expect(() => WETH.deposit({value: pE(100)})).to.changeEtherBalance(largeBidder, BigNumber.from(0).sub(pE(100)));
				await WETH.approve(GnosisEasyAuction.address, pE(1000000000));

				let torn = await TornToken.connect(whale);
				await TornToken.transfer(largeBidder.address, pE(200));
				torn = await TornToken.connect(largeBidder);
				await torn.approve(GnosisEasyAuction.address, pE(200));

//			await expect(() => GnosisEasyAuction.placeSellOrders(
//				BigNumber.from(38),
//				[
//					pE(1.1),pE(1.1) 
//				],
//				[
//					pE(40),pE(40)
//				],
//				[
//					ethers.utils.keccak256(ethers.utils.defaultAbiCoder.encode(["uint256"], [0]))
//				],
//				ethers.utils.defaultAbiCoder.encode(["uint256"], [0]),
//				{
//					gasLimit: BigNumber.from("30000000"),
//					gasPrice: BigNumber.from(6),
//				}
//			)).to.changeTokenBalance(WETH, GnosisEasyAuction, pE(80));
			});

			it("Test multiple accounts proposal", async () => {
				ProposalContract = await MockProposalFactory.deploy();
				const lotteryAddress = (await GovernanceContract.GovernanceLottery());
				const GovernanceLottery = await ethers.getContractAt("TornadoLottery", lotteryAddress);
				clog("Torn balance of governance contract: ", (await TornToken.balanceOf(GovernanceContract.address)).toString());

				////////////// STANDARD PROPOSAL ARGS TEST //////////////////////
				let response, id, state;
				[response, id, state] = await propose([whales[0], ProposalContract, "LotteryUpgrade"]);

				const { events } = await response.wait();
				const args = events.find(({ event }) => event == "ProposalCreated").args
				expect(args.id).to.be.equal(id);
				expect(args.target).to.be.equal(ProposalContract.address);
				expect(args.description).to.be.equal("LotteryUpgrade");
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
				await dore.sendTransaction({to:tornadoMultisig.address, value:pE(1)})

				await expect(multiGov.setGasCompensationsLimit(pE(500))).to.not.be.reverted;


				///////////////////////////// VOTE ////////////////////////////
				const overrides = {
					gasPrice: BigNumber.from(5)
				}

				let signerArmyBalanceInitial = [];
				let signerArmyBalanceVoted = [];
				let gasUsedArray = [];

				const gov1 = await GovernanceContract.connect(dore);
				const overrides1 = {
					value: pE(50)
				}
				await gov1.depositEthereumForGasCompensations(overrides1);

				snapshotIdArray[3] = await sendr("evm_snapshot", []);

				for (i = 0; i < 50; i++) {
					let gov = await GovernanceContract.connect(signerArmy[i]);
					let randN = rand(i * 5, i * 6);
					randN = randN % 2;
					let response;

					signerArmyBalanceInitial[i] = await signerArmy[i].getBalance();

					if (randN > 0) {
						response = await gov.castVote(id, true, overrides);
					} else {
						response = await gov.castVote(id, false, overrides);
					}

					signerArmyBalanceVoted[i] = signerArmyBalanceInitial[i].sub(await signerArmy[i].getBalance());

					const receipt = await response.wait();
					gasUsedArray[i] = receipt.cumulativeGasUsed.mul(receipt.effectiveGasPrice).toString();
				}

				//////////////////////////////// GET STATE ///////////////////////////////
				state = await GovernanceContract.state(id);
				expect(state).to.be.equal(ProposalState.Active);

				///////////////////////////// VOTER INFO ///////////////////////////////////
				// (uncomment for more data)
				/*
				for (i = 0; i < 50; i+=5) {
					const j = BigNumber.from(i);
					console.log(
						`Voter ${i} sqrt: `,
						((await GovernanceLottery.lotteryUserData(id,j))[0]).toString(),
						`Voter ${i+1} sqrt: `,
						((await GovernanceLottery.lotteryUserData(id,j.add(1)))[0]).toString(),
						`Voter ${i+2} sqrt: `,
						((await GovernanceLottery.lotteryUserData(id,j.add(2)))[0]).toString(),
						`Voter ${i+3} sqrt: `,
						((await GovernanceLottery.lotteryUserData(id,j.add(3)))[0]).toString(),
						`Voter ${i+4} sqrt: `,
						((await GovernanceLottery.lotteryUserData(id,j.add(4)))[0]).toString(),
						"\n",
					)
				}

				for (i = 0; i < 50; i+=5) {
					console.log(
						`Voter ${i} ether used: `,
						gasUsedArray[i],
						`Voter ${i+1} ether used: `,
						gasUsedArray[i+1],
						`Voter ${i+2} ether used: `,
						gasUsedArray[i+2],
						`Voter ${i+3} ether used: `,
						gasUsedArray[i+3],
						`Voter ${i+4} ether used: `,
						gasUsedArray[i+4],
						"\n",
					)
	   			}
				*/

				await sendr("evm_revert", [snapshotIdArray[3]]);

				///////////////////////////////// VOTE WITHOUT COMPENSATION //////////////////////////////////////
				let etherUsedWithoutCompensation = [];
				await multiGov.pauseOrUnpauseGasCompensations();

				for (i = 0; i < 50; i++) {
					let gov = await GovernanceContract.connect(signerArmy[i]);
					let randN = rand(i * 5, i * 6);
					randN = randN % 2;
					let response;

					if (randN > 0) {
						response = await gov.castVote(id, true, overrides);
					} else {
						response = await gov.castVote(id, false, overrides);
					}

					const receipt = await response.wait();
					etherUsedWithoutCompensation[i] = receipt.cumulativeGasUsed.mul(receipt.effectiveGasPrice).toString();
				}

				await multiGov.pauseOrUnpauseGasCompensations();

				//////////////////////////////// GET STATE ///////////////////////////////
				state = await GovernanceContract.state(id);
				expect(state).to.be.equal(ProposalState.Active);

				///////////////////////////// VOTER INFO ///////////////////////////////////
				let etherUsedNoComp = BigNumber.from(0);
				let etherUsed = BigNumber.from(0);
				let etherEndDiff = BigNumber.from(0);

				for(i = 0; i < 50; i++) {
					etherUsed = etherUsed.add(BigNumber.from(gasUsedArray[i]));
					etherUsedNoComp = etherUsedNoComp.add(BigNumber.from(etherUsedWithoutCompensation[i]));
					etherEndDiff = etherEndDiff.add(signerArmyBalanceVoted[i]);
				}

				etherUsedNoComp = etherUsedNoComp.div(50);
				etherUsed = etherUsed.div(50);
				etherEndDiff = etherEndDiff.div(50);

				console.log(
					"\n","----------------------------CAST VOTE INFO------------------------", "\n",
					"Ether use without compensation average: ", etherUsedNoComp.toString(), "\n",
					"Ether use average: ", etherUsed.toString(), "\n",
					"Ether diff average: ", etherUsed.sub(etherUsedNoComp).toString(), "\n",
					"Ether compensated in average: ", etherUsed.sub(etherEndDiff).toString(), "\n",
					"Gas use average: ", etherUsed.div(5).toString(), "\n",
					"Gas use without compensation average: ", etherUsedNoComp.div(5).toString(), "\n",
					"Gas diff average: ", etherUsed.sub(etherUsedNoComp).div(5).toString(), "\n",
					"Gas compensated in average: ", etherUsed.sub(etherEndDiff).div(5).toString(), "\n",
					"--------------------------------------------------------------------", "\n"
				)

				/////////////////////////////// CHECKS AND PREPARE GAS TX FOR MULTISIG ///////////////////////////////
				expect((await GovernanceLottery.proposalsData(id))[0]).to.equal(0);

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

				/////////////////////////// FUND WITH CHAINLINK
				await dore.sendTransaction({ to: linkMarine.address, value: pE(1) });
				ChainlinkToken = await ChainlinkToken.connect(linkMarine);

				await ChainlinkToken.transfer(GovernanceLottery.address, pE(500));
				expect(await ChainlinkToken.balanceOf(GovernanceLottery.address)).to.equal(pE(500));

				///////////////////////////////////////// PREPARE //////////////////////////////////////////////////////
				await expect(multiGov.prepareProposalForPayouts(id, ethers.utils.parseUnits("16666", "szabo"))).to.not.be.reverted;

				clog("Transfer per winner: ", ((await GovernanceLottery.proposalsData(id))[1]).toString());

				expect((await GovernanceLottery.proposalsData(id))[0]).to.equal(1);

				/////////////////////////////////// PREPARE CHAINLINK ////////////////////////////////
				let vrfGov = await GovernanceLottery.connect(vrfCoordinator);
				await sendr("hardhat_setBalance", [vrfCoordinator.address, "0x1B1AE4D6E2EF500000"]);

				///////////////////// FULFILL
				const rId = await VRFRequestHelper.makeRequestId((await GovernanceLottery.keyHash()), (await VRFRequestHelper.makeVRFInputSeed(
					await GovernanceLottery.keyHash(),
					BigNumber.from(0),
					GovernanceLottery.address,
					BigNumber.from(0))
				));

				const rfrresponse = await vrfGov.rawFulfillRandomness(rId, someHex[1]);
				const rfrreceipt = await rfrresponse.wait();

				GovernanceContract = await GovernanceContract.connect(whale);

				const whaleBalance1 = await whale.getBalance();

				const fpresponse = await GovernanceContract.finishProposalPreparation(id, overrides);
				const fpreceipt = await fpresponse.wait();

				const whaleBalance2 = await whale.getBalance();

				console.log("\n", "Finish proposal gas used: ", fpreceipt.cumulativeGasUsed.toString());
				console.log("RFR gas used: ", rfrreceipt.cumulativeGasUsed.toString());
				console.log("Whale gas used: " , whaleBalance1.sub(whaleBalance2).div(5).toString(),"\n")

				expect((await GovernanceLottery.proposalsData(id))[0]).to.equal(2);

				console.log("*----＼(^＼)(／^)／--WINNING NUMBERS--＼(^＼)(／^)／----*");
				for(let i =0; i < 10; i++) {
					console.log((await GovernanceLottery.lotteryNumbers(id,i)).toString());
				}
				console.log("--------------------------------------------------","\n");

				let claimGasSum=BigNumber.from(0);
				for (i = 0; i < 50; i++) {
					let gov = await GovernanceContract.connect(signerArmy[i]);
					const voterIndex = await GovernanceLottery.findUserIndex(id, signerArmy[i].address);
					let winIndex = -1;
					for(j = 0; j < 10; j++) {
						if(await GovernanceLottery.checkIfAccountHasWon(id, voterIndex, j)) {
							if(winIndex != -1) {
								console.log("This account won twice! (one payout)");
							}
							winIndex = j;
						}
					}
					if(winIndex >= 0) {
						const claimResponse = await gov.claimRewards(id, voterIndex, winIndex);
						claimGasSum = claimGasSum.add((await claimResponse.wait()).cumulativeGasUsed);
						console.log(`Account ${i} has won: `, (await TornToken.balanceOf(signerArmy[i].address)).toString(), " With number index: ", winIndex);
					}
				}
				claimGasSum = claimGasSum.div(50);
				console.log("\n", "Claim function gas use on average: ", claimGasSum.toString());
			});
		});
	});
});