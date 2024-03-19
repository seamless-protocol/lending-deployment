// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IPoolAddressesProvider} from "aave-v3-core/contracts/interfaces/IPoolAddressesProvider.sol";

library Constants {
    IPoolAddressesProvider constant POOL_ADDRESSES_PROVIDER = IPoolAddressesProvider(0x0E02EB705be325407707662C6f6d3466E939f3a0);
}
