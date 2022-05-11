# Staking

Contracts:
- SPOToken.sol: A simple token, which is the staking and reward token.
- StakingPool.sol: basic version, which have for loop when updating rate.
- StakingPoolV2.sol: more advanced version, the loop is eliminated and use some concepts from MasterChef (Sushiswap), as well as refactor some code and some improvements.

To install dependencies:
```
yarn install
```
To deploy, run:
```
yarn hardhat deploy
```
To run script:
```
yarn hardhat node
yarn hardhat run scripts/<filename>.ts --network localhost
```

In the scripts, the staking contract hold the staking token, while deployer (owner) hold the reward. The deployer need to allow staking contract to transfer reward from the deployer's address.
As the deploy and script use `increaseTime` call, it can run on local testnet only.
Can specify which contract version to deploy by changing VERSION variable in .env file (V2 is default).

