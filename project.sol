// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EduPaymentPlans {
    // Struct to represent a payment plan
    struct PaymentPlan {
        uint256 amount;
        uint256 duration; // in seconds
        uint256 startTime;
        address creator;
        bool isActive;
    }

    mapping(address => PaymentPlan[]) public creatorPlans;
    mapping(address => mapping(address => uint256)) public subscriberBalances;

    event PlanCreated(address indexed creator, uint256 indexed planId, uint256 amount, uint256 duration);
    event PaymentMade(address indexed subscriber, address indexed creator, uint256 amount);
    event SubscriptionCancelled(address indexed subscriber, address indexed creator, uint256 planId);

    // Modifier to ensure only the creator can manage their plans
    modifier onlyCreator(address _creator) {
        require(msg.sender == _creator, "Only the content creator can perform this action");
        _;
    }

    // Create a new payment plan
    function createPlan(uint256 _amount, uint256 _duration) external {
        require(_amount > 0, "Amount must be greater than zero");
        require(_duration > 0, "Duration must be greater than zero");

        PaymentPlan memory newPlan = PaymentPlan({
            amount: _amount,
            duration: _duration,
            startTime: block.timestamp,
            creator: msg.sender,
            isActive: true
        });

        creatorPlans[msg.sender].push(newPlan);
        emit PlanCreated(msg.sender, creatorPlans[msg.sender].length - 1, _amount, _duration);
    }

    // Subscribe to a creator's plan
    function subscribe(address _creator, uint256 _planId) external payable {
        require(_planId < creatorPlans[_creator].length, "Invalid plan ID");
        PaymentPlan storage plan = creatorPlans[_creator][_planId];
        require(plan.isActive, "This plan is not active");
        require(msg.value >= plan.amount, "Insufficient payment amount");

        subscriberBalances[msg.sender][_creator] += msg.value;
        emit PaymentMade(msg.sender, _creator, msg.value);
    }

    // Cancel a subscription and refund remaining balance
    function cancelSubscription(address _creator, uint256 _planId) external {
        require(_planId < creatorPlans[_creator].length, "Invalid plan ID");
        PaymentPlan storage plan = creatorPlans[_creator][_planId];
        require(plan.isActive, "This plan is not active");

        uint256 remainingBalance = subscriberBalances[msg.sender][_creator];
        require(remainingBalance > 0, "No remaining balance to refund");

        subscriberBalances[msg.sender][_creator] = 0;
        payable(msg.sender).transfer(remainingBalance);
        emit SubscriptionCancelled(msg.sender, _creator, _planId);
    }

    // Withdraw funds by the creator
    function withdrawFunds() external {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        payable(msg.sender).transfer(balance);
    }
}
