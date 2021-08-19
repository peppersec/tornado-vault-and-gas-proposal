const { expect } = require("chai");
const { ethers } = require("hardhat");
const { BigNumber } = require("@ethersproject/bignumber")

describe("Start of tests", () => {

	let ProposalFactory;
	let ProposalContract;
	let LoopbackProxy;
	let GovernanceV1;
	let TornToken;
	let BasefeeLogicFactory;
	let BasefeeLogicContract;

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

		BasefeeLogicFactory = await ethers.getContractFactory("BASEFEE_LOGIC");
		BasefeeLogicContract = await BasefeeLogicFactory.deploy();

		ProposalFactory = await ethers.getContractFactory("LotteryAndPeriodProposal");
		ProposalContract = await ProposalFactory.deploy(260000);

		LoopbackProxy = await ethers.getContractAt("./tornado-governance/contracts/LoopbackProxy.sol:LoopbackProxy", proxy_address);
		GovernanceV1 = await ethers.getContractAt("./tornado-governance/contracts/Governance.sol:Governance", proxy_address);

		TornToken = await ethers.getContractAt("@openzeppelin/contracts/token/ERC20/IERC20.sol:IERC20", "0x77777FeDdddFfC19Ff86DB637967013e6C6A116C");

		votingDelay = await GovernanceV1.VOTING_DELAY();
		votingPeriod = await GovernanceV1.VOTING_PERIOD();

		proposalStartTime = BigNumber.from(await timestamp()).add(votingDelay);
		proposalEndTime = votingPeriod.add(proposalStartTime);

		executionExpiration = await GovernanceV1.EXECUTION_EXPIRATION();
		executionDelay = await GovernanceV1.EXECUTION_DELAY();

		extendTime = await GovernanceV1.VOTE_EXTEND_TIME();

		quorumVotes = await GovernanceV1.QUORUM_VOTES();
		proposalThreshold = await GovernanceV1.PROPOSAL_THRESHOLD();

		closingPeriod = await GovernanceV1.CLOSING_PERIOD();
		voteExtendTime = await GovernanceV1.VOTE_EXTEND_TIME();

		snapshotIdArray[0] = await sendr("evm_snapshot", []);
	});
});