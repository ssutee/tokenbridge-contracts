pragma solidity 0.4.24;

interface IOwnable {
    function owner() external view returns (address);
    function transferOwnership(address newOwner) external;
}
