// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {Script, console} from "forge-std/Script.sol";
import {Pool} from "aave-v3-core/contracts/protocol/pool/Pool.sol";
import {Constants} from "./Constants.sol";

contract DeployPoolImplementation is Script {

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);

        console.log("Deployer address: ", deployerAddress);
        console.log("Deployer balance: ", deployerAddress.balance);
        console.log("BlockNumber: ", block.number);
        console.log("ChainId: ", block.chainid);

        vm.startBroadcast(deployerPrivateKey);

        Pool poolImplementation = new Pool(Constants.POOL_ADDRESSES_PROVIDER);
        poolImplementation.initialize(Constants.POOL_ADDRESSES_PROVIDER);

        vm.stopBroadcast();
    }
}
