const { network } = require('hardhat')
const { BigNumber } = require('@ethersproject/bignumber')

async function main() {
  const transferTopic = '0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef'
  const proposalExecutionTopic = '0x712ae1383f79ac853f8d882153778e0260ef8f03b504e2866e0593e04d2b291f'
  const GovernanceContract = '5efda50f22d34f262c29268506c5fa42cb56a1ce'
  const TornToken = '0x77777feddddffc19ff86db637967013e6c6a116c'
  const startBlock = 11480636
  const endBlock = 13124969

  let logsInflows = await network.provider.request({
    method: 'eth_getLogs',
    params: [
      {
        fromBlock: '0x' + startBlock.toString(16),
        toBlock: '0x' + endBlock.toString(16),
        address: TornToken,
        topics: [transferTopic, null, '0x000000000000000000000000' + GovernanceContract],
      },
    ],
  })

  let logsOutflows = await network.provider.request({
    method: 'eth_getLogs',
    params: [
      {
        fromBlock: '0x' + startBlock.toString(16),
        toBlock: '0x' + endBlock.toString(16),
        address: TornToken,
        topics: [transferTopic, '0x000000000000000000000000' + GovernanceContract, null],
      },
    ],
  })

  let validInflowSum = BigNumber.from(0)
  let validOutflowSum = BigNumber.from(0)
  let maxBlock = 0,
    minBlock = 900000000

  for (log of logsInflows) {
    const tx = await network.provider.request({
      method: 'eth_getTransactionByHash',
      params: [log.transactionHash],
    })
    const input = tx.input.slice(0, 10)
    if (input == '0xb54426c8' || input == '0xf0b76892') {
      validInflowSum = validInflowSum.add(BigNumber.from(log.data))
      if (log.blockNumber > maxBlock) {
        maxBlock = log.blockNumber
      } else if (log.blockNumber < minBlock) {
        minBlock = log.blockNumber
      }
    }
  }

  for (log of logsOutflows) {
    const tx = await network.provider.request({
      method: 'eth_getTransactionByHash',
      params: [log.transactionHash],
    })
    const input = tx.input.slice(0, 10)
    if (input == '0x6198e339') {
      validOutflowSum = validOutflowSum.add(BigNumber.from(log.data))
      if (log.blockNumber > maxBlock) {
        maxBlock = log.blockNumber
      } else if (log.blockNumber < minBlock) {
        minBlock = log.blockNumber
      }
    }
  }

  console.log(validInflowSum.sub(validOutflowSum).toString())
  console.log(maxBlock.toString()) // NOTE THE MAX BLOCK!!!!!!
  console.log(minBlock.toString())
}
main()
