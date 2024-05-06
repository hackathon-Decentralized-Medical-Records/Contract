// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {AggregatorV3Interface} from "@chainlink-brownie-contracts/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {Role} from "./Role.sol";

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

contract System is ReentrancyGuard {
    /**
     * Type declarations
     */
    enum RoleType {
        PATIENT,
        DOCTOR,
        SERVICE,
        DATA
    }

    struct FundInfo {
        address userAddress;
        uint256 startTimeSinceEpoch;
        uint256 requiredAmountInWei;
        uint256 actualAmountInWei;
        uint256 tempAmountInWei;
        uint256 endTimeSinceEpoch;
    }

    /**
     * State Variables
     */
    mapping(address user => address) private s_userToContract;
    mapping(address user => RoleType) private s_userToRoleType;
    FundInfo[] private s_fundInfo;
    uint256 s_fundInfoCounter;
    AggregatorV3Interface private s_priceFeed;

    /**
     * Events
     */
    event System__NewUserContractAdded(address indexed user, address indexed contractAddress, uint8 indexed roleType);
    event System__NewUserAdded(address indexed user, uint8 indexed roleType);
    event System__NewFundRegistered(uint256 indexed fundInfoIndex, address user, uint256 amountInUsd, uint80 indexed roundId);
    event System__DonationLimitReached(uint256 indexed index, address indexed user, uint256 amountInWei);
    event System__NewDonation(uint256 indexed index, address user, address indexed sender, uint256 amountInWei);
    event System__WithdrawFund(uint256 indexed index, address indexed user, uint256 amountInWei);

    /**
     * Functions
     */
    constructor(address PriceFeed) {
        s_priceFeed = AggregatorV3Interface(PriceFeed);
    }

    /**
     * frontend ABI
     * @dev mapping new user and his contract to system
     * @param roleType type of user. main charactor :0 - patient, 1 - doctor
     */
    function addNewUserToSystem(RoleType roleType) public nonReentrant {
        s_userToRoleType[msg.sender] = roleType;
        emit System__NewUserAdded(msg.sender, uint8(roleType));
        if (roleType == RoleType.PATIENT) {
            _addNewUserContractToSystem(roleType);
        }
    }

    function getUserToContract(address user) public view returns (address) {
        return s_userToContract[user];
    }

    function _addNewUserContractToSystem(RoleType roleType) private {
        Role role = new Role(msg.sender, address(this), uint8(roleType));
        s_userToContract[msg.sender] = address(role);
        emit System__NewUserContractAdded(msg.sender, address(role), uint8(roleType));
    }

    function registerFundRequest(address user, address contractAddress, uint256 amountInUsd) public {
        if(s_userToContract[user] != contractAddress) {
            revert();
        }
        FundInfo memory fundInfo;
        fundInfo.userAddress = user;
        fundInfo.startTimeSinceEpoch = block.timestamp;
        (uint80 roundId, int256 answer, , , ) = s_priceFeed.latestRoundData();
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
        if(s_fundInfo[index].actualAmountInWei >= s_fundInfo[index].requiredAmountInWei) {
            s_fundInfo[index].endTimeSinceEpoch = block.timestamp;
            emit System__DonationLimitReached(index, user, s_fundInfo[index].actualAmountInWei);
        }
    }

    function withdrawFund(uint256 index) public payable{
        require(s_fundInfo[index].userAddress == msg.sender , "user don't match msg.sender");
        require(s_userToContract[s_fundInfo[index].userAddress] != address(0), "user don't have contract");
        uint256 tempWithdrawAmountInWei = s_fundInfo[index].tempAmountInWei;
        s_fundInfo[index].tempAmountInWei = 0;
        (bool success, )= payable(s_fundInfo[index].userAddress).call{value: tempWithdrawAmountInWei}("");
        if(!success) {
            revert();
        }
        emit System__WithdrawFund(index, msg.sender, tempWithdrawAmountInWei);
    }
}
