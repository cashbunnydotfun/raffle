// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {OwnableUninitialized} from "../abstract/OwnableUninitialized.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

error AlreadyInitialized();
error InvalidCaller();
error InsufficientPayment();
error RaffleNotActive();
error NoParticipants();
error InvalidTicketCount();
error OnlyCoordinatorCanFulfill();
error RaffleNotDueYet();

contract BaseRaffle is OwnableUninitialized, VRFConsumerBaseV2 {
    uint256 public ticketCostBunny; // Ticket cost in $BUNNY
    address public bunnyToken; // $BUNNY token address
    bool public raffleActive;

    mapping(address => uint256) public tickets; // Tracks ticket counts for each participant
    address[] public participants; // Tracks unique participants
    address public winner;

    uint256 public lastDrawTime; // Tracks the last draw timestamp
    uint256 public constant WEEK_DURATION = 7 days; // Weekly draw interval

    // Chainlink VRF variables
    VRFCoordinatorV2Interface private immutable vrfCoordinator;
    uint64 private subscriptionId;
    bytes32 private keyHash;
    uint32 private callbackGasLimit;
    uint16 private requestConfirmations;

    uint256 public latestRequestId;

    event RaffleEntered(address indexed participant, uint256 tickets);
    event RaffleWinnerSelected(address indexed winner, uint256 prizeAmount);
    event RaffleReset();

    modifier onlyActive() {
        if (!raffleActive) revert RaffleNotActive();
        _;
    }

    modifier weeklyDrawDue() {
        if (block.timestamp < lastDrawTime + WEEK_DURATION) revert RaffleNotDueYet();
        _;
    }

    constructor(
        address _vrfCoordinator,
        uint64 _subscriptionId,
        bytes32 _keyHash,
        uint32 _callbackGasLimit,
        uint16 _requestConfirmations
    ) VRFConsumerBaseV2(_vrfCoordinator) {
        vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
        subscriptionId = _subscriptionId;
        keyHash = _keyHash;
        callbackGasLimit = _callbackGasLimit;
        requestConfirmations = _requestConfirmations;
        lastDrawTime = block.timestamp; // Initialize to the contract deployment time
    }

    function initialize(
        address _deployer,
        address _bunnyToken,
        uint256 _ticketCost
    ) external {
        if (owner() != address(0)) revert AlreadyInitialized();
        ticketCostBunny = _ticketCost;
        bunnyToken = _bunnyToken;
        raffleActive = true;
        _transferOwnership(_deployer);
    }

    function enterRaffle(uint256 ticketCount) external onlyActive {
        if (ticketCount == 0) revert InvalidTicketCount();

        uint256 totalCost = ticketCostBunny * ticketCount;
        IERC20(bunnyToken).transferFrom(msg.sender, address(this), totalCost); 
        
        // Burn the ticket value
        IERC20(bunnyToken).burnFrom(address(this), totalCost);

        if (tickets[msg.sender] == 0) {
            participants.push(msg.sender); // Add to participants only if this is their first ticket
        }

        tickets[msg.sender] += ticketCount;

        emit RaffleEntered(msg.sender, ticketCount);
    }

    function pickWinner() external onlyOwner weeklyDrawDue onlyActive {
        if (participants.length == 0) revert NoParticipants();

        latestRequestId = vrfCoordinator.requestRandomWords(
            keyHash,
            subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            1 // Requesting 1 random number
        );

        raffleActive = false; // Prevent entries until draw is finalized
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        if (requestId != latestRequestId) revert InvalidCaller();

        uint256 totalTickets = 0;
        for (uint256 i = 0; i < participants.length; i++) {
            totalTickets += tickets[participants[i]];
        }

        uint256 randomTicket = randomWords[0] % totalTickets;

        uint256 cumulativeTickets = 0;
        for (uint256 i = 0; i < participants.length; i++) {
            cumulativeTickets += tickets[participants[i]];
            if (randomTicket < cumulativeTickets) {
                winner = participants[i];
                break;
            }
        }

        uint256 prizeAmount = address(this).balance;
        (bool success, ) = winner.call{value: prizeAmount}("");
        require(success, "BNB transfer failed");

        emit RaffleWinnerSelected(winner, prizeAmount);

        _resetRaffle();
    }

    function _resetRaffle() internal {
        for (uint256 i = 0; i < participants.length; i++) {
            tickets[participants[i]] = 0;
        }
        delete participants;
        winner = address(0);
        raffleActive = true;
        lastDrawTime = block.timestamp;

        emit RaffleReset();
    }

    function withdrawBunny(address to) external onlyOwner {
        uint256 balance = IERC20(bunnyToken).balanceOf(address(this));
        IERC20(bunnyToken).transfer(to, balance);
    }

    receive() external payable {} // Allow contract to receive BNB
}
