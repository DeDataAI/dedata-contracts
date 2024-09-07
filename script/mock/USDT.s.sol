// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import { USDT } from "../../src/mock/USDT.sol";

contract USDTScript is Script {
  function setUp() public {}

  function run() public {
    address deployer = msg.sender;
    console.log("Deployer: %s", deployer);
    vm.startBroadcast();
    USDT usdt = new USDT(deployer);
    vm.stopBroadcast();
    console.log("USDT Address: %s", address(usdt));
  }
}
