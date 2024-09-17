## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Install
```shell
forge install foundry-rs/forge-std --no-commit
forge install OpenZeppelin/openzeppelin-contracts-upgradeable@v5.0.2 --no-commit
forge install OpenZeppelin/openzeppelin-foundry-upgrades@v0.3.1 --no-commit
```


### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```
#### test a specific contract
```shell
forge test --match-contract PointHelperTest -vvvvv --via-ir 
forge test --match-contract PointHelperTest -vvvvv
forge clean && forge test --match-contract PointHelperTest -vvvvv
forge test --match-contract UnionNFTTest -vvvvv
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/PointHelper.s.sol:PointHelperScript --rpc-url <your_rpc_url> --private-key <your_private_key> --broadcast --verify -vvvv
# deploy the implementation contract
$ forge script script/PointHelperImpl.s.sol:PointHelperImplScript --rpc-url <your_rpc_url> --private-key <your_private_key> --broadcast --verify -vvvv
# deploy the USDT contract
$ forge script script/mock/USDT.s.sol:USDTScript --rpc-url <your_rpc_url> --private-key <your_private_key> --broadcast --verify -vvvv
# deploy the DD contract
$ forge script script/DD.s.sol:DDScript --rpc-url <your_rpc_url> --private-key <your_private_key> --broadcast --verify -vvvv
# deploy the UnionNFT contract
$ forge script script/UnionNFT.s.sol:UnionNFTScript --rpc-url <your_rpc_url> --private-key <your_private_key> --broadcast --verify -vvvv
```

### Cast

```shell
$ cast <subcommand>
$ cast call <contract_address> <method_name> <method_args>
$ cast send <contract_address> <method_name> <method_args> --private-key <private_key>
# demo
$ cast send 0xFF45d2e4E35DdAdC12f6c5a853e9c4BA499e5538 "addPoints(address,(uint256,uint256,uint256),bytes)" 0x4BfB641cA8b5452B8787b4c8500C78298D88069A "(0,1001000000000000000000,10)" 0x04a8b72812e4731aa8ad025aa4c42c0597e97fb26dabaf57bb6a170a82b8bf7977272cff469180aad0bfcbbf90c10890db63278799dbe0ae96a33ae19c85723a1b --rpc-url $RPC --private-key $PRIVATE_KEY 
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
