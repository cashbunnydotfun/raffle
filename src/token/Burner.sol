// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

error InvalidPercentage();
error NotAuthority();
error TimeNotElapsed();
error AlreadyInitialized();
error NotEnoughBalance();

contract Burner {
    address[] public owners;
    uint256 public lastBurnTime;
    uint256 public burnPercentage;
    uint256 public totalBurned;

    bool initialized;

    ERC20Burnable public token;

    uint256 MAX_UINT = 2**256 - 1;

    event Burned(uint256 amount);

    constructor() {
        initialized = false;
    }

    function initialize(
        address _tokenAddress,
        uint256 _burnPercentage,
        address[5] memory _owners
    ) external notInitialized {
        token = ERC20Burnable(_tokenAddress);
        burnPercentage = _burnPercentage;
        lastBurnTime = block.timestamp;
        for (uint256 i = 0; i < _owners.length; i++) {
            owners.push(_owners[i]);
        }

        token.approve(address(this), MAX_UINT);
        initialized = true;
    }

    function executeWeeklyBurn() external timeElapsed {
        uint256 balance = token.balanceOf(address(this));
        if  (balance > 0) {
            uint256 amount = balance * burnPercentage / 100;
            token.burnFrom(address(this), amount);
            lastBurnTime = block.timestamp;
            totalBurned += amount;
            emit Burned(amount);
        } else {
            revert NotEnoughBalance();
        }
    }

    function executeWeeklyBurnByAmt(uint256 amount) external timeElapsed isAuthority {
        uint256 balance = token.balanceOf(address(this));
        if (balance > amount) {
            token.burnFrom(address(this), amount);
            lastBurnTime = block.timestamp;
            totalBurned += amount;
            emit Burned(amount);
        } else {
            revert NotEnoughBalance();
        }
    }

    function setBurnPercentage(uint256 _burnPercentage) external isAuthority {
        if (_burnPercentage > 100 || _burnPercentage <= 0) {
            revert InvalidPercentage();
        }
        burnPercentage = _burnPercentage;
    }

    function setLastBurnTime(uint256 _lastBurnTime) external isAuthority {
        lastBurnTime = _lastBurnTime;
    }

    modifier timeElapsed() {
        if (block.timestamp - lastBurnTime < 604800) {
            revert TimeNotElapsed();
        }
        _;
    }

    modifier notInitialized() {
        if (initialized) {
            revert AlreadyInitialized();
        }
        _;
    }

    modifier isAuthority() {
        bool _isAuthority = false;
        for (uint256 i = 0; i < owners.length; i++) {
            if (msg.sender == owners[i]) {
                _isAuthority = true;
                break;
            }
        }
        if (!_isAuthority) {
            revert NotAuthority();
        }
        _;
    }
}