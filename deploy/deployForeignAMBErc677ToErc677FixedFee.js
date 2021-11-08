const { web3Foreign, FOREIGN_RPC_URL } = require('./src/web3')
const { deployContract, privateKeyToAddress, upgradeProxy } = require('./src/deploymentUtils')
const {
  foreignContracts: { EternalStorageProxy, ForeignAMBErc677ToErc677FixedFee: ForeignBridge }
} = require('./src/loadContracts')
const { DEPLOYMENT_ACCOUNT_PRIVATE_KEY } = require('./src/loadEnv')

const DEPLOYMENT_ACCOUNT_ADDRESS = privateKeyToAddress(DEPLOYMENT_ACCOUNT_PRIVATE_KEY)

async function main() {
  let nonce = await web3Foreign.eth.getTransactionCount(DEPLOYMENT_ACCOUNT_ADDRESS)
  console.log('\n[Foreign] Deploying Bridge Mediator implementation\n')
  const foreignBridgeImplementation = await deployContract(ForeignBridge, [], {
    from: DEPLOYMENT_ACCOUNT_ADDRESS,
    network: 'foreign',
    nonce
  })
  nonce++
  console.log('[Foreign] Bridge Mediator Implementation: ', foreignBridgeImplementation.options.address)
}

main().catch(e => console.log('Error:', e))
