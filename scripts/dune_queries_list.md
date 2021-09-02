# Scripts and Dune Analytics queries to determine locked torn

We looked at the difference between locked and unlocked tokens for the governance vault upgrade,
due to us simplifying to not have to include migration logic which each user would have to call:

After calculations with the **find_torn_distributed.js** script, which gives the same results as:

https://dune.xyz/queries/133422 (sum the hex values at https://onlinehextools.com/add-hex-numbers)

(The result is received by summing the hex values and then following the formula:

```
governance_balance - (vesting_released_to_governance - proposal_execution_outflow)
```

Where the proposal outflow is where you input the dune / script results)

We arrive at a number of:

13893131191552333230524  __(AT THE TIME OF WRITING)__

For our locked balances.

We test this result once again with the __find_torn_locked.js__:

And receive the same number, this is for the reader to try.
__(PLEASE NOTE THE BLOCK NUMBERS, WHEN RUNNING WITH NETWORK MAINNET HARDHAT DID NOT INCLUDE LATEST BLOCK, MANUALLY SUBTRACT OR ADD VALUES BASED ON TXS POST MAX BLOCK)__

One accidental transfer was found:

https://dune.xyz/queries/133579

Equating to **27 TORN**.

### Results

We would advise using **197916666666666636074639** (outflow amount minus 27) as an input value at __line 39__ of __LotteryAndPeriodProposal.sol.__

```
(IERC20(TornTokenAddress).balanceOf(address(this))).sub(IGovernanceVesting(GovernanceVesting).released().sub(197916666666666636074639))
```

For the reason that the [accidental transfer account](https://etherscan.io/address/0xea04a9f67060271fd7473231a9aa59cedca5a5a3) has not been active for more than 195 days.