pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./Presaleable.sol";

contract ApeToken is ERC20, AccessControl, Presaleable {
    bytes32 public constant STAKING_POOL_ROLE = keccak256("STAKING_POOL_ROLE");
    uint256 internal _minimumSupply = 20000 * (10**18);

    constructor() public ERC20("Ape.cash", "APE") {
        _mint(_developer, 10000 * (10**uint256(decimals())));
        _setupRole(STAKING_POOL_ROLE, msg.sender);
    }

    // allow APE staking pool to mint rewards for users
    modifier onlyStakingPool() {
        require(
            hasRole(STAKING_POOL_ROLE, msg.sender),
            "Caller is not a staking pool"
        );
        _;
    }

    function mint(address to, uint256 amount)
        public
        onlyStakingPool
        nonReentrant
    {
        _mint(to, amount);
    }

    function _partialBurn(uint256 amount) internal returns (uint256) {
        uint256 burnAmount = _calculateBurnAmount(amount);

        if (burnAmount > 0) {
            _burn(msg.sender, burnAmount);
        }

        return amount.sub(burnAmount);
    }

    function _calculateBurnAmount(uint256 amount)
        internal
        view
        returns (uint256)
    {
        uint256 burnAmount = 0;

        // burn amount calculations
        if (totalSupply() > _minimumSupply) {
            burnAmount = amount.mul(3).div(100);
            uint256 availableBurn = totalSupply().sub(_minimumSupply);
            if (burnAmount > availableBurn) {
                burnAmount = availableBurn;
            }
        }

        return burnAmount;
    }

    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        return super.transfer(recipient, _partialBurn(amount));
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        return super.transferFrom(sender, recipient, _partialBurn(amount));
    }

    function claimPresale()
        public
        onlyAfterUniswap
        nonReentrant
        returns (bool)
    {
        uint256 result = _getPresaleEntitlement();
        if (result > 0) {
            _mint(msg.sender, result);
        }
    }

    function claimReffererReward() public nonReentrant onlyAfterUniswap {
        uint256 result = _getReferrerReward();
        if (result > 0) {
            _mint(msg.sender, result);
        }
    }
}
