pragma solidity 0.4.24;

import "openzeppelin-solidity/contracts/AddressUtils.sol";
import "../../../Ownable.sol";
import "./BridgeLimitsManager.sol";

contract BridgeLimitsConnector is Ownable {
    bytes32 internal constant BRIDGE_LIMITS_MANAGER_CONTRACT = 0x66a99b9aa49f51e5712ebc27864eff27005edaf6b2c9ec5cd69342f54f6c7850; // keccak256(abi.encodePacked("bridgeLimitsManagerContract"))

    /**
    * @dev Updates an address of the used bridge limits manager contract.
    * @param _manager address of bridge limits manager contract.
    */
    function setBridgeLimitsManager(address _manager) external onlyOwner {
        require(AddressUtils.isContract(_manager));
        addressStorage[BRIDGE_LIMITS_MANAGER_CONTRACT] = _manager;
    }

    /**
    * @dev Retrieves an address of the bridge limits manager contract.
    * @return address of the bridge limits manager contract.
    */
    function bridgeLimitsManager() public view returns (BridgeLimitsManager) {
        return BridgeLimitsManager(addressStorage[BRIDGE_LIMITS_MANAGER_CONTRACT]);
    }
}
