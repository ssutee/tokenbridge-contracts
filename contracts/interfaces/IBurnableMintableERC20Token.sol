pragma solidity 0.4.24;
import "../interfaces/ERC677.sol";

contract IBurnableMintableERC20Token is ERC677 {
    function mint(address _to, uint256 _amount) public;

    function burn(address from, uint256 amount) public;
}

