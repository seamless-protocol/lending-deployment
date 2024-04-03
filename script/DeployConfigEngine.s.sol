// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {Script, console} from "forge-std/Script.sol";
import {IDefaultInterestRateStrategy} from "seamless/aave-v3-core/interfaces/IDefaultInterestRateStrategy.sol";
import {Create2Utils} from "seamless/aave-helpers/ScriptUtils.sol";
import {AaveV3ConfigEngine} from "seamless/aave-helpers/v3-config-engine/AaveV3ConfigEngine.sol";
import {
    IAaveV3ConfigEngine,
    IPool,
    IPoolConfigurator,
    IAaveOracle
} from "seamless/aave-helpers/v3-config-engine/IAaveV3ConfigEngine.sol";
import {V3RateStrategyFactory} from "seamless/aave-helpers/v3-config-engine/V3RateStrategyFactory.sol";
import {
    IV3RateStrategyFactory,
    IPoolAddressesProvider
} from "seamless/aave-helpers/v3-config-engine/IV3RateStrategyFactory.sol";
import {ListingEngine} from "seamless/aave-helpers/v3-config-engine/libraries/ListingEngine.sol";
import {EModeEngine} from "seamless/aave-helpers/v3-config-engine/libraries/EModeEngine.sol";
import {BorrowEngine} from "seamless/aave-helpers/v3-config-engine/libraries/BorrowEngine.sol";
import {CollateralEngine} from "seamless/aave-helpers/v3-config-engine/libraries/CollateralEngine.sol";
import {PriceFeedEngine} from "seamless/aave-helpers/v3-config-engine/libraries/PriceFeedEngine.sol";
import {RateEngine} from "seamless/aave-helpers/v3-config-engine/libraries/RateEngine.sol";
import {CapsEngine} from "seamless/aave-helpers/v3-config-engine/libraries/CapsEngine.sol";
import {ITransparentProxyFactory} from
    "solidity-utils/contracts/transparent-proxy/interfaces/ITransparentProxyFactory.sol";
import {ProxyAdmin} from "solidity-utils/contracts/transparent-proxy/ProxyAdmin.sol";
import {TransparentProxyFactory} from "solidity-utils/contracts/transparent-proxy/TransparentProxyFactory.sol";
import {Constants} from "./Constants.sol";

contract DeployConfigEngine is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);

        console.log("Deployer address: ", deployerAddress);
        console.log("Deployer balance: ", deployerAddress.balance);
        console.log("BlockNumber: ", block.number);
        console.log("ChainId: ", block.chainid);

        vm.startBroadcast(deployerPrivateKey);

        TransparentProxyFactory transparentProxyFactory = new TransparentProxyFactory();
        ProxyAdmin proxyAdmin = ProxyAdmin(transparentProxyFactory.createProxyAdmin(Constants.GUARDIAN));

        (address ratesStrategyFactory,) = _createAndSetupRatesFactory(
            IPoolAddressesProvider(address(Constants.POOL_ADDRESSES_PROVIDER)),
            address(transparentProxyFactory),
            address(proxyAdmin)
        );

        IAaveV3ConfigEngine.EngineLibraries memory engineLibraries = IAaveV3ConfigEngine.EngineLibraries({
            listingEngine: Create2Utils.create2Deploy("v1", type(ListingEngine).creationCode),
            eModeEngine: Create2Utils.create2Deploy("v1", type(EModeEngine).creationCode),
            borrowEngine: Create2Utils.create2Deploy("v1", type(BorrowEngine).creationCode),
            collateralEngine: Create2Utils.create2Deploy("v1", type(CollateralEngine).creationCode),
            priceFeedEngine: Create2Utils.create2Deploy("v1", type(PriceFeedEngine).creationCode),
            rateEngine: Create2Utils.create2Deploy("v1", type(RateEngine).creationCode),
            capsEngine: Create2Utils.create2Deploy("v1", type(CapsEngine).creationCode)
        });

        IAaveV3ConfigEngine.EngineConstants memory engineConstants = IAaveV3ConfigEngine.EngineConstants({
            pool: IPool(Constants.POOL_ADDRESSES_PROVIDER.getPool()),
            poolConfigurator: IPoolConfigurator(Constants.POOL_ADDRESSES_PROVIDER.getPoolConfigurator()),
            ratesStrategyFactory: IV3RateStrategyFactory(ratesStrategyFactory),
            oracle: IAaveOracle(Constants.POOL_ADDRESSES_PROVIDER.getPriceOracle()),
            rewardsController: Constants.REWARDS_CONTROLLER,
            collector: Constants.COLLECTOR
        });

        AaveV3ConfigEngine configEngine = new AaveV3ConfigEngine(
            Constants.ATOKEN_IMPLEMENTATION,
            Constants.VTOKEN_IMPLEMENTATION,
            Constants.STOKEN_IMPLEMENTATION,
            engineConstants,
            engineLibraries
        );

        vm.stopBroadcast();

        console.log("TransparentProxyFactory deployed: ", address(transparentProxyFactory));
        console.log("ProxyAdmin deployed: ", address(proxyAdmin));
        console.log("V3RateStrategyFactory deployed: ", address(ratesStrategyFactory));
        console.log("AaveV3ConfigEngine deployed: ", address(configEngine));

        console.log("listingEngine deployed: ", address(engineLibraries.listingEngine));
        console.log("eModeEngine deployed: ", address(engineLibraries.eModeEngine));
        console.log("borrowEngine deployed: ", address(engineLibraries.borrowEngine));
        console.log("collateralEngine deployed: ", address(engineLibraries.collateralEngine));
        console.log("priceFeedEngine deployed: ", address(engineLibraries.priceFeedEngine));
        console.log("rateEngine deployed: ", address(engineLibraries.rateEngine));
        console.log("capsEngine deployed: ", address(engineLibraries.capsEngine));
    }

    function _createAndSetupRatesFactory(
        IPoolAddressesProvider addressesProvider,
        address transparentProxyFactory,
        address ownerForFactory
    ) internal returns (address, address[] memory) {
        IDefaultInterestRateStrategy[] memory uniqueStrategies =
            _getUniqueStrategiesOnPool(IPool(addressesProvider.getPool()));

        V3RateStrategyFactory ratesFactory = V3RateStrategyFactory(
            ITransparentProxyFactory(transparentProxyFactory).create(
                address(new V3RateStrategyFactory(addressesProvider)),
                ownerForFactory,
                abi.encodeWithSelector(V3RateStrategyFactory.initialize.selector, uniqueStrategies)
            )
        );

        address[] memory strategiesOnFactory = ratesFactory.getAllStrategies();

        return (address(ratesFactory), strategiesOnFactory);
    }

    function _getUniqueStrategiesOnPool(IPool pool) internal view returns (IDefaultInterestRateStrategy[] memory) {
        address[] memory listedAssets = pool.getReservesList();
        IDefaultInterestRateStrategy[] memory uniqueRateStrategies =
            new IDefaultInterestRateStrategy[](listedAssets.length);
        uint256 uniqueRateStrategiesSize;
        for (uint256 i = 0; i < listedAssets.length; i++) {
            address strategy = pool.getReserveData(listedAssets[i]).interestRateStrategyAddress;

            bool found;
            for (uint256 j = 0; j < uniqueRateStrategiesSize; j++) {
                if (strategy == address(uniqueRateStrategies[j])) {
                    found = true;
                    break;
                }
            }

            if (!found) {
                uniqueRateStrategies[uniqueRateStrategiesSize] = IDefaultInterestRateStrategy(strategy);
                uniqueRateStrategiesSize++;
            }
        }

        // The famous one (modify dynamic array size)
        assembly {
            mstore(uniqueRateStrategies, uniqueRateStrategiesSize)
        }

        return uniqueRateStrategies;
    }
}
