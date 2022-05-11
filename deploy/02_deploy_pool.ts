import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
require("dotenv").config();
const deployFarm: DeployFunction = async function (
    hre: HardhatRuntimeEnvironment
) {
    console.log("Hello");
    const { getNamedAccounts, deployments } = hre;
    const { deploy, log } = deployments;
    const { deployer } = await getNamedAccounts();
    log("Deploying Farm");

    // const SPOTokenContract = ethers.getContractAt()
    const SPOTokenContract = await ethers.getContract("SPOToken", deployer);
    const VERSION = process.env.VERSION;

    let stakingContractName = "StakingPool";
    if (VERSION === "2") stakingContractName = "StakingPoolV2";

    const StakingPool = await deploy(stakingContractName, {
        from: deployer,
        args: [SPOTokenContract.address, 50000],
        log: true,
    });

    const feed_tx = await SPOTokenContract.approve(
        StakingPool.address,
        "1000000000000000000000000" //1000000 SPO
    );
    await feed_tx.wait(1);

    const accounts = await hre.ethers.getSigners();

    const balance = await SPOTokenContract.balanceOf(StakingPool.address);
    const balance_deployer = await SPOTokenContract.balanceOf(
        accounts[0].address
    );

    log(`Deploy Farm to address ${StakingPool.address}`);
    log(`Balance of Farm ${balance.toString()} ${balance_deployer.toString()}`);
};

export default deployFarm;
module.exports.tags = ["all"];
