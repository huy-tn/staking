// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IStakingPool.sol";

contract StakingPool is IStakingPool, Ownable {
    uint256 public rate;
    address public rewardPoolAddress;


    mapping(address => uint256) public stakingAmount;
    mapping(address => uint256) private _oldStakingAmount;
    mapping(address => uint256) private _unclaimedReward;
    mapping(address => uint256) public lastChange;

    address[] private stakers;

    IERC20 public immutable token;
    uint256 public constant SEC_PER_DAY = 86400; // number of seconds per day
    uint256 public constant DENOM = 365000000; //or, maybe 365250000 (1 year = 365 and 1/4 days)

    constructor(address _tokenAddress, uint256 _rate) Ownable() {
        token = IERC20(_tokenAddress);
        rate = _rate; // rate = 50000 means 5%
        rewardPoolAddress = msg.sender;
    }

    function updateRate(uint256 newRate) external onlyOwner {
        require(rate != newRate, "New rate must be different");

        uint256 stamp = block.timestamp / SEC_PER_DAY;
        // gas consuming
        for (uint256 i = 0; i < stakers.length; i++) 
            settle(stakers[i], stamp);

        rate = newRate;
        emit UpdateRate(rate);
    }

    function stake(uint256 amount) external {
        require(amount > 0, "Stake amount must be larger than 0");

        if (lastChange[msg.sender] == 0) stakers.push(msg.sender); // a completely new staker
        settle(msg.sender, 0);
        stakingAmount[msg.sender] += amount;

        require(
            token.transferFrom(msg.sender, address(this), amount),
            "Transfer failed"
        );
        emit Stake(msg.sender, amount);
    }

    function unstake(uint256 amount) external {
        require(stakingAmount[msg.sender] > 0, "User haven't staked");
        require(amount <= stakingAmount[msg.sender], "Balance not enough");

        settle(msg.sender, 0);

        uint256 toWithdraw = _unclaimedReward[msg.sender];
        _unclaimedReward[msg.sender] = 0;
        stakingAmount[msg.sender] -= amount;

        _oldStakingAmount[msg.sender] = _oldStakingAmount[msg.sender] > amount
            ? (_oldStakingAmount[msg.sender] - amount)
            : 0;
        // if (_oldStakingAmount[msg.sender] > stakingAmount[msg.sender])
        //     _oldStakingAmount[msg.sender] = stakingAmount[msg.sender];

        require(
            token.transfer(msg.sender, amount),
            "Transfer failed"
        );
        require(
            token.transferFrom(rewardPoolAddress, msg.sender, toWithdraw),
            "Transfer failed"
        );
        emit Unstake(msg.sender, amount);
    }

    function settle(address staker, uint256 stamp) internal {
        // settle reward until yesterday
        if (stamp == 0) stamp = block.timestamp / SEC_PER_DAY; //lazy case, stamp need to be calculated
        uint256 nDay = stamp - lastChange[staker];
        if (stakingAmount[staker] > 0 && nDay > 0) {
            // settle(msg.sender, nDay);
            _unclaimedReward[staker] +=
                (_oldStakingAmount[staker] + (nDay - 1) * stakingAmount[staker]) * rate / DENOM;
            _oldStakingAmount[staker] = stakingAmount[staker];
        }

        lastChange[staker] = stamp;
    }

    // public function to retrieve unclaimed reward more exactly, because private state mapping is lazy
    // function unclaimedReward(address staker) public {

    // }
}
