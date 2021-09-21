# Tornado Governance Changes Documentation

`LotteryAndVaultProposal.sol`, if executed, modifies the tornado.cash governance contract in multiple ways.

This serves as documentation for all functions which are being added or modified and which have relevant functionality:

## Governance (Governance.sol)

The `Governance` contract available in the `tornado-governance` repository modifies the original Governance source code to enable overriding functions via inheritance. This has been submitted via PR.

This is a non issue, as logic and memory slots are left unaffected and properly referenced to. `tornado-governance` is being imported as a package.

## Governance Vault Upgrade (GovernanceVaultUpgrade.sol)

`GovernanceVaultUpgrade` is the first major upgrade to tornado governance. This upgrade introduces new logic which is used to communicate with `TornVault` from the governance contract. The motivation behind this upgrade:

- split DAO member locked TORN from vesting locked TORN.
- block Governance from being able to interact with user TORN.

To solve point 1 of the formerly stated problems, and to reduce the logic bloat of the lock and unlock functionalities, we have opted for calculating the amount of user TORN locked in the governance contract. The calculations and explanations may be found [here](https://github.com/h-ivor/tornado-lottery-period/blob/final_with_auction/scripts/balance_estimation.md).

### Additions and changes

| Function/variable signature        | is addition or change? | describe significance                                                                                                                                                                             |
| ---------------------------------- | ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `_transferTokens(address,uint256)` | change                 | instead of transferring to the governance contract, funds are now transferred to the torn vault with a `transferFrom` call, this has an effect on both the `lock` and `lockWithApproval` function |
| `unlock(uint256)`                  | change                 | unlock now triggers `withdrawTorn(address,uint256)` within the vault which reverts on an unsuccessful transfer (safeTransfer)                                                                     |
| `version`                          | addition               | tells current version of governance contract                                                                                                                                                      |
| `address immutable userVault`      | addition               | address of the deployed vault                                                                                                                                                                     |

### Tornado Vault (TornadoVault.sol)

The compliment to the above upgrade. Stores user TORN, does not keep records of it. Serves exclusively for deposits and withdrawals. Works in effect as personal store of TORN for a user with the balance being user for voting. Locking mechanisms are still in effect.

| Function/variable signature     | describe significance                               |
| ------------------------------- | --------------------------------------------------- |
| `withdrawTorn(address,uint256)` | used for withdrawing TORN balance to users' account |

## Governance Lottery Upgrade (GovernanceLotteryUpgrade.sol)

`GovernanceLotteryUpgrade` is the second major upgrade for governance. The motivation for this upgrade:

- to incentivize users to vote on governance proposals via a pseudorandom chainlink based lottery.
- to incentivize users to vote on governance proposals via gas compensations.
- to extend the voting period on proposals.

### Additions and changes

| Function/variable signature                    | is addition or change? | access       | describe significance                                                                                                                                                                                 |
| ---------------------------------------------- | ---------------------- | ------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `address immutable lottery`                    | addition               | public       | address of the governance lottery contract                                                                                                                                                            |
| `address public multisigAddress`               | addition               | public       | address of the TORN multisig                                                                                                                                                                          |
| `setGasCompensations(uint256)`                 | addition               | onlyMultisig | transfer a certain amount of ethereum to the gas compensation helper contract                                                                                                                         |
| `withdrawFromHelper(uint256)`                  | addition               | onlyMultisig | remove a certain amount of ethereum from the gas compensation helper contract                                                                                                                         |
| `receive() payable`                            | addition               | public       | governance contract payable fallback function                                                                                                                                                         |
| `castVote(uint256,bool)`                       | change                 | public       | function now first casts the vote, then registers the user (if he has not voted already) with the governance lottery and compensates gas for the function call given the formerly mentioned condition |
| `castDelegatedVote(...)`                       | change                 | public       | function logic now made more logical by including the person being delegated to in the address array being passed in, also registers users with lottery                                               |
| `version()`                                    | change                 | public       | change version statement to include lottery                                                                                                                                                           |
| `hasAccountedVoted(uint256,address)`           | addition               | public       | if account has voted on the proposal, return true                                                                                                                                                     |
| `_registerAccountWithLottery(uint256,address)` | addition               | private      | private function which communicates with vault to register user data for a proposal he has voted on                                                                                                   |

## Tornado Lottery (TornadoLottery.sol)

`TornadoLottery` is the helper contract of `GovernanceLotteryUpgrade`, it handles the lottery logic. Some functions of the lottery are of interest to lottery participants, due to the fact that it can give them information on wether they have won the lottery or not, and which index they are in the array of voters. These important functions / variables will be listed below.

| Function/variable signature                          | access   | describe significance                                                                                                 |
| ---------------------------------------------------- | -------- | --------------------------------------------------------------------------------------------------------------------- |
| `lotteryUserData`                                    | public   | mapping which stores voter address + an interval tick for rewards calculations of a proposal                          |
| `proposalsData`                                      | public   | mapping which stores state and rewards amount of a proposal                                                           |
| `prepareProposalForPayouts(uint256,uint256,uint256)` | multisig | called by multisig to prepare proposal for payouts by assigning how much TORN should be used for the proposal rewards |
| `lotteryState`                                       | public   | enum which represents state of entire lottery                                                                         |
| `findUserIndex(uint256,address)`                     | external | find index of address in lotteryUserData for a proposal                                                               |
| `checkIfAccountHasWon(uint256,uint256,uint256)`      | public   | check if account has won lottery for a certain proposal                                                               |
