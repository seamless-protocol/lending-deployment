// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {Test, console} from "forge-std/Test.sol";
import "forge-std/StdJson.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {InitializableImmutableAdminUpgradeabilityProxy} from
    "seamless/aave-v3-core/protocol/libraries/aave-upgradeability/InitializableImmutableAdminUpgradeabilityProxy.sol";
import {IPool} from "seamless/aave-v3-core/interfaces/IPool.sol";
import {IPoolConfigurator} from "seamless/aave-v3-core/interfaces/IPoolConfigurator.sol";
import {DataTypes} from "seamless/aave-v3-core/protocol/libraries/types/DataTypes.sol";
import {IScaledBalanceToken} from "seamless/aave-v3-core/interfaces/IScaledBalanceToken.sol";
import {RewardsController} from "seamless/aave-v3-periphery/rewards/RewardsController.sol";
import {IUiIncentiveDataProviderV3} from "seamless/aave-v3-periphery/misc/interfaces/IUiIncentiveDataProviderV3.sol";
import {ITransferStrategyBase} from "seamless/aave-v3-periphery/rewards/interfaces/ITransferStrategyBase.sol";
import {IPoolAddressesProvider} from "seamless/aave-v3-periphery/misc/interfaces/IUiIncentiveDataProviderV3.sol";
import {Constants} from "../script/Constants.sol";

contract ReplayRewardState is Test {
    using stdJson for string;

    uint256 constant FORK_BLOCK_NUMBER = 14894031; // 2024-05-24 Base - https://basescan.org/tx/0xa67f12e83c64f39720f835e24ca9a28da93c8c05dd57e7b2f69e6bc733044570
    bytes32 constant REWARDS_PROXY_ADDRESS_ID = keccak256("INCENTIVES_CONTROLLER");
    address constant controllerImplementationV2 = 0x8243De25c4B8a2fF57F38f89f7C989F7d0fc2850;

    address constant user = 0x99e5d4a7Fb7BA7281D1F4fc5DCE311F1d832796C;

    address constant USDC = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;

    address usdcAToken;

    RewardsController rewardsProxy;

    function setUp() public {
        vm.createSelectFork(vm.envString("FORK_URL"), FORK_BLOCK_NUMBER - 1);

        IPool pool = IPool(Constants.POOL_ADDRESSES_PROVIDER.getPool());
        DataTypes.ReserveData memory usdcReserve = pool.getReserveData(USDC);

        usdcAToken = usdcReserve.aTokenAddress;

        rewardsProxy = RewardsController(Constants.POOL_ADDRESSES_PROVIDER.getAddress(REWARDS_PROXY_ADDRESS_ID));

        address controllerImplementationV3 = address(new RewardsController(Constants.EMISSION_MANAGER));
        vm.etch(controllerImplementationV2, controllerImplementationV3.code);
    }

    function test_run() public {
        vm.makePersistent(address(controllerImplementationV2));

        bytes32 afterBadClaimTx = 0x1e2c8687937673c88f382f7b645e9ff4e424464ed81607ab7a4e72b83e692228;
        vm.rollFork(afterBadClaimTx);

        assertEq(rewardsProxy.REVISION(), 3);

        uint256 userIndex = rewardsProxy.getUserAssetIndex(user, usdcAToken, USDC);
        assertNotEq(userIndex, 0);

        // {
        //     "values": [
        //         {
        //             "asset": "string",
        //             "reward": "string",
        //             "user": "string",
        //         }
        //     ]
        // }
        string memory json = vm.readFile("./replay-reward-state-input.json");

        uint256 count;
        while(true) {
            address asset ;

            if (asset != address(0)) {
                break;
            }

            address reward;
            address user;
            
            
            count++;
        }
    }
}