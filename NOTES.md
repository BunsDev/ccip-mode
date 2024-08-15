# Notes & References

## Helper.sol
Make yourself familiar with the [`Helper.sol`](./script/Helper.sol) smart contract. It contains all the necessary Chainlink CCIP config. If you ever need to adjust any of those parameters, go to the Helper contract.

This contract also contains some enums, like `SupportedNetworks`:

```solidity
enum SupportedNetworks {
    ETHEREUM_SEPOLIA,   // 0
    MODE_SEPOLIA,       // 1
}
```

This means that if you want to perform some action from `MODE_SEPOLIA` &rarr; `ETHEREUM_SEPOLIA`, for example, you'll pass `1 (uint8)` (source: Mode Sepolia) and `0 (uint8)` (destination: Ethereum Sepolia) as your blockchain flags.

Similarly, there is an `PayFeesIn` enum:

```solidity
enum PayFeesIn {
    Native,  // 0
    LINK     // 1
}
```

So, if you want to pay for Chainlink CCIP fees in LINK token, you will pass `1 (uint8)` as a function argument.

## Token Addresses

- **LINK (Mode Sepolia)**: 0x925a4bfE64AE2bFAC8a02b35F78e60C29743755d </br>
- **CCIP-BNM**: 0xFd57b4ddBf88a4e07fF4e34C487b99af2Fe82a05

## Testnet Faucet

You will need test tokens for some of the examples in this Starter Kit. Public faucets sometimes limit how many tokens a user can create and token pools might not have enough liquidity. To resolve these issues, CCIP supports two test tokens that you can mint permissionlessly so you don't run out of tokens while testing different scenarios.

To get 10\*\*18 units of each of these tokens, use the `script/utils/Faucet.s.sol` smart contract. Keep in mind that the `CCIP-BnM` test token you can mint on all testnets, while `CCIP-LnM` you can mint only on Ethereum Sepolia. On other testnets, the `CCIP-LnM` token representation is a wrapped/synthetic asset called `clCCIP-LnM`.

```solidity
function run(SupportedNetworks network) external;
```

For example, to mint 10\*\*18 units of both `CCIP-BnM` and `CCIP-LnM` test tokens on Ethereum Sepolia, run:

```shell
forge script ./script/utils/Faucet.s.sol -vvv --broadcast --rpc-url ethereumSepolia --sig "run(uint8)" -- 0
```

Or if you want to mint 10\*\*18 units of `CCIP-BnM` test token on Mode Sepolia, run:

```shell
forge script ./script/utils/Faucet.s.sol -vvv --broadcast --rpc-url modeSepolia --sig "run(uint8)" -- 2
```

---

### Local Testing

The test files are located in the `test` folder. Note that there are two types of tests:

- **Test with [CCIPLocalSimulator](https://github.com/smartcontractkit/chainlink-local/blob/main/src/ccip/CCIPLocalSimulator.sol)**: These tests are used to test the CCIP functionality in your local environment. They are located in the `test/no-fork` folder. To run these tests, run the following command:

  ```shell
  forge test --no-match-contract ".*ForkTest$"
  ```

- **Test with [CCIPLocalSimulatorFork](https://github.com/smartcontractkit/chainlink-local/blob/main/src/ccip/CCIPLocalSimulatorFork.sol)**: These tests are used to test the CCIP functionality in a forked environment. They are located in the test/fork folder. To run these tests, run the following command:

  ```shell
  forge test --match-contract ".*ForkTest$"
  ```

---
## How-to: Send Tokens via a Smart Contract

### TokenSender: Transfer Token(s) from Smart Contract

To transfer a token or batch of tokens from a single, universal, smart contract to any address on the destination blockchain follow the next steps:

Fill the [`BasicTokenSender.sol`](./src/BasicTokenSender.sol) with tokens/coins for fees (you can always withdraw it later). You can do it manually from your wallet or by using the `cast send` command. For example, if you want to pay for Chainlink CCIP Fees in LINK tokens, you can fill the [`BasicTokenSender.sol`](./src/BasicTokenSender.sol) smart contract with 1 Mode Sepolia LINK by running:

```shell
cast send <SOURCE_LINK_ADDRESS> "transfer(address,uint256)" <TOKEN_SENDER_ADDRESS> 1000000000000000000 --rpc-url modeSepolia --private-key=$PRIVATE_KEY
```

Or, if you want to pay for Chainlink CCIP Fees in Native coins, you can fill the [`BasicTokenSender.sol`](./src/BasicTokenSender.sol) smart contract with 0.1 Mode Sepolia ETH by running:

```shell
cast send <TOKEN_SENDER_ADDRESS> --rpc-url modeSepolia --private-key=$PRIVATE_KEY --value 0.1ether
```


For each token you want to send, you will need to approve the [`BasicTokenSender.sol`](./src/BasicTokenSender.sol) to spend it on your behalf, by using the `cast send` command.

For example, if you want to send 0.0000000000000001 CCIP-BnM using the [`BasicTokenSender.sol`](./src/BasicTokenSender.sol) you will first need to approve that amount:

```shell
cast send 0xFd57b4ddBf88a4e07fF4e34C487b99af2Fe82a05 "approve(address,uint256)" <BASIC_TOKEN_SENDER_ADDRESS> 100 --rpc-url modeSepolia --private-key=$PRIVATE_KEY
```


Finally, send tokens by providing the array of `Client.EVMTokenAmount {address token; uint256 amount;}` objects, using the `script/Send.s.sol:SendBatch` smart contract.

For example, to send CCIP-BnM token amounts you previously approved from Mode Sepolia to Ethereum Sepolia, and pay for Chainlink CCIP fees in LINK tokens, run:

```shell
forge script ./script/Send.s.sol:SendBatch -vvv --broadcast --rpc-url modeSepolia --sig "run(uint8,address,address,(address,uint256)[],uint8)" -- 0 <BASIC_TOKEN_SENDER_ADDRESS> <RECEIVER> "[(0xFd57b4ddBf88a4e07fF4e34C487b99af2Fe82a05,100)]" 1
```


Of course, you can always withdraw tokens you sent to the [`BasicTokenSender.sol`](./src/BasicTokenSender.sol) for fees, or from [`BasicMessageReceiver.sol`](./src/BasicMessageReceiver.sol) if you received them there.

For example, to withdraw ERC20 tokens, run:

```shell
cast send <CONTRACT_WITH_FUNDS_ADDRESS> --rpc-url <RPC_ENDPOINT> --private-key=$PRIVATE_KEY "withdrawToken(address,address)" <BENEFICIARY_ADDRESS> <TOKEN_TO_WITHDRAW_ADDRESS>
```

And to withdraw native coins, run:

```shell
cast send <CONTRACT_WITH_FUNDS_ADDRESS> --rpc-url <RPC_ENDPOINT> --private-key=$PRIVATE_KEY "withdraw(address)" <BENEFICIARY_ADDRESS>
```
