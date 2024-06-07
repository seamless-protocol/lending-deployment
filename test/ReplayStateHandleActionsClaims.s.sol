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
import {RewardsControllerAdminFunctions} from "./contracts/RewardsControllerAdminFunctions.sol";

contract ReplayStateHandleActionsClaims is Test {
    using stdJson for string;

    uint256 constant FORK_BLOCK_NUMBER = 14894031; // 2024-05-24 Base - https://basescan.org/tx/0xa67f12e83c64f39720f835e24ca9a28da93c8c05dd57e7b2f69e6bc733044570
    bytes32 constant REWARDS_PROXY_ADDRESS_ID = keccak256("INCENTIVES_CONTROLLER");
    address constant controllerImplementationV2 = 0x8243De25c4B8a2fF57F38f89f7C989F7d0fc2850;

    uint256 constant END_BLOCK_NUMBER = 15442183;

    RewardsControllerAdminFunctions rewardsProxy;

    address[] buggedAssets = [
      0x13A13869B814Be8F13B86e9875aB51bda882E391,
      0x13A13869B814Be8F13B86e9875aB51bda882E391,
      0x2733e1DA7d35c5ea3ed246ed6b613DC3dA97Ce2E,
      0x2733e1DA7d35c5ea3ed246ed6b613DC3dA97Ce2E,
      0x2733e1DA7d35c5ea3ed246ed6b613DC3dA97Ce2E,
      0x27Ce7E89312708FB54121ce7E44b13FBBB4C7661,
      0x27Ce7E89312708FB54121ce7E44b13FBBB4C7661,
      0x27Ce7E89312708FB54121ce7E44b13FBBB4C7661,
      0x2c159A183d9056E29649Ce7E56E59cA833D32624,
      0x2c159A183d9056E29649Ce7E56E59cA833D32624,
      0x326441fA5016d946e6E82e807875fDfdc3041B3B,
      0x326441fA5016d946e6E82e807875fDfdc3041B3B,
      0x326441fA5016d946e6E82e807875fDfdc3041B3B,
      0x37eF72fAC21904EDd7e69f7c7AC98172849efF8e,
      0x37eF72fAC21904EDd7e69f7c7AC98172849efF8e,
      0x48bf8fCd44e2977c8a9A744658431A8e6C0d866c,
      0x4cebC6688faa595537444068996ad9A207A19f13,
      0x4cebC6688faa595537444068996ad9A207A19f13,
      0x4cebC6688faa595537444068996ad9A207A19f13,
      0x51fB9021d61c464674b419C0e3082B5b9223Fc17,
      0x53E240C0F985175dA046A62F26D490d1E259036e,
      0x53E240C0F985175dA046A62F26D490d1E259036e,
      0x67368dF7734aee0bc65A845AC6d73974626b7A34,
      0x72Dbdbe3423cdA5e92A3cC8ba9BFD41F67EE9168,
      0x72Dbdbe3423cdA5e92A3cC8ba9BFD41F67EE9168,
      0x72Dbdbe3423cdA5e92A3cC8ba9BFD41F67EE9168
    ];

    address[] buggedRewards = [
      0x1C7a460413dD4e964f96D8dFC56E7223cE88CD85,
      0x5607718c64334eb5174CB2226af891a6ED82c7C6,
      0x1C7a460413dD4e964f96D8dFC56E7223cE88CD85,
      0x5607718c64334eb5174CB2226af891a6ED82c7C6,
      0x998e44232BEF4F8B033e5A5175BDC97F2B10d5e5,
      0x1C7a460413dD4e964f96D8dFC56E7223cE88CD85,
      0x5607718c64334eb5174CB2226af891a6ED82c7C6,
      0x998e44232BEF4F8B033e5A5175BDC97F2B10d5e5,
      0x1C7a460413dD4e964f96D8dFC56E7223cE88CD85,
      0x5607718c64334eb5174CB2226af891a6ED82c7C6,
      0x1C7a460413dD4e964f96D8dFC56E7223cE88CD85,
      0x5607718c64334eb5174CB2226af891a6ED82c7C6,
      0x998e44232BEF4F8B033e5A5175BDC97F2B10d5e5,
      0x1C7a460413dD4e964f96D8dFC56E7223cE88CD85,
      0x5607718c64334eb5174CB2226af891a6ED82c7C6,
      0x5607718c64334eb5174CB2226af891a6ED82c7C6,
      0x1C7a460413dD4e964f96D8dFC56E7223cE88CD85,
      0x5607718c64334eb5174CB2226af891a6ED82c7C6,
      0x998e44232BEF4F8B033e5A5175BDC97F2B10d5e5,
      0x998e44232BEF4F8B033e5A5175BDC97F2B10d5e5,
      0x5607718c64334eb5174CB2226af891a6ED82c7C6,
      0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913,
      0x998e44232BEF4F8B033e5A5175BDC97F2B10d5e5,
      0x1C7a460413dD4e964f96D8dFC56E7223cE88CD85,
      0x5607718c64334eb5174CB2226af891a6ED82c7C6,
      0x998e44232BEF4F8B033e5A5175BDC97F2B10d5e5
    ];

    function setUp() public {
        vm.createSelectFork(vm.envString("FORK_URL"), FORK_BLOCK_NUMBER - 1);
        // vm.createSelectFork(vm.envString("FORK_URL"), END_BLOCK_NUMBER);

        rewardsProxy =  RewardsControllerAdminFunctions(Constants.POOL_ADDRESSES_PROVIDER.getAddress(REWARDS_PROXY_ADDRESS_ID));
        IPoolAddressesProvider addressesProvider = IPoolAddressesProvider(address(Constants.POOL_ADDRESSES_PROVIDER));

        address controllerWithAdminImplementationV4 = address(new RewardsControllerAdminFunctions(Constants.EMISSION_MANAGER));
        vm.startPrank(0x639d2dD24304aC2e6A691d8c1cFf4a2665925fee);
          addressesProvider.setAddressAsProxy(REWARDS_PROXY_ADDRESS_ID, controllerWithAdminImplementationV4);
        vm.stopPrank();
    }

    function test_run() public {
      assertEq(rewardsProxy.REVISION(), 4);

      // state after replayed actions
      assertEq(block.number, FORK_BLOCK_NUMBER - 1);
      handleActionCalls("./queryResults/handleAction_until_15442183_1_s.json", 32000);
      handleActionCalls("./queryResults/handleAction_until_15442183_2_s.json", 32000);
      handleActionCalls("./queryResults/handleAction_until_15442183_3_s.json", 9214);
      claimRewardsCalls("./queryResults/claimRewards_until_15442183.json", 16);
      claimAllRewardsCalls("./queryResults/claimAllRewards_until_15442183.json", 43);
      writeUserData("./queryResults/distinctUsers.json", "./test/out/userDataOut.csv");

            // handleActionCalls("./queryResults/handleAction_until_15442183_1.json", 10);
            // claimAllRewardsCalls("./queryResults/claimAllRewards_until_15442183.json", 4);

      // current state
      // assertEq(block.number, END_BLOCK_NUMBER);
      // writeUserData("./queryResults/distinctUsers.json", "./test/out/userDataOut_current.csv");
    }

    function handleActionCalls(string memory filename, uint256 numRows) internal {
        vm.writeLine('./test/out/test.txt', 'handleActionCalls');

        string memory rawJson = vm.readFile(filename);
        
        address[] memory users = rawJson.readAddressArray(".data.user");
        address[] memory assets = rawJson.readAddressArray(".data.asset");
        uint256[] memory totalSupplys = rawJson.readUintArray(".data.totalSupply");
        uint256[] memory userBalances = rawJson.readUintArray(".data.userBalance");

        for(uint256 i=0; i<numRows; i++) {
          rewardsProxy.adminHandleAction(users[i], totalSupplys[i], userBalances[i], assets[i]);
        }
    }

    function claimRewardsCalls(string memory filename, uint256 numRows) internal {
      vm.writeLine('./test/out/test.txt', 'claimRewardsCalls');

      string memory rawJson = vm.readFile(filename);
        
      for(uint256 i=0; i<numRows; i++) {
        string memory id = Strings.toString(i);

        bytes memory assetsBytes = rawJson.parseRaw(string(abi.encodePacked(".result.rows[", id , "].assets")));
        address[] memory assets = abi.decode(assetsBytes, (address[]));

        uint256 amount = rawJson.readUint(string(abi.encodePacked(".result.rows[", id , "].amount")));
        address to = rawJson.readAddress(string(abi.encodePacked(".result.rows[", id , "].to")));
        address reward = rawJson.readAddress(string(abi.encodePacked(".result.rows[", id , "].reward")));
        address user = rawJson.readAddress(string(abi.encodePacked(".result.rows[", id , "].call_tx_from")));
        // CHECK if user is != of call_tx_from

        // console.log("---", i);
        // console.log(assets.length, amount);
        // console.log(to, reward, user);

        rewardsProxy.adminClaimRewards(assets, amount, to, reward, user);
      }
    }

    function claimAllRewardsCalls(string memory filename, uint256 numRows) internal {
       vm.writeLine('./test/out/test.txt', 'claimAllRewardsCalls');

      string memory rawJson = vm.readFile(filename);
      
      for(uint256 i=0; i<numRows; i++) {
        string memory id = Strings.toString(i);

        bytes memory assetsBytes = rawJson.parseRaw(string(abi.encodePacked(".result.rows[", id , "].assets")));
        address[] memory assets = abi.decode(assetsBytes, (address[]));

        address to = rawJson.readAddress(string(abi.encodePacked(".result.rows[", id , "].to")));
        address user = rawJson.readAddress(string(abi.encodePacked(".result.rows[", id , "].call_tx_from")));
        // CHECK if user is != of call_tx_from

        // console.log("~~~", i);
        // console.log(assets.length, to, user);

        rewardsProxy.adminClaimAllRewards(assets, to, user);
      }
    }

    function writeUserData(string memory usersFilename, string memory outFilename) internal {
      vm.writeLine('./test/out/test.txt', 'writeUserData');

      string memory rawJson = vm.readFile(usersFilename);

      bytes memory usersBytes = rawJson.parseRaw(".users");
      address[] memory users = abi.decode(usersBytes, (address[]));

      vm.writeLine(outFilename, "user,asset,reward,userAccrued,userIndex");

      for(uint256 u=0; u<users.length; u++) {
        address user = users[u];

        address[] memory checkAssets;
        address[] memory checkRewards;
        uint256 usedNum = 0;

        {
          // buggedAssets has fixed length of 26
          bool[] memory useIt = new bool[](26);
          for(uint256 i=0; i<26; i++) {
            if (i>0 && buggedAssets[i] == buggedAssets[i-1]) {
              useIt[i] = useIt[i-1];
            } else {
              useIt[i] = IERC20(buggedAssets[i]).balanceOf(user) > 0;
            }
            if (useIt[i]) usedNum++;
          }

          checkAssets = new address[](usedNum);
          checkRewards = new address[](usedNum);
          uint256 next=0;
          for(uint256 i=0; i<26; i++) {
            if (useIt[i]) {
              checkAssets[next] = buggedAssets[i];
              checkRewards[next] = buggedRewards[i];
              next++;
            }
          }
        }
        
        (uint256[] memory indexes, uint256[] memory accrueds) = 
          rewardsProxy.getUserAssetRewardIndexAndAccrued(user, checkAssets, checkRewards);

        for(uint256 i=0; i<usedNum; i++) {
          vm.writeLine(
            outFilename,
            string.concat(
              Strings.toHexString(user),
              ",",
              Strings.toHexString(checkAssets[i]),
              ",",
              Strings.toHexString(checkRewards[i]),
              ",",
              Strings.toString(accrueds[i]),
              ",",
              Strings.toString(indexes[i])
            )
          );
        }
      }
    }
}
