// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {ModuleVRF} from "./ModuleVRF.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract ModuleJudge is ModuleVRF, VRFConsumerBaseV2{
    // 定义每个provider每天的最大参与评价次数上限
    uint256 public constant DAILY_REVIEWS_LIMIT = 10; 
    // 服务提供者的地址
    address[] s_provider;
    mapping(address provider => uint256) s_providerToIndex;
    uint256 s_providerCount;

    // Chainlink VRF请求id数组
    uint256[] s_requestId;
    mapping(uint256 requestId => address) s_requestIdToProvider;
    uint256 s_requestIdCount;

    // 映射服务提供者到使用着地址
    mapping(address => address[]) s_providerToUsers;

    // 记录每个服务提供者每天收到的评价数量和时间戳
    mapping(address => uint256) private s_providerDailyReviewsCount;
    mapping(address => uint256) private s_providerLastReviewTimestamp;

    constructor(address vrfCoordinatorV2) ModuleVRF() VRFConsumerBaseV2(vrfCoordinatorV2) {}

    // 添加新的评价请求
    function requestReview(address provider) external returns (uint256 requestId) {
        require(s_providerDailyReviewsCount[provider] < DAILY_REVIEWS_LIMIT, "Daily limit reached");
        uint256 currentDay = block.timestamp / 1 days;
        
        // 如果当前请求是新的一天，则重置计数器
        if (s_providerLastReviewTimestamp[provider] / 1 days < currentDay) {
            s_providerDailyReviewsCount[provider] = 0;
        }

        // 增加今天的评价次数
        s_providerDailyReviewsCount[provider]++;
        s_providerLastReviewTimestamp[provider] = block.timestamp;

        // 调用Module VRF的函数来请求随机数
        uint256 length = s_providerToUsers[provider].length;
        requestId = requestVRF(uint32(length));

        // 保存请求id
        s_requestId.push(requestId);
        s_requestIdToProvider[requestId] = provider;

        // 映射provider到当前用户请求者
        s_providerToUsers[provider].push(msg.sender);

        return requestId;
    }
    
    // 处理VRF响应，执行评价
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual override {
        // 获取提供者地址
        address provider = s_requestIdToProvider[requestId]; // 根据requestId来确定哪个提供者
        uint256 randomness = randomWords[0];
        // 使用随机数判断是否执行评价
        bool shouldStartReview = (randomness % 2) == 0; // 简单示例，你可以设置更复杂的条件

        if (shouldStartReview) {
            // 计算启动评价的延迟时间
            uint256 delayTime = randomness % 1 weeks; // 设定延迟时间，一周
            
            // 延迟特定时间执行评价
            // 定义一个用于实际处理评价的内部函数，这里只是假设的函数名和逻辑
            _scheduleReview(provider, delayTime); // 这是伪代码，请根据你的需求实现这个功能
        }
    }
    
    // 使用Chainlink的VRF来请求随机数
    function requestRandomness() internal returns (uint256 requestId) {
        // ... 实现具体的VRF请求逻辑
    }

    function _scheduleReview(address provider, uint256 delayTime) internal {
        // ... 实现评价的调度逻辑
    }
}