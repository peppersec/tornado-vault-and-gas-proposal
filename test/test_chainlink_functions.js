const { expect } = require('chai')
const { ethers, run } = require('hardhat')
const { BigNumber } = require('@ethersproject/bignumber')

describe('Start of tests', () => {
  let LRNCTestImplementationFactory
  let LRNCTestImplementationContract
  let ChainlinkToken

  let firstWallet

  let signerArray = []

  let timestamp = async () => {
    return (await ethers.provider.getBlock('latest')).timestamp
  }

  let sendr = async (method, params) => {
    return await ethers.provider.send(method, params)
  }

  let clog = (...x) => {
    console.log(x)
  }

  let pE = (x) => {
    return ethers.utils.parseEther(`${x}`)
  }

  const delay = (ms) => new Promise((resolve) => setTimeout(resolve, ms))

  before(async () => {
    signerArray = await ethers.getSigners()
    firstWallet = signerArray[0]
    clog(firstWallet.address)

    ChainlinkToken = await ethers.getContractAt(
      '@chainlink/contracts/src/v0.6/interfaces/LinkTokenInterface.sol:LinkTokenInterface',
      '0x01BE23585060835E02B77ef475b0Cc51aA1e0709',
    )

    LRNCTestImplementationFactory = await ethers.getContractFactory('LRNCTestImplementation')
    LRNCTestImplementationContract = await LRNCTestImplementationFactory.deploy()
    //	await LRNCTestImplementationContract.deployTransaction.wait(5);
    //
    //	clog("Contract should be at address: ", LRNCTestImplementationContract.address);
    //
    //	await run("verify:verify", {
    //		address: LRNCTestImplementationContract.address
    //	});
  })

  describe('Test chainlink contracts', () => {
    it('TestImplementation functions should work', async () => {
      await expect(LRNCTestImplementationContract.setIdForLatestRandomNumber(BigNumber.from(25))).to.not.be
        .reverted
      await expect(ChainlinkToken.approve(LRNCTestImplementationContract.address, pE(1000))).to.not.be
        .reverted
    })

    it('Should transfer chainlink', async () => {
      await ChainlinkToken.transfer(LRNCTestImplementationContract.address, ethers.utils.parseEther('1'))

      await delay(120000)

      await expect(LRNCTestImplementationContract.callGetRandomNumber()).to.not.be.reverted

      await delay(180000)
      const randomResult = await LRNCTestImplementationContract.getRandomResult(BigNumber.from(25))
      clog('Random result received: ', randomResult.toString())
    })
  })
})
