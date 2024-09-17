// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import { UnionNFT } from "../src/UnionNFT.sol";
import { ProxyAdmin } from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import { ITransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import { Upgrades } from "openzeppelin-foundry-upgrades/Upgrades.sol";

contract UnionNFTTest is Test {
  ITransparentUpgradeableProxy public proxyAdmin;
  UnionNFT public unionNFT;
  address public owner;
  uint256 internal ownerPrivateKey = 0x1;
  address public user = address(0xACC1);
  address public user2 = address(0xACC2);

  function setUp() public {
    owner = vm.addr(ownerPrivateKey);
    console.log("Owner: %s", owner);
    console.log("User: %s", user);

    vm.startPrank(user);
    address proxy = Upgrades.deployTransparentProxy(
      "UnionNFT.sol",
      owner,
      abi.encodeCall(
        UnionNFT.initialize,
        (
          owner,
          "UnionNFT",
          "UnionNFT",
          "https://api.dedata.io/v1/nfts/",
          200,
          1
        )
      )
    );
    console.log("Proxy Address: %s", proxy);
    unionNFT = UnionNFT(proxy);

    address implAddress = Upgrades.getImplementationAddress(proxy);
    console.log("Implementation Address: %s", implAddress);
    address proxyAdminAddress = Upgrades.getAdminAddress(proxy);
    console.log("Proxy Admin Address: %s", proxyAdminAddress);
    address proxyAdminOwnerAddress = ProxyAdmin(proxyAdminAddress).owner();
    console.log("Proxy Admin Owner Address: %s", proxyAdminOwnerAddress);
    proxyAdmin = ITransparentUpgradeableProxy(proxyAdminAddress);
    assertTrue(proxyAdminOwnerAddress == owner);
    assertTrue(unionNFT.owner() == owner);
    vm.stopPrank();
  }

  /**
   * @dev Test mint
   */
  function testMint() public {
    vm.startPrank(user);
    uint256 tokenId = unionNFT.mint();
    vm.stopPrank();

    assertTrue(tokenId == 1);
    assertTrue(unionNFT.ownerOf(tokenId) == user);
    assertTrue(unionNFT.mintedTokens(user) == 1);

    // it should revert if max supply is reached
    vm.startPrank(user);
    vm.expectRevert();
    unionNFT.mint();
    vm.stopPrank();
  }

  /**
   * @dev Test max supply
   */
  function testMaxSupply() public {
    vm.startPrank(owner);
    unionNFT.setMaxSupply(1);
    vm.stopPrank();

    assertTrue(unionNFT.maxSupply() == 1);

    testMint();

    // it should revert if new max supply is less than the current supply
    vm.startPrank(owner);
    vm.expectRevert();
    unionNFT.setMaxSupply(1);
    vm.stopPrank();

    // it should revert if reached max supply
    vm.startPrank(user2);
    vm.expectRevert("UnionNFT: max supply reached");
    unionNFT.mint();
    vm.stopPrank();
  }
}
