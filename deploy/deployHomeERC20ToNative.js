const env = require('./src/loadEnv')

const {
  deployContract,
  privateKeyToAddress,
  sendRawTxHome,
  upgradeProxy,
  initializeValidators,
  transferProxyOwnership,
  assertStateWithRetry
} = require('./src/deploymentUtils')
const { web3Home, deploymentPrivateKey, HOME_RPC_URL, HOME_CHAIN_ID } = require('./src/web3')
const {
  homeContracts: {
    EternalStorageProxy,
    BridgeValidators,
    RewardableValidators,
    FeeManagerErcToNative,
    HomeBridgeErcToNative: HomeBridge,
    FeeManagerErcToNativePOSDAO
  }
} = require('./src/loadContracts')

const {
  BLOCK_REWARD_ADDRESS,
  DEPLOYMENT_ACCOUNT_PRIVATE_KEY,
  REQUIRED_NUMBER_OF_VALIDATORS,
  HOME_GAS_PRICE,
  HOME_BRIDGE_OWNER,
  HOME_VALIDATORS_OWNER,
  HOME_UPGRADEABLE_ADMIN,
  HOME_DAILY_LIMIT,
  HOME_MAX_AMOUNT_PER_TX,
  HOME_MIN_AMOUNT_PER_TX,
  HOME_REQUIRED_BLOCK_CONFIRMATIONS,
  FOREIGN_DAILY_LIMIT,
  FOREIGN_MAX_AMOUNT_PER_TX,
  HOME_REWARDABLE,
  HOME_TRANSACTIONS_FEE,
  FOREIGN_TRANSACTIONS_FEE,
  HOME_FEE_MANAGER_TYPE,
  FOREIGN_TO_HOME_DECIMAL_SHIFT
} = require('./src/loadEnv')

const DEPLOYMENT_ACCOUNT_ADDRESS = privateKeyToAddress(DEPLOYMENT_ACCOUNT_PRIVATE_KEY)

const foreignToHomeDecimalShift = FOREIGN_TO_HOME_DECIMAL_SHIFT || 0

const isRewardableBridge = HOME_REWARDABLE === 'BOTH_DIRECTIONS'
const isFeeManagerPOSDAO = HOME_FEE_MANAGER_TYPE === 'POSDAO_REWARD'

let VALIDATORS_REWARD_ACCOUNTS = []

if (isRewardableBridge && !isFeeManagerPOSDAO) {
  VALIDATORS_REWARD_ACCOUNTS = env.VALIDATORS_REWARD_ACCOUNTS.split(' ')
}

async function main() {
  let nonce = await web3Home.eth.getTransactionCount(DEPLOYMENT_ACCOUNT_ADDRESS)
  console.log('\ndeploying homeBridge implementation\n')
  const homeBridgeImplementation = await deployContract(HomeBridge, [], {
    from: DEPLOYMENT_ACCOUNT_ADDRESS,
    nonce
  })
  nonce++
  console.log('[Home] HomeBridge Implementation: ', homeBridgeImplementation.options.address)
}

main().catch(e => console.log('Error:', e))
