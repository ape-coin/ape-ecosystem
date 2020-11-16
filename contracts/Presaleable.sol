pragma solidity ^0.6.12;
import "./DeveloperAware.sol";
import "./Promotable.sol";

contract Presaleable is Promotable, DeveloperAware {
    bool internal _presale = true;

    uint256 internal _presaleApePerEther = 200;
    uint256 internal _presaleApePerEtherAfterThreshhold = 180;
    uint256 internal _minTokenPurchaseAmount = .1 ether;
    uint256 internal _maxTokenPurchaseAmount = 3 ether;
    uint256 internal _maxPresaleEtherValue = 199 ether;
    uint256 internal _presaleEtherThreshhold = 69 ether;
    uint256 internal _presaleEtherReceived = 0 ether;
    uint256 internal _firstTradeBlock = 0;
    mapping(address => uint256) public _presaleContributions;

    modifier onlyDuringPresale() {
        require(_presale == true, "The presale is not active");
        _;
    }

    function stopPresale() public onlyDeveloper {
        _presale = false;
        _firstTradeBlock = block.number;
    }

    function startPresale() public onlyBeforeUniswap onlyDeveloper {
        _presale = true;
    }

    function presale(string memory referrer)
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

        _addReferrerReward(referrer);

        _presaleEtherReceived = _presaleEtherReceived.add(msg.value);
        _developer.transfer(msg.value);
    }


    function _getPresaleEntitlement()
        internal
        returns (uint256)
    {
        require(
            _presaleContributions[msg.sender] >= 0,
            "You didn't contribute anything to the presale or you've already redeemed"
        );
        uint256 value = _presaleContributions[msg.sender];
        _presaleContributions[msg.sender] = 0;
        return value;
    }

}
