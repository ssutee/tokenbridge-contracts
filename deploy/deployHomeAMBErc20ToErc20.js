const { web3Home, HOME_RPC_URL, deploymentPrivateKey } = require('./src/web3')
const {
  deployContract,
  privateKeyToAddress,
  upgradeProxy,
  setBridgeContract,
  transferOwnership,
  sendRawTxHome,
  assertStateWithRetry
} = require('./src/deploymentUtils')
const {
  BRIDGEABLE_TOKEN_NAME,
  BRIDGEABLE_TOKEN_SYMBOL,
  BRIDGEABLE_TOKEN_DECIMALS,
  ERC677_HOME_TOKEN_ADDRESS,
  DEPLOYMENT_ACCOUNT_PRIVATE_KEY,
  DEPLOY_REWARDABLE_TOKEN,
  BLOCK_REWARD_ADDRESS,
  DPOS_STAKING_ADDRESS
} = require('./src/loadEnv')

const {
  homeContracts: {
    EternalStorageProxy,
    HomeAMBErc20ToErc20: HomeBridge,
    ERC677BridgeTokenPermittable,
    ERC677BridgeTokenRewardable
  }
} = require('./src/loadContracts')

const DEPLOYMENT_ACCOUNT_ADDRESS = privateKeyToAddress(DEPLOYMENT_ACCOUNT_PRIVATE_KEY)

async function main() {
  let nonce = await web3Home.eth.getTransactionCount(DEPLOYMENT_ACCOUNT_ADDRESS)
  console.log('\n[Home] Deploying Bridge Mediator implementation\n')
  const homeBridgeImplementation = await deployContract(HomeBridge, [], {
    from: DEPLOYMENT_ACCOUNT_ADDRESS,
    nonce
  })
  nonce++
  console.log('[Home] Bridge Mediator Implementation: ', homeBridgeImplementation.options.address)
}

main().catch(e => console.log('Error:', e))
