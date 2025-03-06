// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

contract Consumer is VRFConsumerBaseV2Plus {
    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);

    struct RequestStatus {
        bool fulfilled;
        bool exists;
        uint256[] randomWords;
    }

    mapping(uint256 => RequestStatus) public s_requests; // requestId -> requestStatus

    uint256 public s_subscriptionId;
    uint256[] public requestIds;
    uint256 public lastRequestId;

    bytes32 public keyHash =
        0x1770bdc7eec7771f7ba4ffd640f34260d7f095b79c92d34a5b2551d6f6cfd2be;

    uint32 public callbackGasLimit = 100000;
    uint16 public requestConfirmations = 3;
    uint32 public numWords = 2;

    // ✅ Store last 5 random numbers
    uint256[5] public lastFiveNumbers;

    /**
     * HARDCODED FOR ARBITRUM SEPOLIA
     * COORDINATOR: 0x5CE8D5A2BC84beb22a398CCA51996F7930313D61
     */
    constructor(
        uint256 subscriptionId
    ) VRFConsumerBaseV2Plus(0x5CE8D5A2BC84beb22a398CCA51996F7930313D61) {
        s_subscriptionId = subscriptionId;
    }

    function requestRandomWords(
        bool enableNativePayment
    ) external onlyOwner returns (uint256 requestId) {
        requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: keyHash,
                subId: s_subscriptionId,
                requestConfirmations: requestConfirmations,
                callbackGasLimit: callbackGasLimit,
                numWords: numWords,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({
                        nativePayment: enableNativePayment
                    })
                )
            })
        );
        s_requests[requestId] = RequestStatus({
            randomWords: new uint256[](0),
            exists: true,
            fulfilled: false
        });
        requestIds.push(requestId);
        lastRequestId = requestId;
        emit RequestSent(requestId, numWords);
        return requestId;
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] calldata _randomWords
    ) internal override {
        require(s_requests[_requestId].exists, "Request not found");

        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;

        // ✅ Store last 5 random numbers (FIFO queue behavior)
        for (uint256 i = lastFiveNumbers.length - 1; i > 0; i--) {
            lastFiveNumbers[i] = lastFiveNumbers[i - 1];
        }
        lastFiveNumbers[0] = _randomWords[0]; // Store latest random number

        emit RequestFulfilled(_requestId, _randomWords);
    }

    /// ✅ View function to get the last 5 random numbers
    function getLastFiveNumbers() external view returns (uint256[5] memory) {
        return lastFiveNumbers;
    }

    function getRequestStatus(
        uint256 _requestId
    ) external view returns (bool fulfilled, uint256[] memory randomWords) {
        require(s_requests[_requestId].exists, "Request not found");
        RequestStatus memory request = s_requests[_requestId];
        return (request.fulfilled, request.randomWords);
    }
}
