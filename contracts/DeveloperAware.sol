pragma solidity ^0.6.12;
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./UniswapAware.sol";

contract DeveloperAware {
    address payable internal _developer;

    constructor() public {
        _developer = tx.origin;
    }

    modifier onlyDeveloper() {
        require(msg.sender == _developer);
        _;
    }
}
