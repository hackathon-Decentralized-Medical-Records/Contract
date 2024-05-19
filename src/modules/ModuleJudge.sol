// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {ModuleVRF} from "./ModuleVRF.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract ModuleJudge is ModuleVRF {
    // 定义每个provider每天的最大参与评价次数上限
    uint32 public constant DAILY_REVIEWS_LIMIT = 10;
    // 服务提供者的地址
    address[] s_provider;
    mapping(address provider => uint256) s_providerToIndex;
    uint256 s_providerCount;
    mapping(address => uint256) private s_providerTotalScore;
    mapping(address => uint256) private s_providerReviewCount;

    // 映射服务提供者到使用着地址
    mapping(address => address[]) s_providerToUsers;

    // 记录每个服务提供者每天收到的评价数量和时间戳
    mapping(address => uint256) private s_providerDailyReviewsCount;
    mapping(address => uint256) private s_providerLastReviewTimestamp;

    event ModuleJudge__JudgeLotteryDone(address indexed user, address indexed provider, uint256 indexed delayTime);
    event ModuleJudge__ProviderScoreUpdated(address indexed user, address indexed provider, uint256 indexed score);

    // 添加新的评价请求
    function requestReview(address provider) external returns (uint256 requestId) {
        uint256 currentDay = block.timestamp / 1 days;

        // 如果当前请求是新的一天，则重置计数器
        if (s_providerLastReviewTimestamp[provider] / 1 days < currentDay) {
            s_providerDailyReviewsCount[provider] = 0;
        }

        // 调用Module VRF的函数来请求随机数
        uint256 length = s_providerToUsers[provider].length;
        requestId = requestVRF(uint32(length) + 1);

        // 保存请求id
        s_requestId.push(requestId);
        setRequestidToProvider(requestId, provider);

        // 映射provider到当前用户请求者
        s_providerToUsers[provider].push(msg.sender);

        return requestId;
    }

    function judgeLottery(address provider, uint256[] memory randomWords) internal {
        uint256 length = randomWords.length - 1;
        uint256 nextIndex = randomWords[0] % length;
        uint256 reviewCount = 1;
        for (uint256 i = 1; i <= length + 1; i++) {
            if (reviewCount > DAILY_REVIEWS_LIMIT) {
                break;
            }
            uint256 randomNumber = randomWords[i];
            bool shouldStartReview = (randomNumber % 2) == 0;
            if (shouldStartReview) {
                reviewCount++;
                // 计算启动评价的延迟时间
                uint256 delayTime = randomNumber % 1 weeks; // 设定延迟时间
                emit ModuleJudge__JudgeLotteryDone(s_providerToUsers[provider][nextIndex], provider, delayTime);
            }
        }
    }

    // 更新服务提供者的评分和评价次数
    function updateProviderScore(address user, address provider, uint256 score) public {
        require(score <= 5, "Score must be between 0 and 5");
        s_providerTotalScore[provider] += score;
        s_providerReviewCount[provider] += 1;

        emit ModuleJudge__ProviderScoreUpdated(user, provider, score);
    }

    // 获取服务提供者的平均评分
    function getProviderAverageScore(address provider) public view returns (uint256, uint256) {
        if (s_providerReviewCount[provider] == 0) {
            return (0, 0);
        }
        return (s_providerTotalScore[provider], s_providerReviewCount[provider]);
    }
}