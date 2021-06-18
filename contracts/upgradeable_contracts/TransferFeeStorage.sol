pragma solidity 0.4.24;

import "../upgradeability/EternalStorage.sol";
import "./Ownable.sol";

contract TransferFeeStorage is EternalStorage, Ownable {
    bytes32 internal constant FEE_PERCENT = 0x30f73fcfd66a5747aead79119a5e33a9d14b0d4f98f9c6e54dc7e65fdea073fc; // keccak256(abi.encodePacked("feePercent"))
    bytes32 internal constant FEE_ACCOUNT = 0xaa89e929e903f7a0cecfde404eb83c0a9ba0da6182f5ac53dad003eb99ffcb23; // keccak256(abi.encodePacked("feeAccount"))
    uint256 internal constant FEE_PRECISION = 1000;

    function transferFeePercent() public view returns (uint256) {
        return uintStorage[FEE_PERCENT];
    }

    function setTransferFeePercent(uint256 _feePercent) external onlyOwner {
        _setTransferFeePercent(_feePercent);
    }

    function _setTransferFeePercent(uint256 _feePercent) internal {
        require(_feePercent <= FEE_PRECISION * 10);
        uintStorage[FEE_PERCENT] = _feePercent;
    }

    function transferFeeAccount() public view returns (address) {
        return addressStorage[FEE_ACCOUNT];
    }

    function setTransferFeeAccount(address _feeAccount) external onlyOwner {
        _setTransferFeeAccount(_feeAccount);
    }

    function _setTransferFeeAccount(address _feeAccount) internal {
        require(_feeAccount != address(0));
        addressStorage[FEE_ACCOUNT] = _feeAccount;
    }

}
