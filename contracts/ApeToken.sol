// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./lib/ERC20Presaleable.sol";
import "./lib/ERC20Vestable.sol";
import "./lib/ERC20Burnable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

// APE Token (https://ape.cash)
// Presale	                    19200	19.20%
// Initial Uniswap Liquidity	12800	13.20%
// Marketing (vested)           5000	5.00%
// Team	& development (vested)  15000	15.00%
// Liquidity Mining	            48000	44.96%
// Total Supply	                100000	100.00%

contract ApeToken is ERC20Burnable, ERC20Vestable, ERC20Presaleable {
    IUniswapV2Router02 private router;
    address public constant UNISWAP_ROUTER_ADDRESS =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    constructor(
        address payable developer,
        address payable secondDeveloper,
        address[] memory stakingPools,
        address marketing,
        uint256 presaleCap
    ) public ERC20("Ape.cash", "APE") RoleAware(developer, stakingPools) ERC20Presaleable(presaleCap) {
        // number of tokens is vested over 3 months, see ERC20Vestable
        _addBeneficiary(developer, 10500);
        _addBeneficiary(secondDeveloper, 4500);
        _addBeneficiary(marketing, 5000);

        addWhitelist(UNISWAP_ROUTER_ADDRESS);
        router = IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS);
        _mint(address(this), 50000 ether);
    }

    // allow contracts with role ape staking pool can mint rewards for users
    function mint(address to, uint256 amount)
        public
        onlyStakingPool
        nonReentrant
    {
        if (totalSupply() <= _maximumSupply) {
            _mint(to, amount);
        }
    }

    function listOnUniswap() public onlyDeveloper onlyBeforeUniswap {
        // mint 160 APE per held ETH to list on Uniswap
        timeListed = now;
        
        addWhitelist(_uniswapEthPair);
        uint256 ethBalance = address(this).balance;
        uint256 apeBalance = ethBalance.mul(uniswapApePerEth);
        
        _mint(address(this), apeBalance);

        _approve(address(this), address(router), apeBalance); 

        router.addLiquidityETH{value: ethBalance}(
            address(this),
            apeBalance,
            apeBalance.div(100).mul(98),
            ethBalance.div(100).mul(98),
            address(0),
            block.timestamp + uint256(5).mul(1 minutes)
        );

        revokeRole(WHITELIST_ROLE, _uniswapEthPair);
        stopPresale();
    }

    function transfer(address recipient, uint256 amount)
        public
        override(ERC20Burnable, ERC20)
        returns (bool)
    {
        return ERC20Burnable.transfer(recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override(ERC20Burnable, ERC20) returns (bool) {
        return ERC20Burnable.transferFrom(sender, recipient, amount);
    }
}
