// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../libraries/BEP20.sol";
import "../interfaces/IRouter.sol";
import "../interfaces/IFactory.sol";

/**
 * @title CashBunny
 * @dev A BEP20 token with tax mechanism for fee distribution.
 */
contract CashBunny is BEP20 {

    IRouter private router;
    address private pair;
    address public distributionContract;
    address public authority;
    address public feeAuthority;
    address[] public exemptFee;
    uint8 defaultTax;
    uint8 MAX_EXEMPT_FEE; 

    event DistributionContractUpdated(address indexed newContract);
    event ExemptFeeAdded(address indexed account);

    /**
     * @dev Deploys the CashBunny token and sets up the PancakeSwap pair.
     * @param _pancakeswap_router The PancakeSwap router address.
     * @param _initialSupply The initial supply of tokens.
     * @param _authority The address with authority to manage certain contract actions.
     */
    constructor(
        address _pancakeswap_router, 
        uint256 _initialSupply,
        address _authority
    ) BEP20("CashBunny", "BUNNY") {
        _tokengeneration(_msgSender(), _initialSupply * 10**decimals());
        IRouter _router = IRouter(_pancakeswap_router);
        address _pair = IFactory(_router.factory()).createPair(address(this), _router.WETH());
        router = _router;
        pair = _pair;
        authority = _authority;
        feeAuthority = _msgSender();
        defaultTax = 1;
        MAX_EXEMPT_FEE = 5;
    }

    /**
     * @dev Approves `spender` to transfer up to `amount` tokens from the caller's account.
     * @param spender The address which will transfer the tokens.
     * @param amount The amount of tokens to approve for transfer.
     * @return True if the operation was successful.
     */
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev Transfers `amount` tokens from `sender` to `recipient` using the allowance mechanism.
     * @param sender Address from which tokens are transferred.
     * @param recipient Address to which tokens are transferred.
     * @param amount The amount of tokens to transfer.
     * @return True if the operation was successful.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "BEP20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    /**
     * @dev Increases the allowance of another address to spend tokens on behalf of the caller.
     * @param spender The address which will spend the tokens.
     * @param addedValue The amount by which the allowance will be increased.
     * @return True if the operation was successful.
     */
    function increaseAllowance(address spender, uint256 addedValue) public override returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Decreases the allowance of another address to spend tokens on behalf of the caller.
     * @param spender The address which will spend the tokens.
     * @param subtractedValue The amount by which the allowance will be decreased.
     * @return True if the operation was successful.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public override returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "BEP20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    /**
     * @dev Transfers `amount` tokens from the caller to `recipient`.
     * @param recipient The address to transfer to.
     * @param amount The amount of tokens to transfer.
     * @return True if the transfer was successful.
     */
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev Internal transfer function handling token transfers with fee application.
     * @param sender The address transferring tokens.
     * @param recipient The address receiving tokens.
     * @param amount The amount of tokens to transfer.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal override {
        require(amount > 0, "Transfer amount must be greater than zero");

        uint256 fee = (amount * defaultTax) / 100; // Default fee initialization

        if (exemptFee.length > 0) { // Avoid unnecessary loop if the array is empty
            for (uint8 i = 0; i < exemptFee.length; i++) {
                // Check if sender or recipient is exempt from the fee
                if (exemptFee[i] == sender || exemptFee[i] == recipient) {
                    fee = 0; // Set fee to 0 if exempt
                    break;  // Exit the loop early
                }
            }
        }

        // Transfer the net amount to the recipient
        super._transfer(sender, recipient, amount - fee);

        // Transfer the fee to the distribution contract
        if (fee > 0 && defaultTax > 0) {
            super._transfer(sender, distributionContract, fee);
        }
    }

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }
    
    /**
     * @dev Burns a specific amount of tokens from an account, reducing the total supply.
     * @param account The account whose tokens will be burnt.
     * @param amount The amount of tokens to burn.
     * @return True if the burn was successful.
     */
    function burnFrom(address account, uint256 amount) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[account][_msgSender()];
        require(currentAllowance >= amount, "BEP20: burn amount exceeds allowance");

        // Decrease allowance and burn tokens
        _approve(account, _msgSender(), currentAllowance - amount);
        _burn(account, amount);

        return true;
    }

    /**
    * @notice Sets the fee exemption status for a specific address and renounce authority if cap is reached.
    * @dev Allows the authorized caller to mark an address as exempt or not exempt from fees.
    * @param _who The address whose fee exemption status is being modified.
    * @custom:modifier onlyFeeAuthority Can only be called by an address with the required authority.
    */
    function setExemptFeeAndDisableAtCap(address _who) external onlyFeeAuthority {
        exemptFee.push(_who);
        // Renounce fee authority if max exempt fee reached
        if (exemptFee.length == MAX_EXEMPT_FEE) {
            feeAuthority = address(0);
        }
        emit ExemptFeeAdded(_who);
    }

    /**
     * @dev Sets the distribution contract address.
     * @param _distributionContract The new distribution contract address.
     */
    function setDistributionContractAndRenounce(address _distributionContract) external onlyAuthority {
        distributionContract = _distributionContract;
        authority = address(0);
        emit DistributionContractUpdated(_distributionContract);
    }

    /**
     * @dev Modifier to restrict access to the fee authority.
     */
    modifier onlyFeeAuthority() {
        require(_msgSender() == feeAuthority, "not fee authority");
        _;
    }

    /**
     * @dev Modifier to restrict access to the authority.
     */
    modifier onlyAuthority() {
        require(_msgSender() == authority, "not authorized");
        _;
    }

    /**
     * @dev Fallback function to receive ETH.
     */
    receive() external payable {}
}
