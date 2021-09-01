const { network } = require('hardhat')
const { BigNumber } = require('@ethersproject/bignumber')

async function main() {
  const transferTopic = '0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef'
  const proposalExecutionTopic = '0x712ae1383f79ac853f8d882153778e0260ef8f03b504e2866e0593e04d2b291f'
  const GovernanceContract = '0x5efda50f22d34f262c29268506c5fa42cb56a1ce'
  const startBlock = 11480636
  const endBlock = 13124969

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

  let fullLogs = []

  for (log of logs) {
    fullLogs.push(
      (
        await network.provider.request({
          method: 'eth_getTransactionReceipt',
          params: [log.transactionHash],
        })
      ).logs,
    )
  }

  let filteredLogs = []

  for (entry of fullLogs) {
    for (log of entry) {
      for (topic of log.topics) {
        if (topic == transferTopic) {
          filteredLogs.push(log)
        }
      }
    }
  }

  let results = []
  let sum = BigNumber.from(0)

  for (log of filteredLogs) {
    console.log(log.data)
  }

  for (log of filteredLogs) {
    if ('0x' + log.topics[1].slice(26) == GovernanceContract) {
      const value = BigNumber.from(log.data)
      results.push(value.toString())
      sum = sum.add(value)
    }
  }

  console.log(results)
  console.log(sum.toString())
}
main()
