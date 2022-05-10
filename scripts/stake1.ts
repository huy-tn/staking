import { ethers, network } from "hardhat";
import { moveTime } from "../utils/move_time";
import { moveBlocks } from "../utils/move_blocks";
require("dotenv").config();

// const hre = require("hardhat");
// const ethers = hre.ethers;
// const network = hre.network;

export async function stake() {
    const VERSION = process.env.VERSION;

    let stakingContractName = "StakingPool";
    if (VERSION === "2") stakingContractName = "StakingPoolV2";

    const SPOToken = await ethers.getContract("SPOToken");

    const StakingPool = await ethers.getContract(stakingContractName);

    const owners = await ethers.getSigners();

    const owner = owners[0];
    const alice = owners[1];

    // console.log(owners);

    // const accounts = await hre.ethers.getSigners()

    // const balance = await SPOToken.balanceOf(StakingPool.address);
    // console.log(balance.toString());

    const sendToUserTx = await SPOToken.transfer(
        alice.address,
        "150000000000000000000000"
    );

    await SPOToken.connect(alice).approve(
        StakingPool.address,
        "150000000000000000000000"
    );

    const balance_alice = await SPOToken.balanceOf(alice.address);
    console.log(`Alice's balance ${balance_alice.toString()}`);

    const allowanceAlicePool = await SPOToken.allowance(
        alice.address,
        StakingPool.address
    );
    console.log(`allowance ${allowanceAlicePool.toString()}`);
    await StakingPool.connect(alice).stake("100000000000000000000000");

    await moveTime(14 * 3600 * 24);
    await StakingPool.connect(alice).stake("50000000000000000000000");

    const balance_alice_1 = await SPOToken.balanceOf(alice.address);
    console.log(`Alice's balance ${balance_alice_1.toString()}`);

    await moveTime(15 * 3600 * 24);
    await moveBlocks(1); // make block stamp update by mining 1 block

    // retrieve unclaimed reward
    let unclaimed = await StakingPool.unclaimedReward(alice.address);
    console.log(`Alice's unclaimed reward ${unclaimed.toString()}`);

    await StakingPool.connect(alice).unstake("70000000000000000000000");

    const balance_alice_2 = await SPOToken.balanceOf(alice.address);
    console.log(
        `Alice's balance after unstake 700K SPO ${balance_alice_2.toString()}`
    );

    await moveTime(15 * 3600 * 24);
    await moveBlocks(1);

    unclaimed = await StakingPool.unclaimedReward(alice.address);
    console.log(`Alice's unclaimed reward ${unclaimed.toString()}`);

    await StakingPool.connect(alice).unstake("80000000000000000000000");

    const balance_alice_3 = await SPOToken.balanceOf(alice.address);
    console.log(
        `Alice's balance after unstake 800K SPO ${balance_alice_3.toString()}`
    );
}

// async function queryBalance(SPOToken: Contract, ) {
//     const balance_alice = await SPOToken.balanceOf(alice.address);
//     console.log(`Alice's balance ${balance_alice.toString()}`);

// }
stake()
    .then(() => process.exit())
    .catch((err) => {
        console.log(err);
        process.exit(1);
    });
