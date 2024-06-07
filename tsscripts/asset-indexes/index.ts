import { ethers } from "ethers";
import * as fs from "fs";
import { buggedAssetPairs } from "./buggedAssetPairs";

const BASE_RPC_URL =
  "https://base-mainnet.g.alchemy.com/v2/wiXuGY3sLQTGTJUKJ1YPxnIT7zEGu4Uq";

async function main() {
  const provider = new ethers.JsonRpcProvider(BASE_RPC_URL);

  const rewardControllerAbi = [
    "function getAssetIndex(address, address) external view returns (uint256, uint256)",
  ];
  const rewardControllerAddress = "0x91Ac2FfF8CBeF5859eAA6DdA661feBd533cD3780";

  const result: any[] = [];

  for (const pair of buggedAssetPairs) {
    const rewardController = new ethers.Contract(
      rewardControllerAddress,
      rewardControllerAbi,
      provider
    );

    const assetRewardIndex = await rewardController.getAssetIndex(
      pair.asset,
      pair.reward
    );

    result.push({
      asset: pair.asset,
      reward: pair.reward,
      indexToSet: assetRewardIndex[0].toString(),
    });
  }

  fs.writeFileSync(
    "tsscripts/asset-indexes/assetPairIndexes.json",
    JSON.stringify(result, null, 2)
  );
}
main().catch((err) => {
  console.error(err);
});
