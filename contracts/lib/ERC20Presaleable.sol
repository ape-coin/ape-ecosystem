// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
import "./RoleAware.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

abstract contract ERC20Presaleable is RoleAware, ReentrancyGuard, ERC20 {
    bool internal _presale = true;

    uint256 public _presaleApePerEther = 200;
    uint256 public _presaleApePerEtherAfterThreshhold = 180;
    uint256 public _uniswapApePerEth = 160;
    uint256 internal _minTokenPurchaseAmount = .1 ether;
    uint256 internal _maxTokenPurchaseAmount = 1.5 ether;
    uint256 internal _maxPresaleEtherValue = 99 ether;
    uint256 internal _presaleEtherThreshhold = 69 ether;
    uint256 internal _presaleEtherReceived = 0 ether;

    mapping(address => uint256) public _presaleContributions;

    modifier onlyDuringPresale() {
        require(_presale == true, "The presale is not active");
        _;
    }

    function stopPresale() public onlyDeveloper onlyDuringPresale {
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
                _maxTokenPurchaseAmount.mul(_presaleApePerEther),
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

        _developer.transfer(msg.value.mul(2).div(10));
    }

    function _getPresaleEntitlement() internal returns (uint256) {
        require(
            _presaleContributions[msg.sender] >= 0,
            "No presale contribution or already redeemed"
        );
        uint256 value = _presaleContributions[msg.sender];
        _presaleContributions[msg.sender] = 0;
        return value;
    }

    // presale funds only claimable after uniswap pair created to prevent malicious 3rd-party listing
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
}
