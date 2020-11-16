pragma solidity ^0.6.12;
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./UniswapAware.sol";

contract Promotable is ReentrancyGuard, UniswapAware {
    using SafeMath for uint256;

    mapping(address => uint256) public _referrers;
    mapping(string => address) public _referrerAliases;

    function claimReferralAlias(string memory referrerAlias) public {
        require(
            bytes(referrerAlias).length != 0,
            "Referrer cannot be blank string"
        );
        require(
            _referrerAliases[referrerAlias] == address(0) &&
                _referrers[msg.sender] == 0,
            "Someone else has claimed this referrer already"
        );
        _referrerAliases[referrerAlias] = msg.sender;
        _referrers[msg.sender] = 0;
    }

    function _getReferrerReward() internal returns (uint256) {
        require(_referrers[msg.sender] != 0);
        uint256 referrerBonus = _referrers[msg.sender];
        _referrers[msg.sender] = 0;
        return referrerBonus;
    }

    function _addReferrerReward(string memory referrer) internal {
        if (bytes(referrer).length != 0) {
            _referrers[_referrerAliases[referrer]] = _referrers[_referrerAliases[referrer]]
                .add(msg.value / 10);
        }
    }
}
