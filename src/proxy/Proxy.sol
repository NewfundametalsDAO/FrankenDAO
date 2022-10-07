// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "oz/proxy/ERC1967/ERC1967Proxy.sol";

contract FrankenDAOProxy is ERC1967Proxy {
    constructor(address _logic, bytes memory _data) ERC1967Proxy(_logic, _data) {}

    modifier onlyProxyAdmin() {
        require(msg.sender == _getAdmin(), "Proxy: caller is not the proxy admin");
        _;
    }

    function setProxyAdmin(address newAdmin) external onlyProxyAdmin {
        _changeAdmin(newAdmin);
    }

    function upgradeImplementation(address newImplementation) external onlyProxyAdmin {
        _upgradeTo(newImplementation);
    }

    function upgradeImplementationAndCall(address newImplementation, bytes calldata data) external payable onlyProxyAdmin {
        _upgradeToAndCall(newImplementation, data, false);
    }
}