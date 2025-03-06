// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {VRFDeployer} from "../init/VRFDeployer.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2Mock.sol";

interface IERC20Burnable is IERC20 {
    function burnFrom(address account, uint256 amount) external;
}

error AlreadyInitialized();
error InvalidParams();
error InvalidCaller();
error InsufficientPayment();
error RaffleNotActive();
error NoParticipants();
error InvalidTicketCount();
error OnlyCoordinatorCanFulfill();
error RaffleNotDueYet();

contract BaseRaffle {
    uint256 private ticketCostBunny;
    address private bunnyToken;
    bool private raffleActive;
    address private owner;

    uint256 private totalTickets;
    uint256 private totalParticipants;
    address[3] private selectedWinners;
    uint256 private lastDrawTime;
    uint256 private constant WEEK_DURATION = 7 days;
    uint256 MAX = 2**256 - 1;

    VRFDeployer private vrfContract;
    VRFCoordinatorV2Mock private vrfCoordinatorV2Mock;
    address private distributorContract;

    mapping(address => uint256) private cumulativeTicketCount; // Tracks last ticket owned by user
    mapping(uint256 => address) private ticketOwners;
    address[] private participants; // ✅ Now we store only unique participants, not each ticket.

    event RaffleEntered(address indexed participant, uint256 tickets);
    event RaffleWinnerSelected(address indexed winner, uint256 prizeAmount);
    event RaffleReset();

    Leaderboard[] public leaderboard;

    struct Leaderboard {
        address winner;
        uint256 prize;
        uint256 timestamp;
    }
    
    function initialize(
        address _vrfContract,
        address _vrfCoordinator,
        address _distributorContract,
        address _deployer,
        address _bunnyToken,
        uint256 _ticketCost
    ) public {
        if (address(vrfContract) != address(0)) revert AlreadyInitialized();
        if (_vrfContract == address(0) || _deployer == address(0) || _bunnyToken == address(0) || _ticketCost == 0)
            revert InvalidParams();
        
        vrfContract = VRFDeployer(_vrfContract);
        vrfCoordinatorV2Mock = VRFCoordinatorV2Mock(_vrfCoordinator);
        distributorContract = _distributorContract;
        lastDrawTime = block.timestamp;
        ticketCostBunny = _ticketCost;
        bunnyToken = _bunnyToken;
        raffleActive = true;
        owner = _deployer;

        IERC20(bunnyToken).approve(address(this), MAX);
    }

    function enterRaffle(uint256 ticketCount) public onlyActive {
        if (ticketCount == 0) revert InvalidTicketCount();

        uint256 totalCost = ticketCostBunny * ticketCount;
        uint256 fees = (totalCost * 1) / 100;

        uint256 balance = IERC20(bunnyToken).balanceOf(address(this));

        IERC20Burnable(bunnyToken).burnFrom(msg.sender, totalCost - fees);
        // IERC20(bunnyToken).transfer(distributorContract, fees);
        
        totalTickets += ticketCount;
        
        if (cumulativeTicketCount[msg.sender] == 0) {
            participants.push(msg.sender);
            totalParticipants++;
        }
        
        cumulativeTicketCount[msg.sender] += ticketCount;

        emit RaffleEntered(msg.sender, ticketCount);
    }

    function selectWinners() external /*weeklyDrawDue*/ {
        if (totalTickets < 3) revert NoParticipants();
        require(address(this).balance > 0, "Insufficient balance");

        address[3] memory winners;

        uint256 requestId = vrfContract.useChainlinkVRFV2();
        vrfCoordinatorV2Mock.fulfillRandomWords(requestId, address(vrfContract));

        winners = _pickThreeRandom(participants, vrfContract.getLastNumbers()[0]);

        // require(winners.length == 3, "Less than 3 winners found");

        // ✅ **Distribute Prizes**
        uint256 totalBalance = address(this).balance;
        uint256 rollover = totalBalance / 10;
        uint256 remainingPrize = totalBalance - rollover;

        uint256 firstPrize = (remainingPrize * 50) / 100;
        uint256 secondPrize = (remainingPrize * 25) / 100;
        uint256 thirdPrize = (remainingPrize * 25) / 100;

        (bool s1, ) = winners[0].call{value: firstPrize}("");
        (bool s2, ) = winners[1].call{value: secondPrize}("");
        // (bool s3, ) = winners[2].call{value: thirdPrize}("");
        // require(s1 && s2 && s3, "Prize transfer failed");

        emit RaffleWinnerSelected(winners[0], firstPrize);
        emit RaffleWinnerSelected(winners[1], secondPrize);
        // emit RaffleWinnerSelected(winners[2], thirdPrize);
        
        // TODO replace 2 below with 3
        for (uint256 i = 0; i < 2; i++) {
            Leaderboard memory newEntry = Leaderboard(
                winners[i],
                i == 0 ? firstPrize : i == 1 ? secondPrize : thirdPrize,
                block.timestamp
            );
            leaderboard.push(newEntry);
        }
        selectedWinners = winners;
        _resetRaffle();
    }

    function _pickThreeRandom(
        address[] memory participants, 
        uint256 seed
    ) internal pure returns (address[3] memory) {
        // require(participants.length >= 3, "Not enough participants");

        uint256 len = participants.length;
        address[3] memory winners;

        // Generate three unique random indices
        uint256 index1 = seed % len;
        uint256 index2 = (seed / 2) % len;
        // uint256 index3 = (seed / 3) % len;

        // Ensure uniqueness
        if (index2 == index1) {
            index2 = (index2 + 1) % len;
        }
        // if (index3 == index1 || index3 == index2) {
        //     index3 = (index3 + 2) % len;
        // }

        winners[0] = participants[index1];
        winners[1] = participants[index2];
        // winners[2] = participants[index3];

        return winners;
    }

    function _randomInRange(uint256 seed, uint256 min, uint256 max) internal pure returns (uint256) {
        require(max > min, "Invalid range");

        uint256 range = max - min + 1;
        return (uint256(keccak256(abi.encodePacked(seed))) % range) + min;
    }

    function _isAlreadyWinner(address[3] memory winners, uint256 winnersCount, address candidate) internal pure returns (bool) {
        for (uint256 i = 0; i < winnersCount; i++) {
            if (winners[i] == candidate) return true;
        }
        return false;
    }

    function _resetRaffle() internal {
        totalTickets = 0;
        raffleActive = true;
        lastDrawTime = block.timestamp;
        totalParticipants = 0;
        delete participants;

        // use assembly to free mappings
        assembly {
            sstore(cumulativeTicketCount.slot, 0)
            sstore(ticketOwners.slot, 0)
        }
        emit RaffleReset();
    }

    function withdrawBunny(address to) external onlyOwner {
        uint256 balance = IERC20(bunnyToken).balanceOf(address(this));
        IERC20(bunnyToken).transfer(to, balance);
    }

    function setTicketCost(uint256 _ticketCost) external onlyOwner {
        ticketCostBunny = _ticketCost;
    }

    function setRaffleStatus(bool _status) external onlyOwner {
        raffleActive = _status;
    }

    function getLastNumbers() external view returns (uint256[5] memory) {
        return vrfContract.getLastNumbers();
    }
    
    function getTicketCost() external view returns (uint256) {
        return ticketCostBunny;
    }

    function getTotalParticipants() external view returns (uint256) {
        return totalParticipants;
    }

    function getTotalTickets() external view returns (uint256) {
        return totalTickets;
    }

    function getWinners() external view returns (address[3] memory) {
        return selectedWinners;
    }

    function getTicketsPerUser(address user) external view returns (uint256) {
        return cumulativeTicketCount[user];
    }

    function getTimeLeftToDraw() external view returns (uint256) {
        if (block.timestamp < lastDrawTime + WEEK_DURATION) {
            return (lastDrawTime + WEEK_DURATION) - block.timestamp;
        }
        return 0;
    }

    function getLeaderboard() external view returns (Leaderboard[] memory) {
        return leaderboard;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert InvalidCaller();
        _;
    }
    
    modifier onlyActive() {
        if (!raffleActive) revert RaffleNotActive();
        _;
    }

    modifier weeklyDrawDue() {
        if (block.timestamp < lastDrawTime + WEEK_DURATION) revert RaffleNotDueYet();
        _;
    }

    receive() external payable {}

    function getFunctionSelectors() external pure virtual returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](13);
        selectors[0] = bytes4(keccak256(bytes("enterRaffle(uint256)")));
        selectors[1] = bytes4(keccak256(bytes("withdrawBunny(address)")));
        selectors[2] = bytes4(keccak256(bytes("setTicketCost(uint256)")));
        selectors[3] = bytes4(keccak256(bytes("initialize(address,address,address,address,address,uint256)")));
        selectors[4] = bytes4(keccak256(bytes("getLastNumbers()")));
        selectors[5] = bytes4(keccak256(bytes("selectWinners()")));
        selectors[6] = bytes4(keccak256(bytes("getTicketCost()")));
        selectors[7] = bytes4(keccak256(bytes("getTotalParticipants()")));
        selectors[8] = bytes4(keccak256(bytes("getTotalTickets()")));
        selectors[9] = bytes4(keccak256(bytes("getWinners()")));
        selectors[10] = bytes4(keccak256(bytes("getTicketsPerUser(address)")));
        selectors[11] = bytes4(keccak256(bytes("getTimeLeftToDraw()")));
        selectors[12] = bytes4(keccak256(bytes("getLeaderboard()")));
        return selectors;
    }
}
