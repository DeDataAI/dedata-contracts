// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import { PointHelper } from "../src/PointHelper.sol";
import { DD } from "../src/DD.sol";
import { USDT } from "../src/mock/USDT.sol";
import { ProxyAdmin } from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import { ITransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import { Upgrades } from "openzeppelin-foundry-upgrades/Upgrades.sol";

contract PointHelperTest is Test {
  ITransparentUpgradeableProxy public proxyAdmin;
  PointHelper public pointHelper;
  DD public dd;
  USDT public usdt;
  uint256 public constant exchangeRate = 1e5;
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
    dd = new DD(owner);
    console.log("DeData Address: %s", address(dd));
    usdt = new USDT(owner);
    console.log("USDT Address: %s", address(usdt));
    address proxy = Upgrades.deployTransparentProxy(
      "PointHelper.sol",
      owner,
      abi.encodeCall(
        PointHelper.initialize,
        (owner, oracle, address(dd), exchangeRate)
      )
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

    vm.startPrank(owner);
    // DD balance of user should be 10B
    assertEq(dd.balanceOf(owner), 10e9 ether);
    // transfer DD tokens to PointHelper
    dd.transfer(address(pointHelper), 1e9 ether);
    console.log("PointHelper Balance: %s", dd.balanceOf(address(pointHelper)));

    // tranfer USDT tokens to PointHelper
    usdt.transfer(address(pointHelper), 1e9 ether);
    console.log(
      "PointHelper USDT Balance: %s",
      usdt.balanceOf(address(pointHelper))
    );
    vm.stopPrank();
  }

  /**
   * @dev add points
   * @param point - Point struct
   */
  function _addPoints(PointHelper.Point memory point) internal {
    bytes32 messageHash = pointHelper.getMessageHash(user, point);
    console.logBytes32(messageHash);

    // Oracle's signature
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(oraclePrivateKey, messageHash);
    bytes memory oracleSignature = abi.encodePacked(r, s, v);
    console.logBytes(oracleSignature);

    vm.startPrank(user);
    pointHelper.addPoints(user, point, oracleSignature);
    vm.stopPrank();
  }

  /**
   * @dev Test addPoints
   */
  function testAddPoints() public {
    PointHelper.Point memory point = PointHelper.Point(0, 1001 ether, 10);
    _addPoints(point);

    // get user points and tasks
    (uint256 points, uint256 tasks) = pointHelper.userPoints(user);
    assertEq(points, 1001 ether);
    assertEq(tasks, 10);

    console.log("User Points: %s", points);
    console.log("User Tasks: %s", tasks);
  }

  /**
   * @dev Test claim
   */
  function testClaim() public {
    // add points
    uint256 points = 1000 ether;
    PointHelper.Point memory point = PointHelper.Point(0, points, 10);
    _addPoints(point);

    // claim tokens
    uint256 firstClaim = 100 ether;
    vm.startPrank(user);
    pointHelper.claim(firstClaim);
    vm.stopPrank();

    // get user exchanged points
    uint256 exchangedPoints = pointHelper.exchangedPoints(user);
    assertEq(firstClaim, exchangedPoints);

    // balance of user should be points * exchangeRate / 1e5
    uint256 tokens = (firstClaim * exchangeRate) / 1e5;
    assertEq(dd.balanceOf(user), tokens);

    // claim tokens
    vm.startPrank(user);
    pointHelper.claim();
    vm.stopPrank();

    // get user exchanged points
    exchangedPoints = pointHelper.exchangedPoints(user);
    assertEq(points, exchangedPoints);

    // balance of user should be points * exchangeRate / 1e5
    tokens = (points * exchangeRate) / 1e5;
    assertEq(dd.balanceOf(user), tokens);

    console.log("User Points: %s", points);
    console.log("User Exchanged Points: %s", exchangedPoints);
    console.log("Exchange Rate: %s", exchangeRate);
    console.log("User Tokens: %s", tokens);

    // it should revert if user tries to claim without points that are not exchanged
    vm.startPrank(user);
    vm.expectRevert();
    pointHelper.claim();
    vm.stopPrank();

    // it should revert if user tries to claim with more points than available
    vm.startPrank(user);
    vm.expectRevert();
    pointHelper.claim(1 ether);
    vm.stopPrank();
  }
  /**
   * @dev Test claim bonus
   */
  function testClaimBonus() public {
    PointHelper.Bonus memory bonus = PointHelper.Bonus(
      0,
      address(usdt),
      1000 ether
    );
    bytes32 messageHash = pointHelper.getBonusMessageHash(user, bonus);
    console.logBytes32(messageHash);

    // Oracle's signature
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(oraclePrivateKey, messageHash);
    bytes memory oracleSignature = abi.encodePacked(r, s, v);
    console.logBytes(oracleSignature);

    vm.startPrank(user);
    pointHelper.claimBonus(user, bonus, oracleSignature);
    vm.stopPrank();

    // get user bonus
    uint256 userBonus = pointHelper.userBonuses(user, bonus.token);
    assertEq(userBonus, 1000 ether);

    console.log("User Bonus: %s", userBonus);

    // it should revert if user tries to claim bonus with the same nonce
    vm.startPrank(user);
    vm.expectRevert();
    pointHelper.claimBonus(user, bonus, oracleSignature);
    vm.stopPrank();
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

  /**
   * @dev Set the exchange rate
   */
  function testSetExchangeRate() public {
    uint256 newExchangeRate = 2e5;
    vm.startPrank(owner);
    pointHelper.setExchangeRate(newExchangeRate);
    vm.stopPrank();

    assertTrue(pointHelper.exchangeRate() == newExchangeRate);
  }
}
