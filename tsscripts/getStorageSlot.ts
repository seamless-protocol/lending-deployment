import { BytesLike, ethers } from "ethers";

const { keccak256, AbiCoder, concat, dataSlice } = ethers;

const abiCoder = AbiCoder.defaultAbiCoder();

const getAccruedStorageSlot = (asset: string, user: string, reward: string) => {
  const assetSlot = keccak256(concat([abiCoder.encode(["address"], [asset]), abiCoder.encode(["uint256"], [2])]));

  const rewardSlot = keccak256(concat([abiCoder.encode(["address"], [reward]), assetSlot + 0]));

  const userSlot = keccak256(concat([abiCoder.encode(["address"], [user]), rewardSlot + 1]));

  return userSlot;
};

const unpackSlot = (value: BytesLike) => {
    const sliced = dataSlice(value, 104);
    return abiCoder.decode(["uint128"], sliced);
};

const asset = "0x53e240c0f985175da046a62f26d490d1e259036e";
const user = "0x002841301d1ab971d8acb3509aa2891e3ef9d7e1";
const reward = "0x833589fcd6edb6e08f4c7c32d4f71b54bda02913";

console.log(`asset: ${asset}, user: ${user}, reward: ${reward}`);

const slot = getAccruedStorageSlot(asset, user, reward);

console.log(`slot: ${slot}`);

//const value = unpackSlot();

// console.log(`slot: ${slot}, value: ${value}`);
