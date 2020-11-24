// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ApeToken.sol";

contract ApeStakingPool is ReentrancyGuard, Ownable {
    using SafeMath for uint256;

    uint256 private constant UINT256_MAX = ~uint256(0);
    uint256 private constant MONTH = 30 days;

    ApeToken private _apeTokenInstnace;
    address private _apeTokenAddress;

    bool private _dated;
    uint256 private _deployedAt;

    uint256 public _totalStaked;
    mapping(address => uint256) private _staked;
    mapping(address => uint256) private _lastClaim;
    address private _developerFund;

    event StakeIncreased(address indexed staker, uint256 amount);
    event StakeDecreased(address indexed staker, uint256 amount);
    event Rewards(
        address indexed staker,
        uint256 mintage,
        uint256 developerFund
    );

    constructor() public {
        _developerFund = msg.sender;
        _deployedAt = block.timestamp;
    }

    function setApeToken(address apeTokenAddress) external onlyOwner {
        require(_apeTokenAddress == address(0));
        _apeTokenAddress = apeTokenAddress;
        _apeTokenInstnace = ApeToken(apeTokenAddress);
    }

    function upgradeDevelopmentFund(address fund) external onlyOwner {
        _developerFund = fund;
    }

    function ape() external view returns (address) {
        return address(_apeTokenInstnace);
    }

    function totalStaked() external view returns (uint256) {
        return _totalStaked;
    }

    function staked(address staker) external view returns (uint256) {
        return _staked[staker];
    }

    function lastClaim(address staker) external view returns (uint256) {
        return _lastClaim[staker];
    }

    function increaseStake(uint256 amount) external {
        require(!_dated);

        require(_apeTokenInstnace.transferFrom(msg.sender, address(this), amount));
        _totalStaked = _totalStaked.add(amount);
        _lastClaim[msg.sender] = block.timestamp;
        _staked[msg.sender] = _staked[msg.sender].add(amount);
        emit StakeIncreased(msg.sender, amount);
    }

    function decreaseStake(uint256 amount) external {
        _staked[msg.sender] = _staked[msg.sender].sub(amount);
        _totalStaked = _totalStaked.sub(amount);
        require(_apeTokenInstnace.transfer(address(msg.sender), amount));
        emit StakeDecreased(msg.sender, amount);
    }

    function calculateSupplyDivisor() public view returns (uint256) {
        uint256 result =
            uint256(20).add(block.timestamp.sub(_deployedAt).div(MONTH).mul(5));

        if (result > 50) {
            result = 50;
        }
        return result;
    }

    function _calculateMintage(address staker) private view returns (uint256) {
        uint256 share =
            _apeTokenInstnace.totalSupply().div(calculateSupplyDivisor()).div(
                _totalStaked.div(_staked[staker])
            );

        uint256 timeElapsed = block.timestamp.sub(_lastClaim[staker]);
        uint256 mintage = 0;
        if (timeElapsed > MONTH) {
            mintage = share.mul(timeElapsed.div(MONTH));
            timeElapsed = timeElapsed.mod(MONTH);
        }

        if (timeElapsed != 0) {
            mintage = mintage.add(share.div(MONTH.div(timeElapsed)));
        }
        return mintage;
    }

    function calculateRewards(address staker) public view returns (uint256) {
        return _calculateMintage(staker).div(20).mul(19);
    }

    function claimRewards() external nonReentrant {
        require(!_dated);

        uint256 mintage = _calculateMintage(msg.sender);
        uint256 mintagePiece = mintage.div(20);
        require(mintagePiece > 0);

        _lastClaim[msg.sender] = block.timestamp;
        _apeTokenInstnace.mint(msg.sender, mintage.sub(mintagePiece));
        _apeTokenInstnace.mint(_developerFund, mintagePiece);

        emit Rewards(msg.sender, mintage, mintagePiece);
    }
}
