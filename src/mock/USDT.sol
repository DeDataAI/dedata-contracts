// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract USDT is ERC20, ERC20Permit {
  constructor(
    address _owner
  ) ERC20("USDT", "USDT") ERC20Permit("USDT") {
    // mint 10B tokens to the dedata treasury account
    _mint(_owner, 10_000_000_000 * 10 ** decimals());
  }
}
