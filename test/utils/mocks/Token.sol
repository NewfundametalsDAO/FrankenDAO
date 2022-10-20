// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "solmate/tokens/ERC721.sol";

contract Token is ERC721 {
  uint256 public nextTokenId;

  constructor (string memory _name, string memory _symbol) ERC721(_name, _symbol) {}

  function mint(address _to) external returns (uint) {
    ++nextTokenId;
    _mint(_to, nextTokenId);
    return nextTokenId;
  }

  function tokenURI(uint256 id) public view override returns (string memory) {
    return "";
  }
}
