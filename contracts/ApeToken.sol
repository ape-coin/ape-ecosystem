// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./lib/ERC20Presaleable.sol";
import "./lib/ERC20Vestable.sol";
import "./lib/ERC20Burnable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// APE Token (https://ape.cash)
// Presale	                    19200
// Initial Uniswap Liquidity	12800
// Marketing (vested)           5000
// Team	& development (vested)  15000
// Liquidity Mining	            48000

contract ApeToken is ERC20Burnable, ERC20Vestable, ERC20Presaleable {
    IUniswapV2Router02 private router;
    uint256 MAX_INT = uint256(-1);
    uint256 public stakingPoolDateAdd = 24 hours;
    address public stakingPoolPending;

    address
        public constant UNISWAP_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public constant RFI_ADDRESS = 0xA1AFFfE3F4D611d252010E3EAf6f4D77088b0cd7;

    event LiquidityAdded(
        uint256 amountToken,
        uint256 amountEth,
        uint256 liquidity
    );

    event DeveloperAddedPendingPool(address pendingPool);
    event DeveloperAddedPool(address pool);

    constructor(
        address payable secondDeveloper,
        address[] memory stakingPools,
        address marketing,
        uint256 presaleCap,
        address[] memory supporters,
        uint256[] memory supporterRewards
    )
        public
        ERC20("Ape.cash V2", "APEv2")
        RoleAware(msg.sender, stakingPools)
        ERC20Presaleable(presaleCap)
    {

        // number of tokens is vested over 3 months, see ERC20Vestable
        _addBeneficiary(msg.sender, 105000, 10 days);
        _addBeneficiary(secondDeveloper, 45000, 10 days);
        _addBeneficiary(marketing, 50000, 10 days);

        addWhitelist(UNISWAP_ROUTER_ADDRESS);
        router = IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS);

        _mint(address(this), 50000 ether);
        for (uint256 index = 0; index < supporters.length; index++) {
            _mint(supporters[index], supporterRewards[index]);
        }
    }

    // developer can add staking pools. as these can mint, function is timelocked for 24 hours
    function addStakingPoolConfirm() public onlyDeveloper {
        require(now >= stakingPoolDateAdd.add(24 hours));
        grantRole(STAKING_POOL_ROLE, stakingPoolPending);
        grantRole(WHITELIST_ROLE, stakingPoolPending);
        emit DeveloperAddedPool(stakingPoolPending);
    }

    function addStakingPoolInitial(address stakingPool) public onlyDeveloper {
        stakingPoolDateAdd = now;
        stakingPoolPending = stakingPool;
        emit DeveloperAddedPendingPool(stakingPool);
    }

    // allow contracts with role ape staking pool to mint rewards for users
    function mint(address to, uint256 amount)
        public
        onlyStakingPool
        nonReentrant
    {
        if (totalSupply() <= maximumSupply) {
            _mint(to, amount);
        }
    }

    function listOnUniswap() public onlyDeveloper onlyBeforeUniswap {
        // mint 1800 APE per held ETH to list on Uniswap
        timeListed = now;

        addWhitelist(uniswapEthPair);
        uint256 ethBalance = address(this).balance;
        uint256 apeBalance = ethBalance.mul(uniswapApePerEth);

        _mint(address(this), apeBalance);

        _approve(address(this), address(router), apeBalance);

        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = RFI_ADDRESS;
        
        // todo: use getamountsout to prevent being frontrun
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: ethBalance}(0, path, address(this), now + 5 minutes);

        IERC20 RFI = IERC20(RFI_ADDRESS);
        RFI.approve(UNISWAP_ROUTER_ADDRESS, MAX_INT);

        // todo: sensible values for min params
        (uint256 amountToken, uint256 amountEth, uint256 liquidity) = router
            .addLiquidity(
            address(this),
            RFI_ADDRESS,
            apeBalance,
            RFI.balanceOf(address(this)),
            0,
            0,
            address(this),
            block.timestamp + uint256(5).mul(1 minutes)
        );

        revokeRole(WHITELIST_ROLE, uniswapEthPair);
        revokeRole(WHITELIST_ROLE, UNISWAP_ROUTER_ADDRESS);

        addWhitelistFrom(uniswapEthPair);
        stopPresale();

        uniswapPairImpl = IUniswapV2Pair(uniswapEthPair);
        emit LiquidityAdded(amountToken, amountEth, liquidity);
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
