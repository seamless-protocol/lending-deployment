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

contract RewardsControllerTest is Test {
    uint256 constant FORK_BLOCK_NUMBER = 14261704; // 2024-05-09 Base

    bytes32 constant REWARDS_PROXY_ADDRESS_ID = keccak256("INCENTIVES_CONTROLLER");

    address constant USDC = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;

    address public immutable user = makeAddr("user");

    RewardsController rewardsProxy;
    address[] assetsList;
    address[] rewardsList;

    function setUp() public {
        vm.createSelectFork(vm.envString("FORK_URL"), 14261704);

        rewardsProxy = RewardsController(Constants.POOL_ADDRESSES_PROVIDER.getAddress(REWARDS_PROXY_ADDRESS_ID));

        IUiIncentiveDataProviderV3.AggregatedReserveIncentiveData[] memory incentiveData = Constants
            .UI_INCENTIVE_PROVIDER_V3
            .getReservesIncentivesData(IPoolAddressesProvider(address(Constants.POOL_ADDRESSES_PROVIDER)));

        for (uint256 i = 0; i < incentiveData.length; i++) {
            assetsList.push(incentiveData[i].aIncentiveData.tokenAddress);
            assetsList.push(incentiveData[i].vIncentiveData.tokenAddress);
        }

        rewardsList = rewardsProxy.getRewardsList();

        // remove supply cap
        IPoolConfigurator poolConfigurator = IPoolConfigurator(Constants.POOL_ADDRESSES_PROVIDER.getPoolConfigurator());
        vm.prank(Constants.TIMELOCK_SHORT);
        poolConfigurator.setSupplyCap(USDC, 0);
    }

    function test_Upgrade() public {
        assertEq(rewardsProxy.REVISION(), 1);

        _upgrade();

        assertEq(rewardsProxy.REVISION(), 2);
    }

    function test_MigrateV1ToV2() public {
        uint256[8][20] memory prevNewIndexes;
        uint256[8][20] memory prevOldIndexes;

        // save all reward indexes before upgrade
        for (uint256 i = 0; i < assetsList.length; i++) {
            address asset = assetsList[i];
            address[] memory rewards = rewardsProxy.getRewardsByAsset(asset);

            for (uint256 j = 0; j < rewards.length; j++) {
                (prevOldIndexes[i][j], prevNewIndexes[i][j]) = rewardsProxy.getAssetIndex(asset, rewards[j]);
            }
        }

        _upgrade();

        // check all incentive indexes after upgrade
        for (uint256 i = 0; i < assetsList.length; i++) {
            address asset = assetsList[i];
            address[] memory rewards = rewardsProxy.getRewardsByAsset(asset);

            for (uint256 j = 0; j < rewards.length; j++) {
                (uint256 index,, uint256 lastUpdateTimestamp, uint256 distributionEnd) =
                    rewardsProxy.getRewardsData(asset, rewards[j]);

                assertEq(lastUpdateTimestamp, block.timestamp);
                assertNotEq(index, 0);

                uint256 scaleDiff = (10 ** (27 - IERC20(asset).decimals()));

                if (lastUpdateTimestamp >= distributionEnd) {
                    // check that non-active reward programs
                    assertEq(index, prevOldIndexes[i][j] * scaleDiff);
                } else {
                    // check that active reward programs
                    assertEq(
                        (index - (prevOldIndexes[i][j] * scaleDiff)) / scaleDiff * scaleDiff,
                        (prevNewIndexes[i][j] - prevOldIndexes[i][j]) * scaleDiff
                    );
                }
            }
        }
    }

    function test_FuzzUserIndex(uint256 amount) public {
        amount = bound(amount, 1, type(uint128).max);

        deal(USDC, user, amount);

        IPool pool = IPool(Constants.POOL_ADDRESSES_PROVIDER.getPool());

        vm.startPrank(user);
        IERC20(USDC).approve(address(pool), amount);

        // Split up deposits to force multiple handleAction calls
        if (amount > 1) {
            pool.supply(USDC, amount / 2, user, 0);
            pool.supply(USDC, amount / 2, user, 0);
        }
        if (amount % 2 != 0) {
            pool.supply(USDC, 1, user, 0);
        }
        vm.stopPrank();

        DataTypes.ReserveData memory usdcReserve = pool.getReserveData(USDC);
        address usdcAToken = usdcReserve.aTokenAddress;

        (, uint256 assetIndexBefore) = rewardsProxy.getAssetIndex(usdcAToken, USDC);
        vm.warp(vm.getBlockTimestamp() + 1); // Small time delta to force index round down 0 case
        (, uint256 assetIndexAfter) = rewardsProxy.getAssetIndex(usdcAToken, USDC);

        assertEq(assetIndexAfter, assetIndexBefore);

        address[] memory usdcAddressArray = new address[](1);
        usdcAddressArray[0] = usdcAToken;
        uint256 userRewards = rewardsProxy.getUserRewards(usdcAddressArray, user, USDC);
        assertEq(userRewards, 0);

        _upgrade();

        (, assetIndexAfter) = rewardsProxy.getAssetIndex(usdcAToken, USDC);

        // check index is updated
        assertNotEq(assetIndexAfter, assetIndexBefore);

        userRewards = rewardsProxy.getUserRewards(usdcAddressArray, user, USDC);

        (, uint256 emissionPerSecond,,) = rewardsProxy.getRewardsData(usdcAToken, USDC);

        (uint256 userBalance, uint256 totalSupply) = IScaledBalanceToken(usdcAToken).getScaledUserBalanceAndSupply(user);

        uint256 scaledAssetIndexBefore = assetIndexBefore * 1e27 / 1e6;
        uint256 expectedUserRewards = (
            ((emissionPerSecond * 1e27 / totalSupply) + scaledAssetIndexBefore) - scaledAssetIndexBefore
        ) * userBalance / 1e27;

        assertEq(userRewards, expectedUserRewards);

        vm.prank(user);
        assertEq(rewardsProxy.claimRewards(usdcAddressArray, type(uint256).max, user, USDC), userRewards);
    }

    function test_FuzzUserIndexDuration(uint256 amount, uint32 duration) public {
        amount = bound(amount, 1, type(uint128).max);
        duration = uint32(bound(duration, 1, 60 * 60 * 24 * 10)); // 10 day max

        deal(USDC, user, amount);

        IPool pool = IPool(Constants.POOL_ADDRESSES_PROVIDER.getPool());

        vm.startPrank(user);
        IERC20(USDC).approve(address(pool), amount);

        // Split up deposits to force multiple handleAction calls
        if (amount > 1) {
            pool.supply(USDC, amount / 2, user, 0);
            pool.supply(USDC, amount / 2, user, 0);
        }
        if (amount % 2 != 0) {
            pool.supply(USDC, 1, user, 0);
        }
        vm.stopPrank();

        DataTypes.ReserveData memory usdcReserve = pool.getReserveData(USDC);
        address usdcAToken = usdcReserve.aTokenAddress;

        uint256 userIndexBefore = rewardsProxy.getUserAssetIndex(user, usdcAToken, USDC);

        vm.warp(vm.getBlockTimestamp() + (duration / 2));

        address[] memory usdcAddressArray = new address[](1);
        usdcAddressArray[0] = usdcAToken;
        uint256 userRewardsBefore = rewardsProxy.getUserAccruedRewards(user, USDC);

        _upgrade();

        (, uint256 assetIndexAfter) = rewardsProxy.getAssetIndex(usdcAToken, USDC);

        vm.warp(vm.getBlockTimestamp() + (duration / 2));

        uint256 userRewards = rewardsProxy.getUserRewards(usdcAddressArray, user, USDC);

        (, uint256 emissionPerSecond,,) = rewardsProxy.getRewardsData(usdcAToken, USDC);

        (uint256 userBalance, uint256 totalSupply) = IScaledBalanceToken(usdcAToken).getScaledUserBalanceAndSupply(user);

        uint256 expectedUserRewards = emissionPerSecond * 1e27 * (duration / 2);
        // separated to prevent stack too deep
        expectedUserRewards = (expectedUserRewards / totalSupply);
        expectedUserRewards = expectedUserRewards + assetIndexAfter;
        expectedUserRewards = (expectedUserRewards - (userIndexBefore * 1e27 / 1e6)) * userBalance / 1e27;

        assertEq(userRewards, expectedUserRewards + userRewardsBefore);

        vm.prank(user);
        assertEq(rewardsProxy.claimRewards(usdcAddressArray, type(uint256).max, user, USDC), userRewards);
    }

    function _upgrade() internal {
        address controllerImplementation = address(new RewardsController(Constants.EMISSION_MANAGER));

        vm.prank(Constants.TIMELOCK_SHORT);
        Constants.POOL_ADDRESSES_PROVIDER.setAddressAsProxy(REWARDS_PROXY_ADDRESS_ID, controllerImplementation);
    }
}
