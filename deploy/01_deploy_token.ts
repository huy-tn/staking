import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";

const deployToken: DeployFunction = async function (
    hre: HardhatRuntimeEnvironment
) {
    console.log("Hello");
    const { getNamedAccounts, deployments } = hre;
    const { deploy, log } = deployments;
    const { deployer } = await getNamedAccounts();
    log("Deploying SPO Token");

    const SPOToken = await deploy("SPOToken", {
        from: deployer,
        // args: [],
        log: true,
    });
    log(`Deploy SPO Token to address ${SPOToken.address}`);

    const accounts = await hre.ethers.getSigners()
    for (const account of accounts) {
        console.log(account.address);
    }};

export default deployToken;
module.exports.tags = ["all", "v1", "v2"];
