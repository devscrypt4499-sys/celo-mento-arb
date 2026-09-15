// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "aave-v3-core/contracts/flashloan/base/FlashLoanSimpleReceiverBase.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "aave-v3-core/contracts/interfaces/IPoolAddressesProvider.sol";

interface IMentoRouter {
    function swap(
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 minToAmount
    ) external returns (uint256 toAmount);
}

contract Arbitrage is FlashLoanSimpleReceiverBase {
    address public owner;

    IMentoRouter public constant MENTO =
        IMentoRouter(0x4861840C2EfB2b98312B0aE34d86fD73E8f9B6f6);

    address public constant USDC =
        0xcebA9300f2b948710d2653dD7B07f33A8B32118C;

    address public constant USDm =
        0xdE9e4C3ce781b4bA68120d6261cbad65ce0aB00b;

    uint256 public minProfit = 4e6;

    constructor()
        FlashLoanSimpleReceiverBase(
            IPoolAddressesProvider(
                0x3E59A31363E2ad014dcbc521c4a0d5757d9f3402
            )
        )
    {
        owner = msg.sender;
    }

    function executeOperation(
        address,
        uint256 amount,
        uint256 premium,
        address,
        bytes calldata
    ) external override returns (bool) {
        require(msg.sender == address(POOL), "Invalid caller");

        uint256 amountOwed = amount + premium;

        IERC20(USDC).approve(address(MENTO), amount);
        uint256 usdmAmount = MENTO.swap(
            USDC,
            USDm,
            amount,
            0
        );

        IERC20(USDm).approve(address(MENTO), usdmAmount);
        uint256 finalUSDC = MENTO.swap(
            USDm,
            USDC,
            usdmAmount,
            0
        );

        require(
            finalUSDC >= amountOwed + minProfit,
            "Profit insufficient"
        );

        IERC20(USDC).approve(address(POOL), amountOwed);

        uint256 profit = finalUSDC - amountOwed;
        IERC20(USDC).transfer(owner, profit);

        return true;
    }

    function requestFlashLoan(uint256 amount) external onlyOwner {
        POOL.flashLoanSimple(address(this), USDC, amount, "", 0);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
}
