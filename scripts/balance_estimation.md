# Scripts and Dune Analytics queries to determine locked torn

We looked at the difference between locked and unlocked tokens for the governance vault upgrade,
due to us simplifying to not have to include migration logic which each user would have to call:

After calculations with the **find_torn_distributed.js** script, which gives the same results as [this dune query](https://dune.xyz/queries/133422) (sum the hex values at [this link](https://onlinehextools.com/add-hex-numbers)) we arrive at three governance TORN outflows:

```
outflow1 = 22916666666666666666666
outflow2 = 54999999999999969408000
outflow3 = 120000000000000000000000 (oldest)
```

Which result in a sum of:

```
proposal_execution_outflows = 197916666666666636074666
```

Now:

```
locked_balances = governance_balance - (vesting_released_to_governance - proposal_execution_outflows)
```

We arrive at a number of:

13893131191552333230524 **(AT THE TIME OF WRITING)**

For our locked balances.

We test this result once again with the **find_torn_locked.js**:

And receive the same number, this is for the reader to try.

**PLEASE NOTE THE BLOCK NUMBERS, WHEN RUNNING WITH NETWORK MAINNET HARDHAT DID NOT INCLUDE LATEST BLOCK, MANUALLY SUBTRACT OR ADD VALUES BASED ON TXS POST MAX BLOCK**

### Accidental transfer

One accidental transfer was found:

https://dune.xyz/queries/133579

Equating to **27 TORN**.

## Results

We would advise using **197889666666666636074666** (`proposal_execusion_outflows - 27e18`) as an input value at **line 41** of **LotteryAndPeriodProposal.sol**, for brevity:

```
require(
  IERC20(TornTokenAddress).transfer(
    GovernanceLotteryUpgrade(returnPayableGovernance()).userVault(),
    (IERC20(TornTokenAddress).balanceOf(address(this))).sub(
      IGovernanceVesting(GovernanceVesting).released().sub(
        120000000000000000000000 + 22916666666666666666666 + 54999999999999969408000 - 27e18 // line 41
      )
    )
  ),
  "TORN: transfer failed"
);
```

For the reason that the [accidental transfer account](https://etherscan.io/address/0xea04a9f67060271fd7473231a9aa59cedca5a5a3) has not been active for more than 195 days.