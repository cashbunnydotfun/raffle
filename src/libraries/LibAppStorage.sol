

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import { IUniswapV3Pool } from "@uniswap/v3-core/interfaces/IUniswapV3Pool.sol";
// import { IERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
// import { TokenInfo, LiquidityPosition, LoanPosition } from "../types/Types.sol";

/**
 * @notice Storage structure for token-related information.
 */
struct TokenStorage {
    uint256 initialized;
    uint256 totalSupply;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowances;
    mapping(address => uint256) nonces;
}

/**
 * @notice Storage structure for raffle-related information.
 */
struct RaffleStorage {
    uint256 totalTickets;
}

/**
 * @notice Library for accessing token-related storage.
 */
library LibAppStorage {
    /**
     * @notice Get the token storage.
     * @return ts The token storage.
     */
    function tokenStorage() internal pure returns (TokenStorage storage ts) {
        assembly {
            ts.slot := keccak256(add(0x20, "cashbunny.fun.tokenstorage"), 32)
        }
    }

    /**
     * @notice Get the raffle storage.
     * @return vs The raffle storage.
     */
    function raffleStorage() internal pure returns (RaffleStorage storage vs) {
        assembly {
            vs.slot := keccak256(add(0x20, "cashbunny.fun.rafflestorage"), 32)
        }
    }

}
