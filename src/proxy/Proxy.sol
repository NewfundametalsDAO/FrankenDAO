// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "oz/proxy/ERC1967/ERC1967Proxy.sol";

contract FrankenDAOProxy is ERC1967Proxy {
    constructor(address _logic, bytes memory _data) ERC1967Proxy(_logic, _data) {}

    modifier onlyProxyAdmin() {
        require(msg.sender == _getAdmin(), "Proxy: caller is not the proxy admin");
        _;
    }

    function setProxyAdmin(address _newAdmin) external onlyProxyAdmin {
        _changeAdmin(_newAdmin);
    }

    function upgradeImplementation(address _newImplementation) external onlyProxyAdmin {
        _upgradeTo(_newImplementation);
    }

    function upgradeImplementationAndCall(address _newImplementation, bytes calldata _data) external payable onlyProxyAdmin {
        _upgradeToAndCall(_newImplementation, _data, false);
    }
}
