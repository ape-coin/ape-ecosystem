pragma solidity ^0.6.12;
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./UniswapAware.sol";

contract RoleAware is AccessControl {
    bytes32 public constant STAKING_POOL_ROLE = keccak256("STAKING_POOL_ROLE");
    bytes32 public constant WHITELIST_ROLE = keccak256("WHITELIST_ROLE");
    bytes32 public constant DEVELOPER_ROLE = keccak256("DEVELOPER_ROLE");
    address payable public _developer;

    constructor(address payable developer) public {
        _developer = developer;
        _setupRole(STAKING_POOL_ROLE, msg.sender);
        _setupRole(DEVELOPER_ROLE, _developer);
        _setupRole(WHITELIST_ROLE, _developer);
        _setRoleAdmin(WHITELIST_ROLE, DEVELOPER_ROLE);
        grantRole(WHITELIST_ROLE, address(this));
    }

    modifier onlyDeveloper() {
        require(hasRole(DEVELOPER_ROLE, msg.sender));
        _;
    }

    function addWhitelist(address newWhitelisted) public onlyDeveloper {}
}
