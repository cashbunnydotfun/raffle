// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import {BaseRaffle} from "../src/raffle/BaseRaffle.sol";

contract SelectWinners is Script {
    // Get environment variables.
    uint256 privateKey = vm.envUint("PRIVATE_KEY");
    address deployer = vm.envAddress("DEPLOYER");

    BaseRaffle raffle;

    function run() public {
        vm.startBroadcast(privateKey);

        raffle = BaseRaffle(
            payable(0xb737709B41b895885515b3Af5815c9F5202dDeCC)
        );

        raffle.selectWinners();
    
        console.log("Winners selected");
        vm.stopBroadcast();
    }
}