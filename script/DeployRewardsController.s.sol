// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {Script, console} from "forge-std/Script.sol";
import {RewardsController} from "seamless/aave-v3-periphery/rewards/RewardsController.sol";
import {Constants} from "./Constants.sol";

contract DeployPoolImplementation is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);

        console.log("Deployer address: ", deployerAddress);
        console.log("Deployer balance: ", deployerAddress.balance);
        console.log("BlockNumber: ", block.number);
        console.log("ChainId: ", block.chainid);

        vm.startBroadcast(deployerPrivateKey);

        RewardsController rewardsControllerImplementation = new RewardsController(Constants.EMISSION_MANAGER);
        rewardsControllerImplementation.initialize(Constants.EMISSION_MANAGER);

        console.log("RewardsController implementation deployed: ", address(rewardsControllerImplementation));

        vm.stopBroadcast();
    }
}
