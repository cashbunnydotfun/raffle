// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import {BaseRaffle} from "../src/raffle/BaseRaffle.sol";
import {CashBunny} from "../src/token/CashBunny.sol";

contract RaffleTest is Test {
    BaseRaffle raffle;
    CashBunny cashBunny;

    uint256 privateKey = vm.envUint("PRIVATE_KEY");
    address deployer = vm.envAddress("DEPLOYER");
    uint256 MAX = 2**256 - 1; // Maximum uint256 value for approvals

    address userA = address(2);
    address userB = address(3);
    address userC = address(4);

    address[] users;
    uint256 NUM_USERS = 50;

    function setUp() public {

        raffle = BaseRaffle(
            payable(0xb737709B41b895885515b3Af5815c9F5202dDeCC)
        );
        
        cashBunny = CashBunny(
            payable(0xfefC4fc51924889F788d697e7BC8362F63414B8E)
        );  

        address distributionContract = cashBunny.distributionContract();
        console.log("Distribution contract: ", distributionContract);

        vm.prank(deployer);
        cashBunny.mint(deployer, 100_000e18);
        cashBunny.mint(userA,    100_000e18);
        cashBunny.mint(userB,    100_000e18);
        cashBunny.mint(userC,    100_000e18);

        // Create users and give them tokens
        for (uint i = 0; i < NUM_USERS; i++) {
            address user = address(uint160(i + 1000));
            users.push(user);
            cashBunny.mint(user, 100_000e18);
        }

        // ✅ Fund deployer with ETH if needed
        uint256 initialETH = 10 ether;
        vm.deal(deployer, initialETH);

        // ✅ Send 1 ETH to Raffle contract
        vm.prank(deployer);
        (bool sent, ) = address(raffle).call{value: initialETH}("");
        require(sent, "ETH Transfer to Raffle failed");

        console.log("ETH sent to Raffle:", address(raffle).balance);        
    }

    function testEnterRaffle() public {
        uint256 ticketCount = 1;
        
        vm.prank(deployer);
        cashBunny.approve(address(raffle), MAX);

        uint256 balance = cashBunny.balanceOf(deployer);
        console.log("Balance: ", balance);

        uint256 allowance = cashBunny.allowance(deployer, address(raffle));
        console.log("Allowance: ", allowance);

        vm.prank(address(raffle));
        cashBunny.approve(address(raffle), MAX);

        vm.prank(address(raffle));
        uint256 allowanceRaffle = cashBunny.allowance(address(raffle), address(raffle));
        console.log("Allowance Raffle: ", allowanceRaffle);

        vm.prank(deployer);
        raffle.enterRaffle(ticketCount);
        console.log("Raffle entered successfully");
    }

    function testEnterRaffleMultipleTickets() public {
        uint256 ticketCount = 100;
        
        vm.prank(deployer);
        cashBunny.approve(address(raffle), MAX);

        uint256 balance = cashBunny.balanceOf(deployer);
        console.log("Balance: ", balance);

        uint256 allowance = cashBunny.allowance(deployer, address(raffle));
        console.log("Allowance: ", allowance);

        vm.prank(address(raffle));
        cashBunny.approve(address(raffle), MAX);

        vm.prank(address(raffle));
        uint256 allowanceRaffle = cashBunny.allowance(address(raffle), address(raffle));
        console.log("Allowance Raffle: ", allowanceRaffle);

        vm.prank(deployer);
        raffle.enterRaffle(ticketCount);
        console.log("Raffle entered successfully");
    }

    function testEnterRaffleMultipleUsers() public {
        uint256 ticketCount = 1;
        
        vm.prank(deployer);
        cashBunny.approve(address(raffle), MAX);

        uint256 balance = cashBunny.balanceOf(deployer);
        console.log("Balance: ", balance);

        uint256 allowance = cashBunny.allowance(deployer, address(raffle));
        console.log("Allowance: ", allowance);

        vm.prank(address(raffle));
        cashBunny.approve(address(raffle), MAX);

        vm.prank(address(raffle));
        uint256 allowanceRaffle = cashBunny.allowance(address(raffle), address(raffle));
        console.log("Allowance Raffle: ", allowanceRaffle);

        vm.prank(deployer);
        raffle.enterRaffle(ticketCount);
        console.log("Raffle entered successfully");

        vm.prank(userA);
        cashBunny.approve(address(raffle), MAX);

        vm.prank(address(raffle));
        cashBunny.approve(address(raffle), MAX);

        vm.prank(userA);
        raffle.enterRaffle(ticketCount);
        console.log("Raffle entered successfully");

        vm.prank(userB);
        cashBunny.approve(address(raffle), MAX);

        vm.prank(address(raffle));
        cashBunny.approve(address(raffle), MAX);

        vm.prank(userB);
        raffle.enterRaffle(ticketCount);
        console.log("Raffle entered successfully");

        vm.prank(userC);
        cashBunny.approve(address(raffle), MAX);

        vm.prank(address(raffle));
        cashBunny.approve(address(raffle), MAX);

        vm.prank(userC);
        raffle.enterRaffle(ticketCount);
        console.log("Raffle entered successfully");
    }


    function testEnterRaffleOneHundredUsers() public {
        
        uint256 ticketCount = 10;
        
        for (uint i = 0; i < NUM_USERS; i++) {
            address user = address(uint160(i + 1000));
            vm.prank(user);
            cashBunny.approve(address(raffle), MAX);

            vm.prank(address(raffle));
            cashBunny.approve(address(raffle), MAX);

            vm.prank(user);
            raffle.enterRaffle(ticketCount);
        }
    }

    function testSelectWinners100Users() public {

        testEnterRaffleOneHundredUsers();

        vm.prank(deployer);
        raffle.selectWinners();
        console.log("Winner selected successfully");
 
        uint256[5] memory numbers = raffle.getLastNumbers();

        console2.log("Last numbers generated: ", numbers[0]);
        console2.log("Last numbers generated: ", numbers[1]);
        console2.log("Last numbers generated: ", numbers[2]);
        console2.log("Last numbers generated: ", numbers[3]);
        console2.log("Last numbers generated: ", numbers[4]); 
 
    }

    function testSelectWinners() public {

        testEnterRaffleMultipleUsers();

        vm.prank(deployer);
        raffle.selectWinners();
        console.log("Winner selected successfully");
 
        uint256[5] memory numbers = raffle.getLastNumbers();

        console2.log("Last numbers generated: ", numbers[0]);
        console2.log("Last numbers generated: ", numbers[1]);
        console2.log("Last numbers generated: ", numbers[2]);
        console2.log("Last numbers generated: ", numbers[3]);
        console2.log("Last numbers generated: ", numbers[4]); 

        // print all users ETH balances
        for (uint i = 0; i < NUM_USERS; i++) {
            address user = address(uint160(i + 1000));
            uint256 balance = address(user).balance;
            console2.log("User balance: ", balance);
        }
    }


    function testAtLeastOneWinner() public {

        testEnterRaffleOneHundredUsers();

        vm.prank(deployer);
        raffle.selectWinners();
        console.log("Winner selected successfully");
 
        uint256[5] memory numbers = raffle.getLastNumbers();

        console2.log("Last numbers generated: ", numbers[0]);
        console2.log("Last numbers generated: ", numbers[1]);
        console2.log("Last numbers generated: ", numbers[2]);
        console2.log("Last numbers generated: ", numbers[3]);
        console2.log("Last numbers generated: ", numbers[4]); 

        // print all users ETH balances
        for (uint i = 0; i < NUM_USERS; i++) {
            address user = address(uint160(i + 1000));
            uint256 balance = address(user).balance;
            console2.log("User balance: ", balance);
        }

        // check if at least one user has won
        bool atLeastOneWinner = false;

        for (uint i = 0; i < NUM_USERS; i++) {
            address user = address(uint160(i + 1000));
            uint256 balance = address(user).balance;
            if (balance > 0) {
                console.log("Winner balance: ", balance);
                atLeastOneWinner = true;
                break;
            }
        }

        require(atLeastOneWinner, "No winners found");
    }

    function testAtLeastThreeWinners() public {

        testEnterRaffleOneHundredUsers();

        vm.prank(deployer);
        raffle.selectWinners();
        console.log("Winner selected successfully");
 
        uint256[5] memory numbers = raffle.getLastNumbers();

        console2.log("Last numbers generated: ", numbers[0]);
        console2.log("Last numbers generated: ", numbers[1]);
        console2.log("Last numbers generated: ", numbers[2]);
        console2.log("Last numbers generated: ", numbers[3]);
        console2.log("Last numbers generated: ", numbers[4]); 

        // print all users ETH balances
        for (uint i = 0; i < NUM_USERS; i++) {
            address user = address(uint160(i + 1000));
            uint256 balance = address(user).balance;
            console2.log("User balance: ", balance);
        }

        // check if at least one user has won
        uint256 winnerCount = 0;

        for (uint i = 0; i < NUM_USERS; i++) {
            address user = address(uint160(i + 1000));
            uint256 balance = address(user).balance;
            if (balance > 0) {
                console.log("Winner balance: ", balance);
                winnerCount++;
            }
        }

        require(winnerCount >= 3, "Less than 3 winners found");
    }

    function testGetTicketCost() public {
        uint256 ticketCost = raffle.getTicketCost();
        console.log("Ticket cost: ", ticketCost);
    }
}