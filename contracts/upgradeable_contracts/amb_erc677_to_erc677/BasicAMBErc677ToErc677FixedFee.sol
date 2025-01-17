pragma solidity 0.4.24;

import "../../interfaces/IAMB.sol";
import "../Ownable.sol";
import "../Initializable.sol";
import "../BaseERC677Bridge.sol";
import "../BaseOverdrawManagement.sol";
import "../ReentrancyGuard.sol";
import "../Upgradeable.sol";
import "../Claimable.sol";
import "../VersionableBridge.sol";
import "../TokenBridgeMediator.sol";
import "../TransferFixedFeeStorage.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";

/**
* @title BasicAMBErc677ToErc677
* @dev Common functionality for erc677-to-erc677 mediator intended to work on top of AMB bridge.
*/
contract BasicAMBErc677ToErc677FixedFee is
    Initializable,
    ReentrancyGuard,
    Upgradeable,
    Claimable,
    VersionableBridge,
    BaseOverdrawManagement,
    BaseERC677Bridge,
    TokenBridgeMediator,
    TransferFixedFeeStorage
{
    using SafeMath for uint256;

    function initialize(
        address _bridgeContract,
        address _mediatorContract,
        address _erc677token,
        uint256[3] _dailyLimitMaxPerTxMinPerTxArray, // [ 0 = _dailyLimit, 1 = _maxPerTx, 2 = _minPerTx ]
        uint256[2] _executionDailyLimitExecutionMaxPerTxArray, // [ 0 = _executionDailyLimit, 1 = _executionMaxPerTx ]
        uint256 _requestGasLimit,
        int256 _decimalShift,
        address _owner,
        uint256 _transferFeeAmount,
        address _transferFeeAddress,
        uint256 _giveawayGas
    ) public onlyRelevantSender returns (bool) {
        require(!isInitialized());

        _setBridgeContract(_bridgeContract);
        _setMediatorContractOnOtherSide(_mediatorContract);
        setErc677token(_erc677token);
        _setLimits(_dailyLimitMaxPerTxMinPerTxArray);
        _setExecutionLimits(_executionDailyLimitExecutionMaxPerTxArray);
        _setRequestGasLimit(_requestGasLimit);
        _setDecimalShift(_decimalShift);
        _setOwner(_owner);
        _setTransferFeeAmount(_transferFeeAmount);
        _setTransferFeeAddress(_transferFeeAddress);
        _setGiveawayGas(_giveawayGas);
        setInitialize();

        return isInitialized();
    }

    /**
    * @dev Public getter for token contract.
    * @return address of the used token contract
    */
    function erc677token() public view returns (ERC677) {
        return _erc677token();
    }

    function bridgeContractOnOtherSide() internal view returns (address) {
        return mediatorContractOnOtherSide();
    }

    /**
    * @dev Initiates the bridge operation that will lock the amount of tokens transferred and mint the tokens on
    * the other network. The user should first call Approve method of the ERC677 token.
    * @param _receiver address that will receive the minted tokens on the other network.
    * @param _value amount of tokens to be transferred to the other network.
    */
    function relayTokens(address _receiver, uint256 _value) external {
        // This lock is to prevent calling passMessage twice if a ERC677 token is used.
        // When transferFrom is called, after the transfer, the ERC677 token will call onTokenTransfer from this contract
        // which will call passMessage.
        require(!lock());
        ERC677 token = erc677token();
        address to = address(this);
        require(withinLimit(_value));
        addTotalSpentPerDay(getCurrentDay(), _value);

        setLock(true);
        address feeAddress = transferFeeAddress();
        uint256 feeAmount = transferFeeAmount();
                
        token.transferFrom(msg.sender, to, _value);
        if (feeAddress != address(0) && feeAmount > 0) {
            token.transfer(feeAddress, feeAmount);
        }

        setLock(false);
        bridgeSpecificActionsOnTokenTransfer(token, msg.sender, _value.sub(feeAmount), abi.encodePacked(_receiver));
    }

    function onTokenTransfer(address _from, uint256 _value, bytes _data) external returns (bool) {
        ERC677 token = erc677token();
        require(msg.sender == address(token));
        if (!lock()) {
            require(withinLimit(_value));
            addTotalSpentPerDay(getCurrentDay(), _value);
        }
        bridgeSpecificActionsOnTokenTransfer(token, _from, _value, _data);
        return true;
    }

    function getBridgeInterfacesVersion() external pure returns (uint64 major, uint64 minor, uint64 patch) {
        return (1, 4, 0);
    }

    function getBridgeMode() external pure returns (bytes4 _data) {
        return 0x76595b56; // bytes4(keccak256(abi.encodePacked("erc-to-erc-amb")))
    }

    /**
    * @dev Execute the action to be performed when the bridge tokens are out of execution limits.
    * @param _recipient address intended to receive the tokens
    * @param _value amount of tokens to be received
    */
    function executeActionOnBridgedTokensOutOfLimit(address _recipient, uint256 _value) internal {
        bytes32 _messageId = messageId();
        address recipient;
        uint256 value;
        (recipient, value) = txAboveLimits(_messageId);
        require(recipient == address(0) && value == 0);
        setOutOfLimitAmount(outOfLimitAmount().add(_value));
        setTxAboveLimits(_recipient, _value, _messageId);
        emit MediatorAmountLimitExceeded(_recipient, _value, _messageId);
    }

    /**
    * @dev Fixes locked tokens, that were out of execution limits during the call to handleBridgedTokens
    * @param messageId reference for bridge operation that was out of execution limits
    * @param unlockOnOtherSide true if fixed tokens should be unlocked to the other side of the bridge
    * @param valueToUnlock unlocked amount of tokens, should be less than saved txAboveLimitsValue.
    * Should be less than maxPerTx(), if tokens need to be unlocked on the other side.
    */
    function fixAssetsAboveLimits(bytes32 messageId, bool unlockOnOtherSide, uint256 valueToUnlock)
        external
        onlyIfUpgradeabilityOwner
    {
        (address recipient, uint256 value) = txAboveLimits(messageId);
        require(recipient != address(0) && value > 0 && value >= valueToUnlock);
        setOutOfLimitAmount(outOfLimitAmount().sub(valueToUnlock));
        uint256 pendingValue = value.sub(valueToUnlock);
        setTxAboveLimitsValue(pendingValue, messageId);
        emit AssetAboveLimitsFixed(messageId, valueToUnlock, pendingValue);
        if (unlockOnOtherSide) {
            require(valueToUnlock <= maxPerTx());
            passMessage(recipient, recipient, valueToUnlock);
        }
    }
}
