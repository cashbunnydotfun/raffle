// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {TokenStorage, RaffleStorage} from "../libraries/LibAppStorage.sol";
import {LibERC20} from "../libraries/LibERC20.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

error InsufficientAllowance();
error InsufficientBalance();

contract TokenFacet is IERC20 {
    TokenStorage s;
    RaffleStorage v;

    /// @notice returns the name of the token.
    function name() external view virtual returns (string memory) {
        return "Diamond Token";
    }

    /// @notice returns the symbol of the token.
    function symbol() external view virtual returns (string memory) {
        return "DTKN";
    }

    /// @notice returns the token decimals.
    function decimals() external pure returns (uint8) {
        return 18;
    }

    /// @notice returns the token total supply.
    function totalSupply() external view override returns (uint256) {
        return s.totalSupply;
    }

    /// @notice returns the balance of an address.
    function balanceOf(address _owner) external view virtual override returns (uint256 balance) {
        balance = s.balances[_owner];
    }

    /// @notice transfers `_value` token from `caller` to `_to`.
    function transfer(address _to, uint256 _value) external override returns (bool success) {
        LibERC20.transfer(s, msg.sender, _to, _value);
        success = true;
    }

    /// @notice transfers `_value` tokens, from `_from` to `_to`.
    /// @dev   `caller` must be initially approved.
    function transferFrom(address _from, address _to, uint256 _value) external override returns (bool success) {
        uint256 _allowance = s.allowances[_from][msg.sender];
        if (_allowance < _value) revert InsufficientAllowance();

        LibERC20.transfer(s, _from, _to, _value);
        unchecked {
            s.allowances[_from][msg.sender] -= _value;
        }
        success = true;
    }

    /// @notice approves `_spender` for `_value` tokens, owned by caller.
    function approve(address _spender, uint256 _value) external override returns (bool success) {
        LibERC20.approve(s, msg.sender, _spender, _value);
        success = true;
    }

    /// @notice gets the allowance for spender `_spender` by the owner `_owner`
    function allowance(address _owner, address _spender) external view override returns (uint256 remaining) {
        remaining = s.allowances[_owner][_spender];
    }

    /**
     * @dev Internal function that mints an amount of the token and assigns it to
     * an account. This encapsulates the modification of balances such that the
     * proper events are emitted.
     * @param account The account that will receive the created tokens.
     * @param amount The amount that will be created.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "Mint to the zero address");

        s.totalSupply += amount;
        s.balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @notice Mints `amount` tokens and assigns them to `account`,
     * increasing the total supply.
     * @dev Can add conditions or modify this function for access control
     * if necessary, e.g., allowing only a minter role to mint new tokens.
     * @param account The account to receive the tokens.
     * @param amount The amount of tokens to mint.
     */
    function mint(address account, uint256 amount) external {
        // Example: Uncomment the next line if you want to restrict this function to the contract owner only.
        // require(msg.sender == owner(), "Only owner can mint tokens");
        _mint(account, amount);
    }

    /// @notice Burns `_value` tokens from `caller`.
    /// @param _value The amount of tokens to burn.
    function burn(address _who, uint256 _value) external returns (bool success) {
        _burn(_who, _value);
        success = true;
    }

    /// @dev Internal function that burns `_value` tokens of `_from`.
    /// @param _from The address to burn tokens from.
    /// @param _value The amount of tokens to burn.
    function _burn(address _from, uint256 _value) internal {
        uint256 currentBalance = s.balances[_from];
        // if (currentBalance < _value) revert InsufficientBalance();
        require(currentBalance >= _value, "not enough balance");

        unchecked {
            s.balances[_from] -= _value;
            s.totalSupply -= _value;
        }

        // Emit an ERC20 Transfer event with the `to` address set to the zero address.
        emit Transfer(_from, address(0), _value);
    }
}
