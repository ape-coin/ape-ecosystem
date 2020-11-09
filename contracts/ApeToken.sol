pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract ApeToken is ERC20, AccessControl, ReentrancyGuard {
    using SafeMath for uint256;

    bytes32 public constant STAKING_POOL_ROLE = keccak256("STAKING_POOL_ROLE");
    address internal _uniswapEthPair;
    address payable internal _developer;
    uint256 internal _minimumSupply = 20000 * (10**18);
    bool internal _presale = true;

    uint256 internal _presaleApePerEther = 200;
    uint256 internal _presaleApePerEtherAfterThreshhold = 180;
    uint256 internal _minTokenPurchaseAmount = .1 ether;
    uint256 internal _maxTokenPurchaseAmount = 2 ether;
    uint256 internal _maxPresaleEtherValue = 99 ether;
    uint256 internal _presaleEtherThreshhold = 69 ether;
    uint256 internal _presaleEtherReceived = 0 ether;
    mapping(address => uint256) public _presaleContributions;

    constructor() public ERC20("Ape.cash", "APE") {
        _developer = tx.origin;
        _mint(_developer, 10000 * (10**uint256(decimals())));
        _setupRole(STAKING_POOL_ROLE, msg.sender);
        _uniswapEthPair = pairFor(
            0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f,
            0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
            address(this)
        );
    }


    // allow APE staking pool to mint rewards for users
    modifier onlyStakingPool() {
        require(
            hasRole(STAKING_POOL_ROLE, msg.sender),
            "Caller is not a staking pool"
        );
        _;
    }

    modifier onlyDeveloper() {
        require(msg.sender == _developer);
        _;
    }

    modifier onlyDuringPresale() {
        require(_presale == true, "The presale is not active");
        _;
    }

    modifier onlyAfterUniswap() {
        require(
            isContract(_uniswapEthPair),
            "You can't perform this action until the Uniswap listing"
        );
        _;
    }

    modifier onlyBeforeUniswap() {
        require(
            !isContract(_uniswapEthPair),
            "You can't perform this action after the Uniswap listing"
        );
        _;
    }

    function pairFor(
        address factory,
        address tokenA,
        address tokenB
    ) internal pure returns (address pair) {
        (address token0, address token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        pair = address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex"ff",
                        factory,
                        keccak256(abi.encodePacked(token0, token1)),
                        hex"96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f" // init code hash
                    )
                )
            )
        );
    }

    function isContract(address _addr) private view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
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

    function stopPresale() public onlyDeveloper {
        _presale = false;
    }

    function startPresale() public onlyBeforeUniswap onlyDeveloper {
        _presale = true;
    }

    function presale()
        public
        payable
        onlyDuringPresale
        nonReentrant
        returns (bool)
    {
        require(
            msg.value >= _minTokenPurchaseAmount,
            "Minimum purchase amount not met"
        );
        require(
            _presaleEtherReceived.add(msg.value) <= _maxPresaleEtherValue,
            "Presale maximum already achieved"
        );
        require(
            _presaleContributions[msg.sender].add(msg.value) <=
                _maxTokenPurchaseAmount,
            "Max purchase for your account account exceeded"
        );

        _presaleContributions[msg.sender] = _presaleContributions[msg.sender]
            .add(
            msg.value.mul(
                _presaleEtherReceived > _presaleEtherThreshhold
                    ? _presaleApePerEtherAfterThreshhold
                    : _presaleApePerEther
            )
        );
        _presaleEtherReceived = _presaleEtherReceived.add(msg.value);
        _developer.transfer(msg.value);
    }

    function claimPresale()
        public
        onlyAfterUniswap
        nonReentrant
        returns (bool)
    {
        require(
            _presaleContributions[msg.sender] >= 0,
            "You didn't contribute anything to the presale or you've already redeemed"
        );
        uint256 value = _presaleContributions[msg.sender];
        _presaleContributions[msg.sender] = 0;
        _mint(msg.sender, value);
    }
}
