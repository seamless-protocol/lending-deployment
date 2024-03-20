// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {Script, console} from "forge-std/Script.sol";
import {PriceOracleSentinel} from "seamless/aave-v3-core/protocol/configuration/PriceOracleSentinel.sol";
import {Constants} from "./Constants.sol";

contract DeployPriceOracleSentinel is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);

        console.log("Deployer address: ", deployerAddress);
        console.log("Deployer balance: ", deployerAddress.balance);
        console.log("BlockNumber: ", block.number);
        console.log("ChainId: ", block.chainid);

        vm.startBroadcast(deployerPrivateKey);

        PriceOracleSentinel priceOracleSentinel = new PriceOracleSentinel(
            Constants.POOL_ADDRESSES_PROVIDER, Constants.SEQUENCER_ORACLE, Constants.SEQUENCER_ORACLE_GRACE_PERIOD
        );

        console.log("PriceOracleSentinel deployed: ", address(priceOracleSentinel));

        vm.stopBroadcast();
    }
}
