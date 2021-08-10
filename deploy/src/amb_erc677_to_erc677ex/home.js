const assert = require('assert')
const Web3Utils = require('web3-utils')
const { web3Home, HOME_RPC_URL, deploymentPrivateKey } = require('../web3')
const {
  deployContract,
  privateKeyToAddress,
  upgradeProxy,
  setBridgeContract,
  transferOwnership,
  sendRawTxHome,
  assertStateWithRetry
} = require('../deploymentUtils')
const {
  BRIDGEABLE_TOKEN_NAME,
  BRIDGEABLE_TOKEN_SYMBOL,
  BRIDGEABLE_TOKEN_DECIMALS,
  ERC677_HOME_TOKEN_ADDRESS,
  DEPLOYMENT_ACCOUNT_PRIVATE_KEY,
  DEPLOY_REWARDABLE_TOKEN,
  BLOCK_REWARD_ADDRESS,
  DPOS_STAKING_ADDRESS
} = require('../loadEnv')

const {
  homeContracts: {
    EternalStorageProxy,
    HomeAMBErc20ToErc20FixedFee: HomeBridge,
    ERC677BridgeTokenPermittable,
    ERC677BridgeTokenRewardable
  }
} = require('../loadContracts')

const DEPLOYMENT_ACCOUNT_ADDRESS = privateKeyToAddress(DEPLOYMENT_ACCOUNT_PRIVATE_KEY)

async function deployHome() {
  let nonce = await web3Home.eth.getTransactionCount(DEPLOYMENT_ACCOUNT_ADDRESS)

  console.log('\n[Home] Deploying Bridge Mediator storage\n')
  const homeBridgeStorage = await deployContract(EternalStorageProxy, [], {
    from: DEPLOYMENT_ACCOUNT_ADDRESS,
    nonce
  })
  nonce++
  console.log('[Home] Bridge Mediator Storage: ', homeBridgeStorage.options.address)

  console.log('\n[Home] Deploying Bridge Mediator implementation\n')
  const homeBridgeImplementation = await deployContract(HomeBridge, [], {
    from: DEPLOYMENT_ACCOUNT_ADDRESS,
    nonce
  })
  nonce++
  console.log('[Home] Bridge Mediator Implementation: ', homeBridgeImplementation.options.address)

  console.log('\n[Home] Hooking up Mediator storage to Mediator implementation')
  await upgradeProxy({
    proxy: homeBridgeStorage,
    implementationAddress: homeBridgeImplementation.options.address,
    version: '1',
    nonce,
    url: HOME_RPC_URL
  })
  nonce++

  if (DEPLOY_REWARDABLE_TOKEN) {
    console.log('\n[Home] Set BlockReward contract on Bridgeable token contract')
    const setBlockRewardContractData = await erc677token.methods
      .setBlockRewardContract(BLOCK_REWARD_ADDRESS)
      .encodeABI()
    const setBlockRewardContract = await sendRawTxHome({
      data: setBlockRewardContractData,
      nonce,
      to: erc677token.options.address,
      privateKey: deploymentPrivateKey,
      url: HOME_RPC_URL
    })
    if (setBlockRewardContract.status) {
      assert.strictEqual(Web3Utils.hexToNumber(setBlockRewardContract.status), 1, 'Transaction Failed')
    } else {
      await assertStateWithRetry(erc677token.methods.blockRewardContract().call, BLOCK_REWARD_ADDRESS)
    }
    nonce++

    console.log('\n[Home] Set Staking contract on Bridgeable token contract')
    const setStakingContractData = await erc677token.methods.setStakingContract(DPOS_STAKING_ADDRESS).encodeABI()
    const setStakingContract = await sendRawTxHome({
      data: setStakingContractData,
      nonce,
      to: erc677token.options.address,
      privateKey: deploymentPrivateKey,
      url: HOME_RPC_URL
    })
    if (setStakingContract.status) {
      assert.strictEqual(Web3Utils.hexToNumber(setStakingContract.status), 1, 'Transaction Failed')
    } else {
      await assertStateWithRetry(erc677token.methods.stakingContract().call, DPOS_STAKING_ADDRESS)
    }
    nonce++
  }

  console.log('\nHome part of ERC677-to-ERC677 bridge deployed\n')
  return {
    homeBridgeMediator: { address: homeBridgeStorage.options.address },
    bridgeableErc677: { address: ERC677_HOME_TOKEN_ADDRESS }
  }
}

module.exports = deployHome
