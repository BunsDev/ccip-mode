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
