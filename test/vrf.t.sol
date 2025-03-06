// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2Mock.sol";
import {VRFDeployer} from "../src/init/VRFDeployer.sol";


contract ChainlinkVRF_test is Test {
  // Initializing the contract instances
    VRFDeployer public chainlinkVRF;
    VRFCoordinatorV2Mock public vrfCoordinatorV2Mock;

    // These variables will keep a count of the number of times each
    // random number number was generated
    uint counter1; uint counter2; uint counter3;

    function setUp() public {
        vrfCoordinatorV2Mock = new VRFCoordinatorV2Mock(100000000000000000, 1000000000);
        uint64 subId = vrfCoordinatorV2Mock.createSubscription();

        //funding the subscription with 1000 LINK
        vrfCoordinatorV2Mock.fundSubscription(subId, 1000000000000000000000);

        chainlinkVRF = new VRFDeployer(subId, 0, address(vrfCoordinatorV2Mock));
        vrfCoordinatorV2Mock.addConsumer(subId, address(chainlinkVRF));
    }    

    function testrequestRandomWords() public {

            for(uint i = 0; i < 10; i++)
            {                    
                uint256 requestId = chainlinkVRF.useChainlinkVRFV2();
                vrfCoordinatorV2Mock.fulfillRandomWords(requestId, address(chainlinkVRF));

                if(chainlinkVRF.number() == 1){
                    counter1++;
                } else if(chainlinkVRF.number() == 2){
                    counter2++;
                } else {
                    counter3++;
                }   
            }

            console2.log("Number of times 1 was generated: ", counter1);
            console2.log("Number of times 2 was generated: ", counter2);
            console2.log("Number of times 3 was generated: ", counter3);


            uint256[5] memory numbers = chainlinkVRF.getLastNumbers();

            console2.log("Last 5 numbers generated: ", numbers[0]);
            console2.log("Last 5 numbers generated: ", numbers[1]);
            console2.log("Last 5 numbers generated: ", numbers[2]);
            console2.log("Last 5 numbers generated: ", numbers[3]);
            console2.log("Last 5 numbers generated: ", numbers[4]);

        }


}