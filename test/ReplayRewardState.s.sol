// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {Test, console} from "forge-std/Test.sol";
import "forge-std/StdJson.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
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

    address constant USDC = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;
    address constant SEAM = 0x1C7a460413dD4e964f96D8dFC56E7223cE88CD85;
    address constant usdcAToken = 0x53E240C0F985175dA046A62F26D490d1E259036e;
    address constant user = 0x99e5d4a7Fb7BA7281D1F4fc5DCE311F1d832796C;

    string constant outputFileName = "./test/output.csv";
    string constant transfersInputFile = "./test/transfers.json";

    RewardsController rewardsProxy;
    address[] assetsList;

    function setUp() public {
        vm.createSelectFork(vm.envString("FORK_URL"), FORK_BLOCK_NUMBER - 1);

        IUiIncentiveDataProviderV3.AggregatedReserveIncentiveData[] memory incentiveData = Constants
            .UI_INCENTIVE_PROVIDER_V3
            .getReservesIncentivesData(IPoolAddressesProvider(address(Constants.POOL_ADDRESSES_PROVIDER)));

        for (uint256 i = 0; i < incentiveData.length; i++) {
            assetsList.push(incentiveData[i].aIncentiveData.tokenAddress);
            assetsList.push(incentiveData[i].vIncentiveData.tokenAddress);
        }

        rewardsProxy = RewardsController(Constants.POOL_ADDRESSES_PROVIDER.getAddress(REWARDS_PROXY_ADDRESS_ID));

        // etch must be in the test setup method. https://github.com/foundry-rs/foundry/issues/8006
        address controllerImplementationV3 = address(new RewardsController(Constants.EMISSION_MANAGER));
        vm.etch(controllerImplementationV2, controllerImplementationV3.code);
    }

    function test_run() public {
        // bytes32 afterTimerecentTxlockTx = 0x4e5f725376c58b9f710dd2ece16ca10175d8f52d535996455ebce7e7a2d77c51;
        // bytes32 afterBadClaimTx = 0x1e2c8687937673c88f382f7b645e9ff4e424464ed81607ab7a4e72b83e692228;
        // bytes32 afterBadAccrueTx = 0xda9c51dcb272d3af3f3704ed1c7a655f9d692fa262171e4aed70e1cc5b64220e;
        bytes32 recentTx = 0xf547f5e520552750c24c74e084bfb7163e37875c1c260db0224f26b879716911;
        vm.makePersistent(address(controllerImplementationV2));
        // vm.makePersistent(address(rewardsProxy));

        vm.rollFork(recentTx);

        console.log("Fork rolled forward");

        assertEq(rewardsProxy.REVISION(), 3);

        (uint256 userAccrued, uint256 userIndex) = rewardsProxy.getUserAssetData(user, usdcAToken, USDC);
        assertEq(userAccrued, 0);
        assertEq(userIndex, 7554000000000000000000000);
        return;

        if (vm.exists(outputFileName)) {
            vm.removeFile(outputFileName);
        }

        _writeUsersData();
        _writeTransfersData();
    }

    function _writeUsersData() internal {
        // {
        //     "rows": [{ "user": "0x13a13869b814be8f13b86e9875ab51bda882e391"}]
        // }
        // https://dune.com/queries/3776138/6349617
        string memory rawJson = vm.readFile("./test/users.json");

        bytes memory userBytes = rawJson.parseRaw("$..user");
        address[] memory users = abi.decode(userBytes, (address[]));

        console.log("Start fetching and writing user state.");

        vm.writeLine(outputFileName, "asset,reward,user,userAccrued,userIndex");

        for (uint256 i = 0; i < assetsList.length; i++) {
            address[] memory rewards = rewardsProxy.getRewardsByAsset(assetsList[i]);

            for (uint256 j = 0; j < rewards.length; j++) {
                for (uint256 k = 0; k < users.length; k++) {
                    (uint256 userAccrued, uint256 userIndex) =
                        rewardsProxy.getUserAssetData(users[k], assetsList[i], rewards[j]);
                    // console.log("asset %s, reward %s, user %s", assetsList[i], rewards[j], users[k]);
                    // console.log("userAccrued %s, userIndex %s", userAccrued, userIndex);
                    vm.writeLine(
                        outputFileName,
                        string.concat(
                            Strings.toHexString(assetsList[i]),
                            ",",
                            Strings.toHexString(rewards[j]),
                            ",",
                            Strings.toHexString(users[k]),
                            ",",
                            Strings.toString(userAccrued),
                            ",",
                            Strings.toString(userIndex)
                        )
                    );
                }
            }
        }
    }

    function _writeTransfersData() internal {
        // {
        //     "rows": {
        //             "contract_address": "0x13a13869b814be8f13b86e9875ab51bda882e391",
        //             "to": "0x93ae00e201c0d8b361ebb075d42f306342a04fc5"
        //         }
        // }
        // https://dune.com/queries/3776169/6349652
        string memory rawJson = vm.readFile(transfersInputFile);

        bytes memory userBytes = rawJson.parseRaw("$..user");
        bytes memory assetsBytes = rawJson.parseRaw("$..contract_address");
        address[] memory users = abi.decode(userBytes, (address[]));
        address[] memory assets = abi.decode(assetsBytes, (address[]));

        assertEq(users.length, assets.length);

        console.log("Start fetching user state.");

        vm.writeLine(outputFileName, "asset,reward,user,userAccrued,userIndex");

        for (uint256 i = 0; i < assets.length; i++) {
            address[] memory rewards = rewardsProxy.getRewardsByAsset(assets[i]);

            for (uint256 j = 0; j < rewards.length; j++) {
                (uint256 userAccrued, uint256 userIndex) =
                    rewardsProxy.getUserAssetData(users[i], assets[i], rewards[j]);
                // console.log("asset %s, reward %s, user %s", assets[i], rewards[j], users[k]);
                // console.log("userAccrued %s, userIndex %s", userAccrued, userIndex);
                vm.writeLine(
                    outputFileName,
                    string.concat(
                        Strings.toHexString(assets[i]),
                        ",",
                        Strings.toHexString(rewards[j]),
                        ",",
                        Strings.toHexString(users[i]),
                        ",",
                        Strings.toString(userAccrued),
                        ",",
                        Strings.toString(userIndex)
                    )
                );
            }
        }
    }
}
