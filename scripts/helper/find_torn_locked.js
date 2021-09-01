const { network } = require('hardhat')
const { BigNumber } = require('@ethersproject/bignumber')

async function main() {
  const transferTopic = '0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef'
  const GovernanceContract = '0x5efda50f22d34f262c29268506c5fa42cb56a1ce'
  const TornToken = '0x77777feddddffc19ff86db637967013e6c6a116c'
  const startBlock = 11480636
  const endBlock = 13124969

  const lockIds = ['0xb54426c8', '0xf0b76892']
  const unlockId = '0x6198e339'

  let logs = await network.provider.request({
    method: 'eth_getLogs',
    params: [
      {
        fromBlock: '0x' + startBlock.toString(16),
        toBlock: '0x' + endBlock.toString(16),
        address: GovernanceContract,
        topics: [proposalExecutionTopic],
      },
    ],
  })

  let blockHashes = []

  for (log of logs) {
    blockHashes.push(log.blockHash)
  }

  console.log(blockHashes)
  //
  // let logs = await network.provider.request({
  //   method: 'eth_getLogs',
  //   params: [
  //     {
  //       fromBlock: '0x' + startBlock.toString(16),
  //       toBlock: '0x' + endBlock.toString(16),
  //       address: TornToken,
  //       topics: [transferTopic, ['0x000000000000000000000000' + GovernanceContract.slice(2), null], [null, '0x000000000000000000000000' + GovernanceContract.slice(2)]],
  //     },
  //   ],
  // })
  //
  // let txes = []
  //
  // for (log of logs) {
  //   txes.push(
  //     await network.provider.request({
  //       method: 'eth_getTransactionByHash',
  //       params: [log.transactionHash],
  //     }),
  //   )
  // }
  //
  // console.log(txes)
  //
  // let tornLocked = BigNumber.from(0);
  //
  // console.log(txes.length)
  //
  // for(tx of txes) {
  //   console.log(tx.input.slice(0, 10))
  //   if(tx.input.slice(0, 10) == lockIds[0] || tx.input.slice(0, 10) == lockIds[1]) {
  //    console.log("HERE")
  //    tornLocked = tornLocked.add(
  //	    BigNumber.from('0x' + tx.input.slice(10))
  //    );
  //   } else if(tx.input.slice(0,10) == unlockId) {
  //    tornLocked = tornLocked.sub(
  //	    BigNumber.from('0x' + tx.input.slice(10))
  //    )
  //   }
  // }
  //
  // console.log(tornLocked.toString())
}
main()
