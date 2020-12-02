// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
import "./RoleAware.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

abstract contract ERC20Vestable is RoleAware, ERC20 {

    // tokens vest 10% every 10 days. `claimFunds` can be called once every 10 days
    struct VestingAllowance {
        uint256 frequency;
        uint256 allowance;
        uint256 claimAmount;
        uint256 lastClaimed;
    }

    mapping(address => VestingAllowance) public vestingAllowances;

    function _grantFunds(address beneficiary) internal {
        VestingAllowance memory allowance = vestingAllowances[beneficiary];
        require(
            allowance.allowance > 0 &&
                allowance.allowance >= allowance.claimAmount,
            "Entire allowance already claimed, or no initial aloowance"
        );
        allowance.allowance = allowance.allowance.sub(allowance.claimAmount);
        vestingAllowances[beneficiary] = allowance;
        _mint(beneficiary, allowance.claimAmount.mul(10**uint256(decimals())));
    }

    // internal function only ever called from constructor
    function _addBeneficiary(
        address beneficiary,
        uint256 amount,
        uint256 claimFrequency
    ) internal onlyBeforeUniswap {
        vestingAllowances[beneficiary] = VestingAllowance(
            claimFrequency,
            amount,
            amount.div(10),
            now
        );
        // beneficiary gets 10% of funds immediately
        _grantFunds(beneficiary);
    }

    function claimFunds() public {
        VestingAllowance memory allowance = vestingAllowances[msg.sender];
        require(
            allowance.lastClaimed != 0 &&
                now >= allowance.lastClaimed.add(allowance.frequency),
            "Allowance cannot be claimed more than once every 10 days"
        );
        allowance.lastClaimed = now;
        vestingAllowances[msg.sender] = allowance;
        _grantFunds(msg.sender);
    }

    function addV1Beneficiary(address[] memory addresses, uint256[] memory amounts)
        public
        onlyDeveloper
        onlyBeforeUniswap
    {
        for (uint256 index = 0; index < addresses.length; index++) {
            _addBeneficiary(addresses[index], amounts[index], 4 days);
        }
    }
}
