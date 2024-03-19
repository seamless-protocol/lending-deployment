// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IPoolAddressesProvider} from "seamless/aave-v3-core/interfaces/IPoolAddressesProvider.sol";
import {ISequencerOracle} from "seamless/aave-v3-core/interfaces/ISequencerOracle.sol";

library Constants {
    IPoolAddressesProvider constant POOL_ADDRESSES_PROVIDER =
        IPoolAddressesProvider(0x0E02EB705be325407707662C6f6d3466E939f3a0);
    ISequencerOracle constant SEQUENCER_ORACLE = ISequencerOracle(0xBCF85224fc0756B9Fa45aA7892530B47e10b6433);
    uint256 constant SEQUENCER_ORACLE_GRACE_PERIOD = 3600;
}
