// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {Script, console} from "forge-std/Script.sol";
import {CapsPlusRiskSteward, IPoolDataProvider} from "seamless/aave-helpers/riskstewards/CapsPlusRiskSteward.sol";
import {Constants} from "./Constants.sol";

contract DeployRiskSteward is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);

        console.log("Deployer address: ", deployerAddress);
        console.log("Deployer balance: ", deployerAddress.balance);
        console.log("BlockNumber: ", block.number);
        console.log("ChainId: ", block.chainid);

        vm.startBroadcast(deployerPrivateKey);

        CapsPlusRiskSteward riskSteward = new CapsPlusRiskSteward(
            IPoolDataProvider(address(Constants.POOL_ADDRESSES_PROVIDER.getPoolDataProvider())),
            Constants.CONFIG_ENGINE,
            Constants.GUARDIAN
        );

        vm.stopBroadcast();

        console.log("CapsPlusRiskSteward deployed: ", address(riskSteward));
    }
}
