// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IChainlinkVDF {
    function generateRandomNumber() external returns (uint256);
}

contract Raffle is ReentrancyGuard, Ownable {
    IERC20 public token; // The $BUNNY token
    IChainlinkVDF public chainlinkVDF; // Chainlink VDF for randomness
    address public receivingWallet;

    uint256 public constant ENTRY_FEE = 0.1 ether; // Adjust according to token decimals
    uint256 public maxTickets = 10; // Maximum tickets per transaction
    uint256 public ticketCounter; // Total tickets sold
    mapping(address => uint256) public tickets; // Track tickets per user
    address[] public players; // List of unique players
    
    enum GiveawayState { inactive, active }
    GiveawayState public state;

    event TicketsPurchased(address indexed buyer, uint256 amount);
    event WinnerSelected(address indexed winner, uint256 winningNumber);

    modifier toBeInState(GiveawayState _state) {
        require(state == _state, "Not in the correct state");
        _;
    }

    constructor(IERC20 _token, IChainlinkVDF _chainlinkVDF, address _receivingWallet) {
        token = _token;
        chainlinkVDF = _chainlinkVDF;
        receivingWallet = _receivingWallet;
        state = GiveawayState.active; // Start active for this example
    }

    function enterRaffle(uint256 _tickets) public toBeInState(GiveawayState.active) nonReentrant {
        require(_tickets > 0 && _tickets <= maxTickets, "Invalid ticket amount");
        
        uint256 priceToPay = _tickets * ENTRY_FEE;
        require(token.balanceOf(msg.sender) >= priceToPay, "Insufficient balance");

        // Transfer tokens to receiving wallet
        token.transferFrom(msg.sender, receivingWallet, priceToPay);

        // Check if this is the user's first purchase
        uint256 previousTicketCount = tickets[msg.sender];

        // Update tickets for the user
        tickets[msg.sender] += _tickets;
        ticketCounter += _tickets;

        // Track players only if this is their first ticket purchase
        if (previousTicketCount == 0) {
            players.push(msg.sender);
        }

        emit TicketsPurchased(msg.sender, _tickets);
    }

    function selectWinner() public toBeInState(GiveawayState.active) {
        require(block.timestamp % 1 days < 12 hours, "Can only be called on Tuesday or Friday");

        // Generate a random number using Chainlink VDF
        uint256 winningNumber = chainlinkVDF.generateRandomNumber() % ticketCounter;

        // Find the winner based on the winning number
        address winner;
        uint256 cumulativeTickets = 0;

        for (uint256 i = 0; i < players.length; i++) {
            cumulativeTickets += tickets[players[i]];
            if (cumulativeTickets > winningNumber) {
                winner = players[i];
                break;
            }
        }

        // Emit winner event
        emit WinnerSelected(winner, winningNumber);

        // Reset raffle state
        resetRaffle();
    }

    function resetRaffle() internal {
        for (uint256 i = 0; i < players.length; i++) {
            tickets[players[i]] = 0; // Reset tickets for each player
        }
        ticketCounter = 0;
        delete players; // Clear the list of players
    }

    
}
