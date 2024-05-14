// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IPoolAddressesProvider} from "seamless/aave-v3-core/interfaces/IPoolAddressesProvider.sol";
import {ISequencerOracle} from "seamless/aave-v3-core/interfaces/ISequencerOracle.sol";
import {IAaveV3ConfigEngine} from "seamless/aave-helpers/v3-config-engine/IAaveV3ConfigEngine.sol";
import {IUiIncentiveDataProviderV3} from "seamless/aave-v3-periphery/misc/interfaces/IUiIncentiveDataProviderV3.sol";

library Constants {
    IPoolAddressesProvider constant POOL_ADDRESSES_PROVIDER =
        IPoolAddressesProvider(0x0E02EB705be325407707662C6f6d3466E939f3a0);

    address constant ATOKEN_IMPLEMENTATION = 0x27076A995387458da63b23d9AFe3df851727A8dB;
    address constant VTOKEN_IMPLEMENTATION = 0x3800DA378e17A5B8D07D0144c321163591475977;
    address constant STOKEN_IMPLEMENTATION = 0xb4D5e163738682A955404737f88FDCF15C1391bF;

    address constant REWARDS_CONTROLLER = 0x91Ac2FfF8CBeF5859eAA6DdA661feBd533cD3780;
    address constant COLLECTOR = 0x982F3A0e3183896f9970b8A9Ea6B69Cd53AF1089;

    IAaveV3ConfigEngine constant CONFIG_ENGINE = IAaveV3ConfigEngine(0xD982669abE883B8bE5f229faAF5153f968B879a0);

    address constant GUARDIAN = 0xA1b5f2cc9B407177CD8a4ACF1699fa0b99955A22;

    ISequencerOracle constant SEQUENCER_ORACLE = ISequencerOracle(0xBCF85224fc0756B9Fa45aA7892530B47e10b6433);
    uint256 constant SEQUENCER_ORACLE_GRACE_PERIOD = 3600;

    address constant EMISSION_MANAGER = 0x6e081F9ebb2B2f07C2f771074EBB32dDac141d14;

    IUiIncentiveDataProviderV3 constant UI_INCENTIVE_PROVIDER_V3 =
        IUiIncentiveDataProviderV3(0x3F5a90eF7BC3eE64e1E95b850DbBC2469fF71ce8);

    address constant TIMELOCK_SHORT = 0x639d2dD24304aC2e6A691d8c1cFf4a2665925fee;
}
