// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {LibTypeDef} from "../../src/utils/LibTypeDef.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {ModuleManage} from "./ModuleManage.sol";

contract ModuleFund is ModuleManage {
    LibTypeDef.FundInfo[] private s_fundInfo;
    uint256 public s_fundInfoCounter = 0;
    AggregatorV3Interface private s_priceFeed;

    constructor(address priceFeed) {
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    event System__NewFundRegistered(
        uint256 indexed fundInfoIndex, address user, uint256 amountInUsd, uint80 indexed roundId
    );

    event System__DonationLimitReached(uint256 indexed index, address indexed user, uint256 amountInWei);
    event System__NewDonation(uint256 indexed index, address user, address indexed sender, uint256 amountInWei);
    event System__FundWithdrawn(uint256 indexed index, address indexed user, uint256 amountInWei);

    function getFundInfo(uint256 index) public view returns (LibTypeDef.FundInfo memory) {
        return s_fundInfo[index];
    }

    function registerFundRequest(address user, address contractAddress, uint256 amountInUsd) public {
        if (s_userToContract[user] != contractAddress) {
            revert();
        }
        LibTypeDef.FundInfo memory fundInfo;
        fundInfo.userAddress = user;
        fundInfo.startTimeSinceEpoch = block.timestamp;
        (uint80 roundId, int256 answer,,,) = s_priceFeed.latestRoundData();
        fundInfo.requiredAmountInWei =  1e18 * amountInUsd * uint256(10 ** s_priceFeed.decimals()) / uint256(answer);
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
}
