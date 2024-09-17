// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import { UnionNFT } from "../src/UnionNFT.sol";
import { Upgrades } from "openzeppelin-foundry-upgrades/Upgrades.sol";

contract UnionNFTScript is Script {
  function setUp() public {}

  function run() public {
    //    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    //    address deployer = vm.addr(deployerPrivateKey);
    address deployer = msg.sender;
    console.log("Deployer: %s", deployer);
    address owner = vm.envOr("OWNER", deployer);
    console.log("Owner: %s", owner);

    //    vm.startBroadcast(deployerPrivateKey);
    vm.startBroadcast();
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
    vm.stopBroadcast();
    console.log("Proxy Address: %s", proxy);
    address implAddress = Upgrades.getImplementationAddress(proxy);
    console.log("Implementation Address: %s", implAddress);
    address proxyAdminAddress = Upgrades.getAdminAddress(proxy);
    console.log("Proxy Admin Address: %s", proxyAdminAddress);
  }
}
