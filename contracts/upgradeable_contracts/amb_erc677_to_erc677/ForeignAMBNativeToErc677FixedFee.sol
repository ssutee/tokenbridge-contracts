pragma solidity 0.4.24;

import "./BasicAMBErc677ToErc677FixedFee.sol";
import "../../libraries/SafeERC20.sol";
import "../MediatorBalanceStorage.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";

/**
* @title ForeignAMBNativeToErc677FixedFee
* @dev Foreign side implementation for native-to-erc677 mediator intended to work on top of AMB bridge.
* It is designed to be used as an implementation contract of EternalStorageProxy contract.
*/
contract ForeignAMBNativeToErc677FixedFee is BasicAMBErc677ToErc677FixedFee, MediatorBalanceStorage {
    using SafeERC20 for ERC677;
    using SafeMath for uint256; 

    function() public payable {
        require(msg.data.length == 0);
    }

    function relayTokens(address, uint256) external {
        revert("disable");
    }

    function relayNativeTokens(address _receiver, uint256 _value) external payable {
        // This lock is to prevent calling passMessage twice if a ERC677 token is used.
        // When transferFrom is called, after the transfer, the ERC677 token will call onTokenTransfer from this contract
        // which will call passMessage.
        require(!lock());
        require(msg.value == _value);

        ERC677 token = erc677token();

        // address to = address(this);
        require(withinLimit(_value));
        addTotalSpentPerDay(getCurrentDay(), _value);

        setLock(true);
        address feeAddress = transferFeeAddress();
        uint256 feeAmount = transferFeeAmount();

        if (feeAddress != address(0) && feeAmount > 0) {
            feeAddress.transfer(feeAmount);
        }

        setLock(false);
        bridgeSpecificActionsOnTokenTransfer(token, msg.sender, _value.sub(feeAmount), abi.encodePacked(_receiver));
    }

    /**
     * @dev Executes action on the request to withdraw tokens relayed from the other network
     * @param _recipient address of tokens receiver
     * @param _value amount of bridged tokens
     */
    function executeActionOnBridgedTokens(address _recipient, uint256 _value) internal {
        uint256 value = _unshiftValue(_value);
        bytes32 _messageId = messageId();

        _setMediatorBalance(mediatorBalance().sub(value));

        _recipient.transfer(value);

        emit TokensBridged(_recipient, value, _messageId);
    }

    /**
     * @dev Allows to send to the other network the amount of locked tokens that can be forced into the contract
     * without the invocation of the required methods.
     * @param _receiver the address that will receive the tokens on the other network
     */
    function fixMediatorBalance(address _receiver) external onlyIfUpgradeabilityOwner validAddress(_receiver) {
        uint256 balance = _erc677token().balanceOf(address(this));
        uint256 expectedBalance = mediatorBalance();
        require(balance > expectedBalance);
        uint256 diff = balance - expectedBalance;
        uint256 available = maxAvailablePerTx();
        require(available > 0);
        if (diff > available) {
            diff = available;
        }
        addTotalSpentPerDay(getCurrentDay(), diff);
        _setMediatorBalance(expectedBalance.add(diff));
        passMessage(_receiver, _receiver, diff);
    }

    /**
     * @dev Executes action on deposit of bridged tokens
     * @param _from address of tokens sender
     * @param _value requsted amount of bridged tokens
     * @param _data alternative receiver, if specified
     */
    function bridgeSpecificActionsOnTokenTransfer(
        ERC677, /* _token */
        address _from,
        uint256 _value,
        bytes _data
    ) internal {
        if (!lock()) {
            _setMediatorBalance(mediatorBalance().add(_value));
            passMessage(_from, chooseReceiver(_from, _data), _value);
        }
    }

    /**
    * @dev Unlock back the amount of tokens that were bridged to the other network but failed.
    * @param _recipient address that will receive the tokens
    * @param _value amount of tokens to be received
    */
    function executeActionOnFixedTokens(address _recipient, uint256 _value) internal {
        _setMediatorBalance(mediatorBalance().sub(_value));
        _recipient.transfer(_value);
    }

    /**
    * @dev Allows to transfer any locked token on this contract that is not part of the bridge operations.
    * @param _token address of the token, if it is not provided, native tokens will be transferred.
    * @param _to address that will receive the locked tokens on this contract.
    */
    function claimTokens(address _token, address _to) external onlyIfUpgradeabilityOwner {
        //require(_token != address(_erc677token()));
        claimValues(_token, _to);
    }

    function withdraw(address _to, uint256 _value) external onlyIfUpgradeabilityOwner {
        _to.transfer(_value);
    }

}
