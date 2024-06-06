import { ethers } from "ethers";
import * as fs from "fs";

const BASE_RPC_URL = "";

async function makeIndexMap() {
  const assetPairIndexesFile = fs.readFileSync(
    "tsscripts/asset-indexes/assetPairIndexes.json"
  );
  const assetPairIndexes = JSON.parse(assetPairIndexesFile.toString());

  const indexesMap = new Map();

  for (const pair of assetPairIndexes) {
    const key =
      pair.asset.toString().toLowerCase() +
      pair.reward.toString().toLowerCase();

    indexesMap.set(key, pair.indexToSet);
  }

  return indexesMap;
}

async function main() {
  const indexesMap = await makeIndexMap();

  const userAssetRewardFile = fs.readFileSync(
    "tsscripts/final/userAssetReward.json"
  );
  const userAssetReward = JSON.parse(userAssetRewardFile.toString());

  const provider = new ethers.JsonRpcProvider(BASE_RPC_URL);
  const rewardControllerAbi = [
    "function getAssetIndex(address, address) external view returns (uint256, uint256)",
    "function getUserRewards(address[],address,address) external view returns (uint256)",
  ];
  const rewardControllerAddress = "0x91Ac2FfF8CBeF5859eAA6DdA661feBd533cD3780";
  const rewardController = new ethers.Contract(
    rewardControllerAddress,
    rewardControllerAbi,
    provider
  );

  const changes: any = [];

  for (let i = 0; i < userAssetReward.length; i += 10) {
    const subArray = userAssetReward.slice(i, i + 10);

    await Promise.all(
      subArray.map(async (elem: any) => {
        const key =
          elem.asset.toString().toLowerCase() +
          elem.reward.toString().toLowerCase();

        const indexToSet = indexesMap.get(key);

        const currentAccruedRewards = BigInt(
          await rewardController.getUserRewards(
            [elem.asset],
            elem.user,
            elem.reward
          )
        );
        const accruedToDeduct = BigInt(elem.accruedRewards);

        const accruedToSet =
          currentAccruedRewards > accruedToDeduct
            ? currentAccruedRewards - accruedToDeduct
            : BigInt(0);

        changes.push({
          user: elem.user,
          asset: elem.asset,
          reward: elem.reward,
          indexToSet: indexToSet,
          accruedToSet: accruedToSet.toString(),
          currentAccrued: currentAccruedRewards.toString(),
          accruedToDeduct: accruedToDeduct.toString(),
        });
      })
    );
  }

  fs.writeFileSync(
    "tsscripts/final/changes.json",
    JSON.stringify(changes, null, 2)
  );
}

main().catch((err) => {
  console.error(err);
});
