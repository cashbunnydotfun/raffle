// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
}

import {Consumer} from "../src/vrf/Consumer.sol";

contract Deploy is Script {
    // Get environment variables.
    uint256 privateKey = vm.envUint("PRIVATE_KEY");
    address deployer = vm.envAddress("DEPLOYER");
    uint256 MAX = 2**256 - 1; // Maximum uint256 value for approvals
    Consumer consumer; 

    
    function run() public {  
        vm.chainId(4216138);
        vm.startBroadcast(privateKey);
        
        // Deploy Chainlink VRF
        // Consumer consumer = new Consumer(
        //     23044934761894326054506003046252108926555862354177597283062196425441119753214
        // );
        IERC20(0xb1D4538B4571d411F07960EF2838Ce337FE1E80E).approve(0x0113E32F56Ab4918FcdB59EE917BbD9D283f2dEa, MAX);
        uint256 reqId = Consumer(0xF28F45FBb45C25236cf39f4D1D903047f0cf176D).requestRandomWords(true);

        (bool fulfilled, uint256[] memory numbers) = Consumer(0xF28F45FBb45C25236cf39f4D1D903047f0cf176D).getRequestStatus(reqId);

        console.log("fulfilled: ", fulfilled);
        // console2.log("Last 5 numbers generated: ", numbers[0]);     

        vm.stopBroadcast();
    }

}   
