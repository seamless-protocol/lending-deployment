// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test,console} from "forge-std/Test.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {RewardsController} from "seamless/aave-v3-periphery/rewards/RewardsController.sol";
import {IUiIncentiveDataProviderV3} from "seamless/aave-v3-periphery/misc/interfaces/IUiIncentiveDataProviderV3.sol";
import {IPoolAddressesProvider} from "seamless/aave-v3-periphery/misc/interfaces/IUiIncentiveDataProviderV3.sol";
import {Constants} from "../script/Constants.sol";

contract RewardsControllerTest is Test {
    uint256 constant FORK_BLOCK_NUMBER = 14261704; // 2024-05-09 Base

    bytes32 constant REWARDS_PROXY_ADDRESS_ID = keccak256("INCENTIVES_CONTROLLER");

    RewardsController rewardsProxy;
    address[] assetsList;
    address[] rewardsList;

    function setUp() public {
        vm.createSelectFork(vm.envString("BASE_RPC"), 14261704);

        rewardsProxy = RewardsController(Constants.POOL_ADDRESSES_PROVIDER.getAddress(REWARDS_PROXY_ADDRESS_ID));

        IUiIncentiveDataProviderV3.AggregatedReserveIncentiveData[] memory incentiveData = Constants
            .UI_INCENTIVE_PROVIDER_V3
            .getReservesIncentivesData(IPoolAddressesProvider(address(Constants.POOL_ADDRESSES_PROVIDER)));

        for (uint256 i = 0; i < incentiveData.length; i++) {
            assetsList.push(incentiveData[i].aIncentiveData.tokenAddress);
            assetsList.push(incentiveData[i].vIncentiveData.tokenAddress);
        }

        rewardsList = rewardsProxy.getRewardsList();
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

                if (lastUpdateTimestamp >= distributionEnd) {
                    // check that non-active reward programs are unchanged
                    assertEq(index, prevOldIndexes[i][j]);
                } else {
                    // check that active reward programs have new indexes are scaled up to 1e27
                    uint256 scaleDiff = (10 ** (27 - IERC20(asset).decimals()));
                    assertEq((index - prevOldIndexes[i][j]) / scaleDiff * scaleDiff, (prevNewIndexes[i][j] - prevOldIndexes[i][j]) * scaleDiff);
                }
            }
        }
    }

    function test_UserIndex(uint256 amount) public {
        // User deposit 1 USDC

        _upgrade();

        // User should have x USDC rewards to claim
    }

    function _upgrade() internal {
        address controllerImplementation = address(new RewardsController(Constants.EMISSION_MANAGER));

        vm.prank(Constants.TIMELOCK_SHORT);
        Constants.POOL_ADDRESSES_PROVIDER.setAddressAsProxy(REWARDS_PROXY_ADDRESS_ID, controllerImplementation);
    }
}
