// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IStakingPool.sol";

contract StakingPoolV2 is IStakingPool, Ownable {
    struct UserInfo {
        uint256 stakingAmount;
        uint256 oldStakingAmount;
        uint256 unclaimedReward;
        uint256 lastChange;
        uint256 rewardDebt;
    }

    uint256 public rate;
    uint256 public lastRewardDay;
    uint256 public accRewardPerToken;
    address public rewardPoolAddress;

    mapping(address => UserInfo) public userInfo;
    // to store past rate, mapping is more convenient. Array can be used for saving memory
    mapping(uint256 => uint256) public legacyRate; 

    IERC20 public immutable token;
    uint256 public constant SEC_PER_DAY = 1 days; // number of seconds per day
    uint256 public constant DENOM = 365000000; //or, maybe 365250000 (1 year = 365 and 1/4 days)
    uint256 public constant ADJ = 1e12; // to improve the precision when calculating reward

    constructor(address _tokenAddress, uint256 _rate) Ownable() {
        token = IERC20(_tokenAddress);
        rate = _rate; // rate = 50000 means 5%

        rewardPoolAddress = msg.sender; // for simplicity, using owner's balance to pay reward, owner should approve
    }

    function updatePool() public {
        uint256 stamp = block.timestamp / SEC_PER_DAY; // 0h00 stamp
        if (stamp <= lastRewardDay) return;

        uint256 nDay = stamp - lastRewardDay;
        accRewardPerToken += nDay * rate * ADJ;
        lastRewardDay = stamp;
    }

    function unclaimedReward(address _user)
        public
        view
        returns (uint256 pending)
    {
        uint256 stamp = block.timestamp / SEC_PER_DAY; // 0h00 stamp
        UserInfo storage user = userInfo[_user];    

        uint256 nDay = stamp - lastRewardDay;
        uint256 tmpAccRewardPerToken = accRewardPerToken + nDay * rate * ADJ;

        uint256 rawPending = user.unclaimedReward;
        if (user.stakingAmount > 0 && nDay > 0) {
            uint256 r = legacyRate[user.lastChange];

            rawPending +=
                user.stakingAmount * tmpAccRewardPerToken / ADJ - user.rewardDebt - 
                    (user.stakingAmount - user.oldStakingAmount) * r;
        }
        pending = rawPending / DENOM;
    }

    function stakingAmount(address _user) public view returns (uint256) {
        return userInfo[_user].stakingAmount;
    }

    function updateRate(uint256 _newRate) external onlyOwner {
        require(rate != _newRate, "New rate must be different");
        updatePool();

        uint256 stamp = block.timestamp / SEC_PER_DAY;
        // for loop eliminated!!!
        // for (uint256 i = 0; i < stakers.length; i++) 
        //     settle(stakers[i], stamp);

        rate = _newRate;
        legacyRate[stamp] = rate;

        emit UpdateRate(rate);
    }

    function stake(uint256 _amount) external {
        require(_amount > 0, "Stake amount must be larger than 0");
        updatePool();

        UserInfo storage user = userInfo[msg.sender];

        uint256 stamp = block.timestamp / SEC_PER_DAY;
        uint256 nDay = stamp - user.lastChange;

        if (user.stakingAmount > 0 && nDay > 0) settle(user);

        user.stakingAmount += _amount;
        user.rewardDebt = (user.stakingAmount * accRewardPerToken) / ADJ;

        user.lastChange = stamp;
        legacyRate[stamp] = rate;

        require(
            token.transferFrom(msg.sender, address(this), _amount),
            "Transfer failed"
        );

        emit Stake(msg.sender, _amount);
    }

    function unstake(uint256 _amount) external {
        UserInfo storage user = userInfo[msg.sender];

        require(user.stakingAmount > 0, "User haven't staked");
        require(_amount <= user.stakingAmount, "Balance not enough");
        updatePool();

        uint256 stamp = block.timestamp / SEC_PER_DAY;
        uint256 nDay = stamp - user.lastChange;

        if (nDay > 0) settle(user);

        uint256 reward = user.unclaimedReward / DENOM; // all the value are multiplied by DENOM until now
        user.unclaimedReward = 0;
        user.stakingAmount -= _amount;
        user.oldStakingAmount = user.oldStakingAmount > _amount
            ? (user.oldStakingAmount - _amount)
            : 0;

        user.rewardDebt = (user.stakingAmount * accRewardPerToken) / ADJ;
        user.lastChange = stamp;
        legacyRate[stamp] = rate;

        require(token.transfer(msg.sender, _amount), "Transfer failed");

        require(
            token.transferFrom(rewardPoolAddress, msg.sender, reward),
            "Transfer failed"
        );
        emit Unstake(msg.sender, _amount);
    }

    function settle(UserInfo storage _user) internal {
        uint256 r = legacyRate[_user.lastChange];

        _user.unclaimedReward +=
                _user.stakingAmount * accRewardPerToken / ADJ - _user.rewardDebt - 
                    (_user.stakingAmount - _user.oldStakingAmount) * r;
        _user.oldStakingAmount = _user.stakingAmount;
    }
}
