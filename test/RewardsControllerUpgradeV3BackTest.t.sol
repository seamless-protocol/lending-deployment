// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
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

// Test upgrade/migration of RewardsController
contract RewardsControllerUpgradeV3BackTest is Test {
    uint256 constant FORK_BLOCK_NUMBER = 14894031; // 2024-05-24 Base - https://basescan.org/tx/0xa67f12e83c64f39720f835e24ca9a28da93c8c05dd57e7b2f69e6bc733044570

    bytes32 constant REWARDS_PROXY_ADDRESS_ID = keccak256("INCENTIVES_CONTROLLER");

    address constant controllerImplementationV2 = 0x8243De25c4B8a2fF57F38f89f7C989F7d0fc2850;

    address constant user = 0x99e5d4a7Fb7BA7281D1F4fc5DCE311F1d832796C;

    address constant USDC = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;
    address constant OG_POINTS = 0x5607718c64334eb5174CB2226af891a6ED82c7C6;
    address constant SEAM = 0x1C7a460413dD4e964f96D8dFC56E7223cE88CD85;

    address usdcAToken;

    RewardsController rewardsProxy;

    function setUp() public {
        vm.createSelectFork(vm.envString("FORK_URL"), FORK_BLOCK_NUMBER - 1);

        IPool pool = IPool(Constants.POOL_ADDRESSES_PROVIDER.getPool());
        DataTypes.ReserveData memory usdcReserve = pool.getReserveData(USDC);

        usdcAToken = usdcReserve.aTokenAddress;

        rewardsProxy = RewardsController(Constants.POOL_ADDRESSES_PROVIDER.getAddress(REWARDS_PROXY_ADDRESS_ID));

        // etch must be in the setup method. https://github.com/foundry-rs/foundry/issues/8006
        address controllerImplementationV3 = address(new RewardsController(Constants.EMISSION_MANAGER));
        vm.etch(controllerImplementationV2, controllerImplementationV3.code);
    }

    function test_BackTestV3() public {
        vm.makePersistent(address(controllerImplementationV2));

        uint256 userIndex = rewardsProxy.getUserAssetIndex(user, usdcAToken, USDC);
        assertNotEq(userIndex, 0);

        uint256 userAccrued = rewardsProxy.getUserAccruedRewards(user, USDC);
        assertEq(userAccrued, 0);

        bytes32 afterTimelockTx = 0x4e5f725376c58b9f710dd2ece16ca10175d8f52d535996455ebce7e7a2d77c51; // tx right after timelock execution

        vm.rollFork(afterTimelockTx);

        assertEq(rewardsProxy.REVISION(), 3);

        // bytes32 badClaimTx = 0x50d408481b6383d56afe01ed1a67c05b94fd9d69231c4720e152e7493a2855bd; // bad state transaction claim
        bytes32 afterBadClaimTx = 0x1e2c8687937673c88f382f7b645e9ff4e424464ed81607ab7a4e72b83e692228; // immdediately after 0x50d408481b6383d56afe01ed1a67c05b94fd9d69231c4720e152e7493a2855bd
        // bytes32 badAccrueTx = 0x97d21eb3cb3935035ecb8672c5f73f69cfd612bd6f6507d6e211db25573bfb64; // bad state accrued tranaction
        bytes32 afterBadAccrueTx = 0xda9c51dcb272d3af3f3704ed1c7a655f9d692fa262171e4aed70e1cc5b64220e; // immediately after bad accrue tx

        vm.rollFork(afterBadClaimTx);

        assertEq(rewardsProxy.REVISION(), 3);

        userIndex = rewardsProxy.getUserAssetIndex(user, usdcAToken, USDC);
        assertNotEq(userIndex, 0);

        userAccrued = rewardsProxy.getUserAccruedRewards(user, USDC);
        assertEq(userAccrued, 0);

        vm.rollFork(afterBadAccrueTx);
        assertEq(rewardsProxy.REVISION(), 3);

        userIndex = rewardsProxy.getUserAssetIndex(user, usdcAToken, USDC);
        assertNotEq(userIndex, 0);

        userAccrued = rewardsProxy.getUserAccruedRewards(user, USDC);
        assertNotEq(userAccrued, 0);
    }
}
