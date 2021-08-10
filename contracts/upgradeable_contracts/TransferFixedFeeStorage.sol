pragma solidity 0.4.24;

import "../upgradeability/EternalStorage.sol";
import "./Ownable.sol";

contract TransferFixedFeeStorage is EternalStorage, Ownable {
    bytes32 internal constant FEE_AMOUNT = 0xb57b57c32f08d35b1d0aba8906aabd78c13ea6500a303931d95fe3b883d1266c; // keccak256(abi.encodePacked("feeAmount"))
    bytes32 internal constant FEE_ADDRESS = 0x33088bb68c831fb409e4920e632ee8cc604af2428f8685e4b78713caabeec6ef; // keccak256(abi.encodePacked("feeAddress"))

    function transferFeeAmount() public view returns (uint256) {
        return uintStorage[FEE_AMOUNT];
    }

    function setTransferFeeAmount(uint256 _feeAmount) external onlyOwner {
        _setTransferFeeAmount(_feeAmount);
    }

    function _setTransferFeeAmount(uint256 _feeAmount) internal {
        uintStorage[FEE_AMOUNT] = _feeAmount;
    }

    function transferFeeAddress() public view returns (address) {
        return addressStorage[FEE_ADDRESS];
    }

    function setTransferFeeAddress(address _feeAddress) external onlyOwner {
        _setTransferFeeAddress(_feeAddress);
    }

    function _setTransferFeeAddress(address _feeAddress) internal {
        require(_feeAddress != address(0));
        addressStorage[FEE_ADDRESS] = _feeAddress;
    }

}
