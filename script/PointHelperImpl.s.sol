// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import { PointHelper } from "../src/PointHelper.sol";

contract PointHelperImplScript is Script {
  function setUp() public {}

  function run() public {
    address deployer = msg.sender;
    console.log("Deployer: %s", deployer);
    vm.startBroadcast();
    PointHelper pointHelper = new PointHelper();
    vm.stopBroadcast();
    console.log("Implementation Address: %s", address(pointHelper));
  }
}
