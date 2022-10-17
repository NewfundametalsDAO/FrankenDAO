// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "oz/proxy/transparent/TransparentUpgradeableProxy.sol";

contract GovernanceProxy is TransparentUpgradeableProxy {
    constructor(address _logic, address _admin, bytes memory _data) 
        TransparentUpgradeableProxy(_logic, _admin, _data) {}
}
