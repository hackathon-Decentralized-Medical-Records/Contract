// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

abstract contract ModuleVRF {
    //VRF Variants
    VRFCoordinatorV2Interface private s_vrfCoordinator;
    uint64 private s_subscriptionId;
    bytes32 private s_gasLane;
    uint32 private s_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;

    function requestVRF(uint32 numWords) internal returns (uint256 requestId) {
        return requestId = s_vrfCoordinator.requestRandomWords(
            s_gasLane, s_subscriptionId, REQUEST_CONFIRMATIONS, s_callbackGasLimit, numWords
        );
    }

    // Chainlink VRF请求id数组
    uint256[] internal s_requestId;
    mapping(uint256 requestId => address) private s_requestIdToProvider;

    function setVRFConfig(
        uint64 subscriptionId,
        bytes32 gasLane, // keyHash
        uint32 callbackGasLimit,
        address vrfCoordinatorV2
    ) internal {
        s_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        s_gasLane = gasLane;
        s_subscriptionId = subscriptionId;
        s_callbackGasLimit = callbackGasLimit;
    }

    function getRequestIdToProvider(uint256 requestId) internal view returns (address provider) {
        return s_requestIdToProvider[requestId];
    }

    function setRequestidToProvider(uint256 requestId, address provider) internal {
        s_requestIdToProvider[requestId] = provider;
    }
}
