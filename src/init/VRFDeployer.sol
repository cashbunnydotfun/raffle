// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/vrf/dev/interfaces/IVRFCoordinatorV2Plus.sol";
import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";

contract VRFDeployer is VRFConsumerBaseV2 {
    IVRFCoordinatorV2Plus public coordinatorV25;
    VRFCoordinatorV2Interface public coordinatorV2;

    uint64 private subscriptionIdV2;
    uint256 private subscriptionIdV25;
    bytes32 private constant KEY_HASH = 0x1770bdc7eec7771f7ba4ffd640f34260d7f095b79c92d34a5b2551d6f6cfd2be;
    uint32 private constant CALLBACK_GAS_LIMIT = 100000;
    uint16 private constant BLOCK_CONFIRMATIONS = 10;
    uint32 private constant NUM_WORDS = 1;

    // Variable to store the generated random number
    uint256 public number;

    // Array to store the last 5 random numbers
    uint256[5] public lastFiveNumbers;

    event CoordinatorDeployed(address coordinator);
    event RandomNumberGenerated(uint256 randomNumber);

    constructor(
        uint64 _subscriptionIdV2, 
        uint256 _subscriptionIdV25, 
        address vrfCoordinatorV2Address
    )
        VRFConsumerBaseV2(vrfCoordinatorV2Address)
    {
        subscriptionIdV2 = _subscriptionIdV2;
        subscriptionIdV25 = _subscriptionIdV25;
        coordinatorV2 = VRFCoordinatorV2Interface(vrfCoordinatorV2Address);
        coordinatorV25 = IVRFCoordinatorV2Plus(vrfCoordinatorV2Address);
    }


    function useChainlinkVRFV2() public returns (uint256 requestId) {
        requestId = coordinatorV2.requestRandomWords(
            KEY_HASH,
            subscriptionIdV2,
            BLOCK_CONFIRMATIONS,
            CALLBACK_GAS_LIMIT,
            NUM_WORDS
        );
        return requestId;
    }
    
    function useChainlinkVRF25() public returns (uint256 requestId) {
        requestId = coordinatorV25.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: KEY_HASH,
                subId: subscriptionIdV25,
                numWords: NUM_WORDS,
                callbackGasLimit: CALLBACK_GAS_LIMIT,
                requestConfirmations: BLOCK_CONFIRMATIONS,
                extraArgs: VRFV2PlusClient._argsToBytes(
                VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
        )
            })
        );
        return requestId;
    }

    function fulfillRandomWords(uint256, uint256[] memory randomWords) internal override {
        uint256 randomNumber = (randomWords[0] % 100) + 1;

        if (randomNumber == 100) {
            number = 1;
        } else if (randomNumber % 3 == 0) {
            number = 2;
        } else {
            number = 3;
        }

        // Shift numbers in the array (FIFO queue) and store the latest value
        for (uint256 i = 4; i > 0; i--) {
            lastFiveNumbers[i] = lastFiveNumbers[i - 1];
        }
        lastFiveNumbers[0] = randomNumber;

        emit RandomNumberGenerated(randomNumber);
    }

    function getLastNumbers() external view returns (uint256[5] memory) {
        return lastFiveNumbers;
    }

    function getCoordinatorAddressV2() external view returns (address) {
        return address(coordinatorV2);
    }

    function getCoordinatorAddressV25() external view returns (address) {
        return address(coordinatorV25);
    }
}
