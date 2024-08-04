// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import { PointHelper } from "../src/PointHelper.sol";
import { Upgrades } from "openzeppelin-foundry-upgrades/Upgrades.sol";

contract PointHelperScript is Script {
  function setUp() public {}

  function run() public {
    //    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    //    address deployer = vm.addr(deployerPrivateKey);
    address deployer = msg.sender;
    console.log("Deployer: %s", deployer);
    address owner = vm.envOr("OWNER", deployer);
    console.log("Owner: %s", owner);
    address oracle = vm.envOr("ORACLE", deployer);
    console.log("Oracle: %s", oracle);

    //    vm.startBroadcast(deployerPrivateKey);
    vm.startBroadcast();
    address proxy = Upgrades.deployTransparentProxy(
      "PointHelper.sol",
      owner,
      abi.encodeCall(PointHelper.initialize, (owner, oracle))
    );
    vm.stopBroadcast();
    console.log("Proxy Address: %s", proxy);
    address implAddress = Upgrades.getImplementationAddress(proxy);
    console.log("Implementation Address: %s", implAddress);
    address proxyAdminAddress = Upgrades.getAdminAddress(proxy);
    console.log("Proxy Admin Address: %s", proxyAdminAddress);
  }
}
