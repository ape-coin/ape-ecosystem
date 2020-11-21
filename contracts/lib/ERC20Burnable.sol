// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
import "./RoleAware.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

abstract contract ERC20Burnable is RoleAware, ERC20 {
    uint256 public _minimumSupply = 20000 * (10**18);
    uint256 public _maximumSupply = 100000 * (10**18);
    uint256 private constant roughDay = 60 * 60 * 24;
    uint256 public timeListed = 0;

    function _partialBurn(
        uint256 amount,
        address recipient,
        address sender
    ) internal returns (uint256) {
        uint256 burnAmount = calculateBurnAmount(amount, recipient, sender);

        if (burnAmount > 0) {
            _burn(msg.sender, burnAmount);
        }

        return amount.sub(burnAmount);
    }

    function calculateBurnAmount(
        uint256 amount,
        address recipient,
        address sender
    ) public view returns (uint256) {
        uint256 burnAmount = 0;
        uint256 burnPercentage =
            uint256(15).sub((now - timeListed).div(roughDay));
        if (recipient == _uniswapEthPair) {
            burnPercentage = burnPercentage.add(20);
        }
        // burn amount calculations
        if (totalSupply() > _minimumSupply) {
            burnAmount = amount.mul(burnPercentage).div(100);
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
        return
            super.transfer(
                recipient,
                _partialBurn(amount, recipient, address(0))
            );
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        return
            super.transferFrom(
                sender,
                recipient,
                _partialBurn(amount, recipient, sender)
            );
    }
}
