// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import { DD } from "../src/DD.sol";

contract DDScript is Script {
  function setUp() public {}

  function run() public {
    address deployer = msg.sender;
    console.log("Deployer: %s", deployer);
    vm.startBroadcast();
    DD dd = new DD(deployer);
    vm.stopBroadcast();
    console.log("DeData Address: %s", address(dd));
  }
}
