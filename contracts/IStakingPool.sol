// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStakingPool {
    event UpdateRate(uint256);
    event Stake(address indexed, uint256);
    event Unstake(address indexed, uint256);

    function updateRate(uint256 newRate) external;
    function stake(uint256 amount) external;
    function unstake(uint256 amount) external;
    function unclaimedReward(address _user) external view returns(uint256);

}
