// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import {BaseRaffle} from "../src/raffle/BaseRaffle.sol";

interface IRaffle {
    function selectWinners() external;
}

contract Test is Script {
    // Get environment variables.
    uint256 privateKey = vm.envUint("PRIVATE_KEY");
    address deployer = vm.envAddress("DEPLOYER");
    IRaffle raffle = IRaffle(
        payable(0xb737709B41b895885515b3Af5815c9F5202dDeCC)
    );

    function run() public {  

        vm.startBroadcast(privateKey);
        raffle.selectWinners();
        console.log("Winners selected");
        vm.stopBroadcast();
    }   


}   
