require('dotenv').config()
const { task } = require('hardhat/config')
const { abi, bytecode } = require('../resources/external-artifacts/EasyAuction.sol/EasyAuction.json')

task('deploy_governance', 'deploy gov')
  .setAction(async (taskArgs, hre) => {
    const signerArray = await hre.ethers.getSigners();
    const governanceFactory = await hre.ethers.getContractFactory('ModifiedGovernance')
    const governance = await governanceFactory.deploy();

    await governance.deployTransaction.wait(5)

    await hre.run('verify:verify', {
      contract: "contracts/test-dependencies/gov-modified/ModifiedGovernance.sol:ModifiedGovernance",
      address: governance.address
    })

    const tornTokenFactory = await hre.ethers.getContractFactory('ModifiedTORN')

    const torn = await tornTokenFactory.deploy(governance.address, 20, [
	[signerArray[0].address, hre.ethers.utils.parseEther("10000000")]
    ], {gasLimit: 10000000})

    await torn.deployTransaction.wait(5)

    await hre.run('verify:verify', {
      contract: "contracts/test-dependencies/torn-modified/ModifiedTORN.sol:ModifiedTORN",
      address: torn.address,
      constructorArguments: [governance.address, 20, [[signerArray[0].address, hre.ethers.utils.parseEther("100000000")]]]
    })

    console.log('Successfully deployed governance contract at: ', governance.address, " and torn at: ", torn.address)
  })