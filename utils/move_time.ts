import { network } from "hardhat";

export async function moveTime(amount: number) {
    console.log("Moving time");

    await network.provider.request({
        method: "evm_increaseTime",
        params: [amount],
    });

    console.log(`Moved foward ${amount} seconds`)
}
