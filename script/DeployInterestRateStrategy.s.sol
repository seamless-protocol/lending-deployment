// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {Script, console} from "forge-std/Script.sol";
import {CapsPlusRiskSteward, IPoolDataProvider} from "seamless/aave-helpers/riskstewards/CapsPlusRiskSteward.sol";
import {WadRayMath} from "seamless/aave-v3-core/protocol/libraries/math/WadRayMath.sol";
import {DefaultReserveInterestRateStrategy} from
    "seamless/aave-v3-core/protocol/pool/DefaultReserveInterestRateStrategy.sol";
import {Constants} from "./Constants.sol";

contract DeployInterestRateStrategy is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);

        console.log("Deployer address: ", deployerAddress);
        console.log("Deployer balance: ", deployerAddress.balance);
        console.log("BlockNumber: ", block.number);
        console.log("ChainId: ", block.chainid);

        vm.startBroadcast(deployerPrivateKey);

        uint256 optimalUsageRatio = _bpsToRay(45_00);
        uint256 variableSlope1 = _bpsToRay(9_00);
        uint256 variableSlope2 = _bpsToRay(300_00);

        DefaultReserveInterestRateStrategy interestStrategy = new DefaultReserveInterestRateStrategy(
            Constants.POOL_ADDRESSES_PROVIDER, optimalUsageRatio, 0, variableSlope1, variableSlope2, 0, 0, 0, 0, 0
        );

        vm.stopBroadcast();

        console.log("DefaultReserveInterestRateStrategy deployed: ", address(interestStrategy));
    }

    function _bpsToRay(uint256 amount) internal pure returns (uint256) {
        return (amount * WadRayMath.RAY) / 10_000;
    }
}
