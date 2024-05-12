// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

library LibTypeDef {
    enum RoleType {
        PATIENT,
        DOCTOR,
        SERVICE,
        DATA
    }

    struct MedicalRecord {
        mapping(uint256 index => address) indexToProvider;
        uint256 createTimeSinceEpoch;
    }

    struct NetworkConfig {
        uint64 subscriptionId;
        bytes32 gasLane;
        uint256 automationUpdateInterval;
        uint32 callbackGasLimit;
        address vrfCoordinatorV2;
        address link;
        uint256 deployerKey;
        address priceFeed;
    }

    struct FundInfo {
        address userAddress;
        uint256 startTimeSinceEpoch;
        uint256 requiredAmountInWei;
        uint256 actualAmountInWei;
        uint256 tempAmountInWei;
        uint256 endTimeSinceEpoch;
    }

    struct ContributionInfo {
        address patient;
        address initiator;
        address provider;
        uint256 amountInWei;
        uint256 timeSinceEpoch;
    }

    enum CountingState {
        ON,
        OFF
    }
}
