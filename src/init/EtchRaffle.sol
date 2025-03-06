// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Diamond } from "../Diamond.sol";
import { DiamondInit } from "./DiamondInit.sol";
import { OwnershipFacet } from "../facets/OwnershipFacet.sol";
import { DiamondCutFacet } from "../facets/DiamondCutFacet.sol";
import { IDiamondCut } from "../interfaces/IDiamondCut.sol";
import { IFacet } from "../interfaces/IFacet.sol";
import { IDiamond } from "../interfaces/IDiamond.sol";

/**
 * @title EtchRaffle
 * @notice A contract for deploying and initializing a Diamond proxy raffle.
 * @dev This contract is responsible for deploying the Diamond proxy, adding facets, and initializing the contract.
 */
contract EtchRaffle {

    // State variables
    Diamond diamond; // The Diamond proxy contract.
    DiamondCutFacet dCutFacet; // The DiamondCutFacet contract.
    OwnershipFacet ownerF; // The OwnershipFacet contract.
    DiamondInit dInit; // The DiamondInit contract.
    
    address private immutable deployer; // The address of the deployer contract.
    address public raffle; // The address of the raffle contract.

    constructor(
        address _deployer 
    ) {
        deployer = _deployer;
    }

    function preDeploy(
        address _vaultUpgrade
    )
        public
        onlyDeployer
        returns (address)
    {
        // Deploy facets
        dCutFacet = new DiamondCutFacet();
        diamond = new Diamond(address(this), address(dCutFacet));
        ownerF = new OwnershipFacet();
        dInit = new DiamondInit();

        // Build cut struct
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](3);

        cut[0] = (
            IDiamondCut.FacetCut({
                facetAddress: address(ownerF),
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: IFacet(
                    address(ownerF)
                ).getFunctionSelectors()
            })
        );

        cut[1] = (
            IDiamondCut.FacetCut({
                facetAddress: address(dInit),
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: IFacet(address(dInit)).getFunctionSelectors()
            })
        );

        cut[2] = (
            IDiamondCut.FacetCut({
                facetAddress: address(dCutFacet),
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: IFacet(address(dCutFacet)).getFunctionSelectors()
            })
        );

        // Upgrade diamond
        IDiamondCut(address(diamond)).diamondCut(cut, address(0x0), "");
        IDiamond(address(diamond)).transferOwnership(_vaultUpgrade);
            
        // Initialization
        DiamondInit(address(diamond)).init();
        raffle = address(diamond);

        return raffle;
    }
    
    modifier onlyDeployer() {
        require(msg.sender == deployer, "EtchRaffle: Only deployer can call this function");
        _;
    }
}