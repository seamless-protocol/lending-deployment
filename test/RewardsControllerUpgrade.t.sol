// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
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
        }

        rewardsList = rewardsProxy.getRewardsList();
    }

    function test_Upgrade() public {
        assertEq(rewardsProxy.REVISION(), 1);

        _upgrade();

        assertEq(rewardsProxy.REVISION(), 2);
    }

    

    function _upgrade() internal {
        address controllerImplementation = address(new RewardsController(Constants.EMISSION_MANAGER));

        vm.prank(Constants.TIMELOCK_SHORT);
        Constants.POOL_ADDRESSES_PROVIDER.setAddressAsProxy(REWARDS_PROXY_ADDRESS_ID, controllerImplementation);
    }
}
