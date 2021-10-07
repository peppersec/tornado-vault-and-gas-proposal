# Scripts and Dune Analytics queries to determine locked torn

I looked at the difference between locked and unlocked tokens for the governance vault upgrade:

After calculations with the **find_torn_distributed.js** script, which gives the same results as [this dune query](https://dune.xyz/queries/133422) (sum the hex values at [this link](https://onlinehextools.com/add-hex-numbers)) I arrive at three governance TORN outflows:

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

I arrived at a number of:

13893131191552333230524 **(AT THE TIME OF WRITING)**

For our locked balances.

I tested this result once again with the **find_torn_locked.js**:

And receive the same number, this is for the reader to try.

**Please note the block numbers, when running with network mainnet hardhat did not include latest block, manually subtract or add values based on txs post max block**

### Accidental transfer

One accidental transfer was found:

https://dune.xyz/queries/133579

Equating to **27 TORN**.

## Results

I would advise using the following input values at **lines 53 - 61** of **VaultAndGasProposal.sol**, for brevity:

```
uint256 totalOutflowsOfProposalExecutions = 120000000000000000000000 + 22916666666666666666666 + 54999999999999969408000 - 27e18;

require(
  tornToken.transfer(
    address(newGovernance.userVault()),
    (tornToken.balanceOf(address(this))).sub(GovernanceVesting.released().sub(totalOutflowsOfProposalExecutions))
  ),
  "TORN: transfer failed"
);
```

For the reason that the [accidental transfer account](https://etherscan.io/address/0xea04a9f67060271fd7473231a9aa59cedca5a5a3) has not been active for more than 195 days.
