// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {AutomationCompatibleInterface} from
    "@chainlink/contracts/src/v0.8/automation/interfaces/AutomationCompatibleInterface.sol";

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

import {Role} from "./Role.sol";
import {LibTypeDef} from "../src/utils/LibTypeDef.sol";

// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

contract System is VRFConsumerBaseV2, AutomationCompatibleInterface, ReentrancyGuard {
    /**
     * Errors
     */
    error System__UpkeepNotNeeded();

    /**
     * State Variables
     */
    mapping(address user => address) private s_userToContract;
    mapping(address user => LibTypeDef.RoleType) private s_userToRoleType;
    mapping(address => uint256) private s_userToContributionTimes;
    mapping(bytes32 => uint256) private s_addressTupleToContributionIndex;
    mapping(address => uint256) private s_TransferFailAddressToAmountInWei;
    uint256 private immutable i_interval;
    uint256 private s_lastTimeStamp;
    uint256 private s_contributionTotalAmount;
    uint256 private s_fundInfoCounter;
    LibTypeDef.FundInfo[] private s_fundInfo;
    LibTypeDef.CountingState private s_countingState;
    LibTypeDef.ContributionInfo[] private s_contributionInfo;
    LibTypeDef.ContributionInfo[] private s_tempContributionInfo;
    AggregatorV3Interface private s_priceFeed;
    //uint32 private s_numWords;

    //VRF Variants
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    uint64 private immutable i_subscriptionId;
    bytes32 private immutable i_gasLane;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;

    /**
     * Events
     */
    event System__NewUserContractAdded(address indexed user, address indexed contractAddress, uint8 indexed roleType);
    event System__NewUserAdded(address indexed user, uint8 indexed roleType);
    event System__NewFundRegistered(
        uint256 indexed fundInfoIndex, address user, uint256 amountInUsd, uint80 indexed roundId
    );
    event System__DonationLimitReached(uint256 indexed index, address indexed user, uint256 amountInWei);
    event System__NewDonation(uint256 indexed index, address user, address indexed sender, uint256 amountInWei);
    event System__FundWithdrawn(uint256 indexed index, address indexed user, uint256 amountInWei);
    event System__UpkeepPerformed(uint256 requestId, uint32 numWords);
    event System__LotteryCompleted();

    /**
     * Functions
     */
    constructor(
        address PriceFeed,
        uint64 subscriptionId,
        bytes32 gasLane, // keyHash
        uint256 interval,
        uint32 callbackGasLimit,
        address vrfCoordinatorV2
    ) VRFConsumerBaseV2(vrfCoordinatorV2) {
        s_priceFeed = AggregatorV3Interface(PriceFeed);
        s_lastTimeStamp = block.timestamp;
        s_countingState = LibTypeDef.CountingState.OFF;

        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = gasLane;
        i_interval = interval;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
    }

    /**
     * frontend ABI
     * @dev mapping new user and his contract to system
     * @param roleType type of user. main character :0 - patient, 1 - doctor
     */
    function addNewUserToSystem(LibTypeDef.RoleType roleType) public nonReentrant {
        s_userToRoleType[msg.sender] = roleType;
        emit System__NewUserAdded(msg.sender, uint8(roleType));
        if (roleType == LibTypeDef.RoleType.PATIENT) {
            _addNewUserContractToSystem(roleType);
        }
    }

    function getUserToContract(address user) public view returns (address) {
        return s_userToContract[user];
    }

    function _addNewUserContractToSystem(LibTypeDef.RoleType roleType) private {
        Role role = new Role(msg.sender, address(this), roleType);
        s_userToContract[msg.sender] = address(role);
        emit System__NewUserContractAdded(msg.sender, address(role), uint8(roleType));
    }

    function registerFundRequest(address user, address contractAddress, uint256 amountInUsd) public {
        if (s_userToContract[user] != contractAddress) {
            revert();
        }
        LibTypeDef.FundInfo memory fundInfo;
        fundInfo.userAddress = user;
        fundInfo.startTimeSinceEpoch = block.timestamp;
        (uint80 roundId, int256 answer,,,) = s_priceFeed.latestRoundData();
        fundInfo.requiredAmountInWei = uint256(answer) * 1e18 * amountInUsd / uint256(s_priceFeed.decimals());
        fundInfo.endTimeSinceEpoch = 0;

        s_fundInfo.push(fundInfo);
        s_fundInfoCounter++;
        emit System__NewFundRegistered(s_fundInfoCounter - 1, msg.sender, amountInUsd, roundId);
    }

    function donation(uint256 index, address user) public payable {
        require(s_fundInfo[index].userAddress == user, "Index to User doesn't match.");
        s_fundInfo[index].actualAmountInWei += msg.value;
        s_fundInfo[index].tempAmountInWei += msg.value;
        emit System__NewDonation(index, user, msg.sender, msg.value);
        if (s_fundInfo[index].actualAmountInWei >= s_fundInfo[index].requiredAmountInWei) {
            s_fundInfo[index].endTimeSinceEpoch = block.timestamp;
            emit System__DonationLimitReached(index, user, s_fundInfo[index].actualAmountInWei);
        }
    }

    function withdrawFund(uint256 index) public payable {
        require(s_fundInfo[index].userAddress == msg.sender, "user don't match msg.sender");
        require(s_userToContract[s_fundInfo[index].userAddress] != address(0), "user don't have contract");
        uint256 tempWithdrawAmountInWei = s_fundInfo[index].tempAmountInWei;
        s_fundInfo[index].tempAmountInWei = 0;
        (bool success,) = payable(s_fundInfo[index].userAddress).call{value: tempWithdrawAmountInWei}("");
        if (!success) {
            revert();
        }
        emit System__FundWithdrawn(index, msg.sender, tempWithdrawAmountInWei);
    }

    //weekly
    function checkUpkeep(bytes memory /* checkData */ )
        public
        view
        override
        returns (bool upkeepNeeded, bytes memory /* performData */ )
    {
        bool isOff = s_countingState == LibTypeDef.CountingState.OFF;
        bool TimePassed = block.timestamp - s_lastTimeStamp >= i_interval;
        bool hasPlayer = s_contributionInfo.length > 0;
        bool hasBalance = s_contributionTotalAmount > 0 && address(this).balance >= s_contributionTotalAmount;
        upkeepNeeded = isOff && TimePassed && hasPlayer && hasBalance;
    }

    function performUpkeep(bytes calldata /* performData */ ) external {
        (bool upkeepNeeded,) = checkUpkeep("");

        if (!upkeepNeeded) {
            revert System__UpkeepNotNeeded();
        }

        s_countingState = LibTypeDef.CountingState.OFF;
        s_lastTimeStamp = block.timestamp;

        uint32 numSize = uint32(s_contributionInfo.length / 10);

        if (numSize == 0) {
            numSize = 1;
        }

        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane, i_subscriptionId, REQUEST_CONFIRMATIONS, i_callbackGasLimit, numSize
        );

        emit System__UpkeepPerformed(requestId, numSize);
    }

    function fulfillRandomWords(uint256, /* requestId */ uint256[] memory randomWords) internal override {
        uint256 length = randomWords.length;

        for (uint256 i = 0; i < length; i++) {
            uint256 index = randomWords[i] % s_contributionInfo.length;
            LibTypeDef.ContributionInfo memory contributionInfo = s_contributionInfo[index];

            uint256 amountInWei = contributionInfo.amountInWei;
            uint256 totalTransferAmountInWei = 0;

            address to = payable(contributionInfo.provider);
            (bool success,) = to.call{value: amountInWei}("");
            if (!success) {
                s_TransferFailAddressToAmountInWei[to] = amountInWei;
            }
            totalTransferAmountInWei += amountInWei;

            to = payable(contributionInfo.initiator);
            (success,) = to.call{value: amountInWei}("");
            if (!success) {
                s_TransferFailAddressToAmountInWei[to] = amountInWei;
            }
            totalTransferAmountInWei += amountInWei;

            to = payable(contributionInfo.patient);
            (success,) = to.call{value: amountInWei}("");
            if (!success) {
                s_TransferFailAddressToAmountInWei[to] = amountInWei;
            }
            totalTransferAmountInWei += amountInWei;
            s_contributionTotalAmount -= totalTransferAmountInWei;
        }
        emit System__LotteryCompleted();
        s_countingState = LibTypeDef.CountingState.ON;
    }
}
