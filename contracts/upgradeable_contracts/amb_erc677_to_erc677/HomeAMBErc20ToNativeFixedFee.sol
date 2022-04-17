
pragma solidity 0.4.24;

import "./BasicAMBErc677ToErc677FixedFee.sol";
import "../../interfaces/IBurnableMintableERC20Token.sol";

/**
* @title HomeAMBErc20ToErc20
* @dev Home side implementation for erc20-to-erc20 mediator intended to work on top of AMB bridge.
* It is designed to be used as an implementation contract of EternalStorageProxy contract.
*/
contract HomeAMBErc20ToNativeFixedFee is BasicAMBErc677ToErc677FixedFee {

    function() public payable {
        require(msg.data.length == 0);
    }

    function relayTokens(address _receiver, uint256 _value) external payable {
        // This lock is to prevent calling passMessage twice if a ERC677 token is used.
        // When transferFrom is called, after the transfer, the ERC677 token will call onTokenTransfer from this contract
        // which will call passMessage.
        require(!lock());
        require(msg.value == _value);
        
        ERC677 token = erc677token();

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
     * @dev Executes action on the request to deposit tokens relayed from the other network
     * @param _recipient address of tokens receiver
     * @param _value amount of bridged tokens
     */
    function executeActionOnBridgedTokens(address _recipient, uint256 _value) internal {
        uint256 value = _shiftValue(_value);
        bytes32 _messageId = messageId();
        
        _recipient.transfer(value);

        emit TokensBridged(_recipient, value, _messageId);
    }

    /**
     * @dev Executes action on withdrawal of bridged tokens
     * @param _token address of token contract
     * @param _from address of tokens sender
     * @param _value requsted amount of bridged tokens
     * @param _data alternative receiver, if specified
     */
    function bridgeSpecificActionsOnTokenTransfer(ERC677 _token, address _from, uint256 _value, bytes _data) internal {
        if (!lock()) {
            passMessage(_from, chooseReceiver(_from, _data), _value);
        }
    }

    /**
     * @dev Withdraws the erc20 tokens or native coins from this contract.
     * @param _token address of the claimed token or address(0) for native coins.
     * @param _to address of the tokens/coins receiver.
     */
    function claimTokens(address _token, address _to) external onlyIfUpgradeabilityOwner {
        // For home side of the bridge, tokens are not locked at the contract, they are minted and burned instead.
        // So, its is safe to allow claiming of any tokens. Native coins are allowed as well.
        claimValues(_token, _to);
    }

    function withdraw(address _to, uint256 _value) external onlyIfUpgradeabilityOwner {
        _to.transfer(_value);
    }

    function executeActionOnFixedTokens(address _recipient, uint256 _value) internal {
        _recipient.transfer(_value);
    }
}
