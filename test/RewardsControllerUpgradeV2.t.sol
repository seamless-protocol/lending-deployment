// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {IPool} from "seamless/aave-v3-core/interfaces/IPool.sol";
import {IPoolConfigurator} from "seamless/aave-v3-core/interfaces/IPoolConfigurator.sol";
import {DataTypes} from "seamless/aave-v3-core/protocol/libraries/types/DataTypes.sol";
import {IScaledBalanceToken} from "seamless/aave-v3-core/interfaces/IScaledBalanceToken.sol";
import {RewardsController} from "seamless/aave-v3-periphery/rewards/RewardsController.sol";
import {IUiIncentiveDataProviderV3} from "seamless/aave-v3-periphery/misc/interfaces/IUiIncentiveDataProviderV3.sol";
import {IPoolAddressesProvider} from "seamless/aave-v3-periphery/misc/interfaces/IUiIncentiveDataProviderV3.sol";
import {Constants} from "../script/Constants.sol";

// Test upgrade/migration of RewardsController
contract RewardsControllerTest is Test {
    uint256 constant FORK_BLOCK_NUMBER = 14894031; // 2024-05-24 Base

    bytes32 constant REWARDS_PROXY_ADDRESS_ID = keccak256("INCENTIVES_CONTROLLER");

    address constant USDC = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;
    address constant DAI = 0x50c5725949A6F0c72E6C4a641F24049A917DB0Cb;
    address constant SEAM = 0x1C7a460413dD4e964f96D8dFC56E7223cE88CD85;

    address public immutable user = makeAddr("user");

    RewardsController rewardsProxy;
    address[] assetsList;

    function setUp() public {
        vm.createSelectFork(vm.envString("FORK_URL"), FORK_BLOCK_NUMBER);

        rewardsProxy = RewardsController(Constants.POOL_ADDRESSES_PROVIDER.getAddress(REWARDS_PROXY_ADDRESS_ID));

        // remove supply cap
        IPoolConfigurator poolConfigurator = IPoolConfigurator(Constants.POOL_ADDRESSES_PROVIDER.getPoolConfigurator());
        vm.prank(Constants.TIMELOCK_SHORT);
        poolConfigurator.setSupplyCap(USDC, 0);
    }

    function test_Upgrade() public {
        assertEq(rewardsProxy.REVISION(), 2);

        _upgrade();

        assertEq(rewardsProxy.REVISION(), 3);
    }

    function test_RewardEnded() public {
        uint256 amount = 1000 ether;

        deal(DAI, user, amount + 1);

        IPool pool = IPool(Constants.POOL_ADDRESSES_PROVIDER.getPool());

        vm.startPrank(user);
        IERC20(DAI).approve(address(pool), amount + 1);

        pool.supply(DAI, amount, user, 0);
        vm.stopPrank();

        DataTypes.ReserveData memory daiReserve = pool.getReserveData(DAI);

        vm.warp(vm.getBlockTimestamp() + 1 days);

        uint256 userIndex = rewardsProxy.getUserAssetIndex(user, daiReserve.aTokenAddress, SEAM);
        assertNotEq(userIndex, 0);

        uint256 snapshot = vm.snapshot();

        vm.prank(user);
        pool.supply(DAI, 1, user, 0);

        userIndex = rewardsProxy.getUserAssetIndex(user, daiReserve.aTokenAddress, SEAM);
        assertEq(userIndex, 0);

        vm.revertTo(snapshot);  

        _upgrade();

        vm.prank(user);
        pool.supply(DAI, 1, user, 0);

        userIndex = rewardsProxy.getUserAssetIndex(user, daiReserve.aTokenAddress, SEAM);
        assertNotEq(userIndex, 0);
    }

    function _upgrade() internal {
        address controllerImplementation = address(new RewardsController(Constants.EMISSION_MANAGER));

        vm.prank(Constants.TIMELOCK_SHORT);
        Constants.POOL_ADDRESSES_PROVIDER.setAddressAsProxy(REWARDS_PROXY_ADDRESS_ID, controllerImplementation);
    }
}
