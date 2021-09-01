# Dune Analytics queries to determine locked torn

I looked at the difference between locked and unlocked tokens for the governance vault upgrade, 
due to us simplifying to not have to include migration logic which each user would have to call:

https://dune.xyz/queries/133750

And found this to be **1.356062583491274e+22**

After calculations with the __find_torn_distributed.js__ script, which gives the same results as:

https://dune.xyz/queries/133422 (sum the hex values at https://onlinehextools.com/add-hex-numbers)

(The result is received by summing the hex values and then following the formula:
```
governance_balance - (vesting_released_to_governance - proposal_execution_outflow)
```
Where the proposal outflow is received either by the script or the dune query)

Which though leads to a discrepancy in amount locked with the above calculation, leading to an number of:

__1.3920131191552333230524 × 10^22__

Which is approximately a __360 TORN__ difference.

One accidental transfer was found:

https://dune.xyz/queries/133579

Equating to __27 TORN__. Meaning there would still be __333 unexplained TORN extra__ left in the contract.

I would thus advise using __197916666666666636074666__ as an input value at line 54 of GovernanceV2.sol:

```
(torn.balanceOf(address(this))).sub(IGovernanceVesting(GovernanceVesting).released().sub(197916666666666636074666))
```

For the reason that with this amount of TORN it would be more important to ensure the safety of the funds of a user.
The extra TORN would only stay reedemable by the user.

If wanted, an approval can be added for this amount of TORN in the same function to make the funds retrievable by governance in case
the funds are found to not belong to a user. A simple transferFrom would then suffice to transfer it out to governance again.
