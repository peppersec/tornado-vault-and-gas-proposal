# Auctioning some Tornado for compensations ETH

To boost voting activity, one of our ideas is to compensate gas used for voting on proposals.
Both for the castVote and castDelegatedVote functionality.

To make this as smooth as possible, we will compensate users directly in __ETH__ (non-wrapped) for voting.
The priority fee is not compensated for to make exploiting the compensations unnecessary and unprofitable.

In order to receive ETH, TORN will be auctioned off by the governance contract with the help of a auction helper 
(see contracts/auction/TornadoAuctionHandler.sol).

This contract has two functionalities:

- Initiate an auction.

- Convert all WETH it holds into ETH and send to Governance (callable by anyone).

This way, Governance does not need to handle WETH swap logic (would require extra logic) and ETH will be directly sent to the governance contract.

The initializeAuction function takes a couple of parameters:
```
function initializeAuction(
    uint256 _auctionEndDate,
    uint96 _auctionedSellAmount,
    uint96 _minBuyAmount,
    uint256 _minBidPerOrder,
    uint256 _minFundingThreshold
  ) external onlyGovernance {
```

- _auctionEndDate -> the auction end date expressed in unix format
- _auctionedSellAmount -> the amount of TORN to be sold for the auction
- _minBuyAmount -> 