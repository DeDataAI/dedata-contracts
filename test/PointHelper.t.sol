// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import { PointHelper } from "../src/PointHelper.sol";
import { ProxyAdmin } from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import { ITransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import { Upgrades } from "openzeppelin-foundry-upgrades/Upgrades.sol";

contract PointHelperTest is Test {
  ITransparentUpgradeableProxy public proxyAdmin;
  PointHelper public pointHelper;
  address public owner;
  uint256 internal ownerPrivateKey = 0x1;
  address public oracle;
  uint256 internal oraclePrivateKey = 0x2;
  address public user = address(0x3);

  function setUp() public {
    owner = vm.addr(ownerPrivateKey);
    console.log("Owner: %s", owner);
    oracle = vm.addr(oraclePrivateKey);
    console.log("Oracle: %s", oracle);
    console.log("User: %s", user);

    vm.startPrank(user);
    address proxy = Upgrades.deployTransparentProxy(
      "PointHelper.sol",
      owner,
      abi.encodeCall(PointHelper.initialize, (owner, oracle))
    );
    console.log("Proxy Address: %s", proxy);
    pointHelper = PointHelper(proxy);

    address implAddress = Upgrades.getImplementationAddress(proxy);
    console.log("Implementation Address: %s", implAddress);
    address proxyAdminAddress = Upgrades.getAdminAddress(proxy);
    console.log("Proxy Admin Address: %s", proxyAdminAddress);
    address proxyAdminOwnerAddress = ProxyAdmin(proxyAdminAddress).owner();
    console.log("Proxy Admin Owner Address: %s", proxyAdminOwnerAddress);
    proxyAdmin = ITransparentUpgradeableProxy(proxyAdminAddress);
    assertTrue(proxyAdminOwnerAddress == owner);
    assertTrue(pointHelper.owner() == owner);
    assertTrue(pointHelper.oracle() == oracle);
    vm.stopPrank();
  }

  /**
   * @dev Test addPoints
   */
  function testAddPoints() public {
    PointHelper.Point memory point = PointHelper.Point(0, 1001 ether, 10);
    bytes32 messageHash = pointHelper.getMessageHash(user, point);
    console.logBytes32(messageHash);

    // Oracle's signature
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(oraclePrivateKey, messageHash);
    bytes memory oracleSignature = abi.encodePacked(r, s, v);
    console.logBytes(oracleSignature);

    vm.startPrank(user);
    pointHelper.addPoints(user, point, oracleSignature);
    vm.stopPrank();

    // get user points and tasks
    (uint256 points, uint256 tasks) = pointHelper.userPoints(user);
    assertEq(points, 1001 ether);
    assertEq(tasks, 10);

    console.log("User Points: %s", points);
    console.log("User Tasks: %s", tasks);
  }

  /**
   * @dev Test setOracle
   */
  function testSetOracle() public {
    vm.startPrank(owner);
    pointHelper.setOracle(user);
    vm.stopPrank();

    assertTrue(pointHelper.oracle() == user);
  }
}
