// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";

import {Diamond} from "../src/Diamond.sol";
import {DiamondInit} from "../src/init/DiamondInit.sol";
import {OwnershipFacet} from "../src/facets/OwnershipFacet.sol";
import {DiamondCutFacet} from "../src/facets/DiamondCutFacet.sol";
import {IDiamondCut} from "../src/interfaces/IDiamondCut.sol";
import {IFacet} from "../src/interfaces/IFacet.sol";
import {IDiamond} from "../src/interfaces/IDiamond.sol";

import {BaseRaffle} from  "../src/raffle/BaseRaffle.sol";
import {RaffleUpgrade, RaffleUpgradeFinalize} from "../src/init/RaffleUpgrade.sol"; //RaffleUpgradeStep1, RaffleUpgradeStep2,
import {EtchRaffle} from "../src/init/EtchRaffle.sol";
import {VRFDeployer} from "../src/init/VRFDeployer.sol";

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2Mock.sol";

import {CashBunny} from "../src/token/CashBunny.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

interface IRaffleUpgrade {
    function doUpgradeStart(address diamond, address _vaultUpgradeFinalize) external;
    function doUpgradeFinalize(address diamond) external;
}

contract Deploy is Script {
    // Get environment variables.
    uint256 privateKey = vm.envUint("PRIVATE_KEY");
    address deployer = vm.envAddress("DEPLOYER");

    Diamond diamond;
    DiamondCutFacet dCutFacet;
    OwnershipFacet ownerF;
    DiamondInit dInit;

    address raffleUpgradeAddress;
    address raffleUpgradeFinalizeAddress;

    BaseRaffle public raffle;
    address public cashBunnyToken;

    VRFDeployer public chainlinkVRF;
    VRFDeployer public chainlinkVRF2;
    VRFCoordinatorV2Mock public vrfCoordinatorV2Mock;
    CashBunny public cashBunny;

    uint counter1; uint counter2; uint counter3;
    
    address vrfCoordinator = 0x50d47e4142598E3411aA864e08a44284e471AC6f;

    function run() public {  

        vm.startBroadcast(privateKey);

        // Deploy CashBunny Token
        cashBunny = new CashBunny(
            0x8cFe327CEc66d1C090Dd72bd0FF11d690C33a2Eb,
            100_000_000,
            deployer
        );

        cashBunny.setDistributionContractAndRenounce(0x5Df089ff2eaB44684717D876077D8C3a7E951819);
        console.log("CashBunny deployed to address: ", address(cashBunny));
            
        IERC20(address(cashBunny)).transfer(0x12e30FcC16B741a08cCf066074F0547F3ce79F32, 1_000_000e18);

        address distributor = cashBunny.distributionContract();
        console.log("CashBunny distributor: ", distributor);

        // Deploy Chainlink VRF
        // uint256 subIdV25 = 23044934761894326054506003046252108926555862354177597283062196425441119753214; 
        vrfCoordinatorV2Mock = new VRFCoordinatorV2Mock(100000000000000000, 1000000000);
        console.log("VRFCoordinatorV2Mock deployed to address: ", address(vrfCoordinatorV2Mock));
        
        uint64 subIdV2 = vrfCoordinatorV2Mock.createSubscription();

        //funding the subscription with 1000 LINK
        vrfCoordinatorV2Mock.fundSubscription(subIdV2, 1000000000000000000000);

        chainlinkVRF = new VRFDeployer(subIdV2, 0, address(vrfCoordinatorV2Mock));
        vrfCoordinatorV2Mock.addConsumer(subIdV2, address(chainlinkVRF));

        console.log("Chainlink VRF deployed to address: ", address(chainlinkVRF));

        RaffleUpgrade raffleUpgrade = new RaffleUpgrade(deployer);
        console.log("RaffleUpgrade deployed to address: ", address(raffleUpgrade));
        
        EtchRaffle etchRaffle = new EtchRaffle(deployer);
        console.log("EtchRaffle deployed to address: ", address(etchRaffle));

        address payable raffleAddress = payable(etchRaffle.preDeploy(address(raffleUpgrade)));
        console.log("Raffle contract deployed to address: ", raffleAddress);

        raffle = BaseRaffle(raffleAddress);

        IRaffleUpgrade(address(raffleUpgrade)).doUpgradeStart(raffleAddress, raffleAddress);
        vm.stopBroadcast();

        vm.prank(deployer);
        raffle.initialize(address(chainlinkVRF), address(vrfCoordinatorV2Mock), address(0), deployer, address(cashBunny), 2500e18);

        // requestRandomWords();

    }   

    function requestRandomWords() public {

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
