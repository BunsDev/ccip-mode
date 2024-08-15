# ccip-mode
Example demonstrating how to use CCIP on Mode blockchain.

## Chainlink CCIP Starter Kit

> _This repository represents an example of using a Chainlink product or service. It is provided to help you understand how to interact with Chainlink’s systems so that you can integrate them into your own. This template is provided "AS IS" without warranties of any kind, has not been audited, and may be missing key checks or error handling to make the usage of the product more clear. Take everything in this repository as an example and not something to be copy pasted into a production ready service._

This project demonstrates a couple of basic Chainlink CCIP use cases.

## What is Chainlink CCIP?

**Chainlink Cross-Chain Interoperability Protocol (CCIP)** provides a single, simple, and elegant interface through which dApps and web3 entrepreneurs can securely meet all their cross-chain needs, including token transfers and arbitrary messaging.

![basic-architecture](./img/basic-architecture.png)

**With Chainlink CCIP, one can**:

1. Transfer Tokens
2. Send Arbitrary Data
3. Send Programmable Tokens

Receiver can be either a smart contract that implements `CCIPReceiver.sol` or an EOA, **but if you send a message and token(s) to EOA, only tokens will arrive**.

## Getting Started

In the next section you can see a couple of basic Chainlink CCIP use case examples. But before that, you need to set up some environment variables, install dependencies, setup environment variables, and compile contracts.

### A. Install Packages and Compile Contracts
```
    yarn && make
```

### B. Setup Environment Variables
Copy & paste `.env.example` and name it `.env` and fill in the variables.

```
cp .env.example .env
```

After filling out your `.env`, run the following:
```
source .env
```

### C. Cast Interactive Setup
Cast enables you to interact directly with a blockchain. Setup your wallet, using the following command: 
```
cast wallet address --interactive
```

### Fill up with Test Tokens
```shell
forge script ./script/utils/Faucet.s.sol -vvv --broadcast --rpc-url modeSepolia --sig "run(bool)" -- false
```

## Scenarios
    
    1. Transfer Tokens
    2. Send Message
    3. Program Tokens

### 0. Deploy Contracts
In order to interact with our contracts, we first need to deploy them, which is simplified in the [`script/Deploy.s.sol`](./script/Deploy.s.sol) smart contract. 

We have package scripts that enable you to deploy contracts, as follows:

```shell
yarn deploy
```
- [`BasicTokenSender.sol`](./src/BasicTokenSender.sol)
- [`BasicMessageSender.sol`](./src/BasicMessageSender.sol)
- [`BasicMessageReceiver.sol`](./src/BasicMessageReceiver.sol)
- [`ProgrammableTokenTransfers.sol`](./src/ProgrammableTokenTransfers.sol)

### [...] 1. Transfer Tokens: from EOA &rarr; EOA

Transfer tokens from one EOA on one blockchain to another EOA on another blockchain you can use the `script/Transfer.s.sol` smart contract:

For example, if you want to send 1 CCIP-BnM from Mode Sepolia to Ethereum Sepolia and to pay for CCIP fees in LINK, run:

```shell
forge script ./script/Transfer.s.sol -vvv --broadcast --rpc-url modeSepolia --sig "run(uint256,uint8)" -- 1000000000000000000 1
```
---
### 2. Message - Receive: Transfer Tokens from EOA &rarr; Smart Contract

To transfer tokens from EOA from the source blockchain to the smart contract on the destination blockchain, follow the next steps:

1. **Transfer Tokens**: send from the **source blockchain** to the deployed BasicMessageReceiver smart contract using the `script/Message.s.sol:CCIPTokenTransfer` smart contract:

> ***For example**: to send 0.0000000000000001 CCIP-BnM from Mode Sepolia to Ethereum Sepolia and to pay for CCIP fees in native coin (Test ETH), run the command below.* 
```shell
forge script ./script/Message.s.sol:CCIPTokenTransfer -vvv --broadcast --rpc-url modeSepolia --sig "run(uint8,uint8,address,address,uint256,uint8)" -- 2 0 <MESSAGE_RECEIVER_ADDRESS> 0xFd57b4ddBf88a4e07fF4e34C487b99af2Fe82a05 100 0
```

3. **Get Details**: once the CCIP message is finalized on the destination blockchain, you can see the details about the latest message using the `script/Message.s.sol:GetLatestMessageDetails` smart contract:

For example,

```shell
forge script ./script/Message.s.sol:GetLatestMessageDetails -vvv --broadcast --rpc-url ethereumSepolia --sig "run(address)" -- <MESSAGE_RECEIVER_ADDRESS>
```

4. Finally, you can always withdraw received tokens from the [`BasicMessageReceiver.sol`](./src/BasicMessageReceiver.sol) smart contract using the `cast send` command.

For example, to withdraw 100 units of CCIP-BnM previously sent, run:

```shell
cast send <MESSAGE_RECEIVER_ADDRESS> --rpc-url ethereumSepolia --private-key=$PRIVATE_KEY "withdrawToken(address,address)" <BENEFICIARY_ADDRESS> 0xFd57b4ddBf88a4e07fF4e34C487b99af2Fe82a05
```

### TokenSender: Transfer Token(s) from Smart Contract

To transfer a token or batch of tokens from a single, universal, smart contract to any address on the destination blockchain follow the next steps:

1. Fill the [`BasicTokenSender.sol`](./src/BasicTokenSender.sol) with tokens/coins for fees (you can always withdraw it later). You can do it manually from your wallet or by using the `cast send` command. For example, if you want to pay for Chainlink CCIP Fees in LINK tokens, you can fill the [`BasicTokenSender.sol`](./src/BasicTokenSender.sol) smart contract with 1 Mode Sepolia LINK by running:

```shell
cast send <SOURCE_LINK_ADDRESS> "transfer(address,uint256)" <TOKEN_SENDER_ADDRESS> 1000000000000000000 --rpc-url modeSepolia --private-key=$PRIVATE_KEY
```

Or, if you want to pay for Chainlink CCIP Fees in Native coins, you can fill the [`BasicTokenSender.sol`](./src/BasicTokenSender.sol) smart contract with 0.1 Mode Sepolia ETH by running:

```shell
cast send <TOKEN_SENDER_ADDRESS> --rpc-url modeSepolia --private-key=$PRIVATE_KEY --value 0.1ether
```

4. For each token you want to send, you will need to approve the [`BasicTokenSender.sol`](./src/BasicTokenSender.sol) to spend it on your behalf, by using the `cast send` command.

For example, if you want to send 0.0000000000000001 CCIP-BnM using the [`BasicTokenSender.sol`](./src/BasicTokenSender.sol) you will first need to approve that amount:

```shell
cast send 0xFd57b4ddBf88a4e07fF4e34C487b99af2Fe82a05 "approve(address,uint256)" <BASIC_TOKEN_SENDER_ADDRESS> 100 --rpc-url modeSepolia --private-key=$PRIVATE_KEY
```

5. Finally, send tokens by providing the array of `Client.EVMTokenAmount {address token; uint256 amount;}` objects, using the `script/Send.s.sol:SendBatch` smart contract:

For example, to send CCIP-BnM token amounts you previously approved from Mode Sepolia to Ethereum Sepolia, and pay for Chainlink CCIP fees in LINK tokens, run:

```shell
forge script ./script/Send.s.sol:SendBatch -vvv --broadcast --rpc-url modeSepolia --sig "run(uint8,address,address,(address,uint256)[],uint8)" -- 0 <BASIC_TOKEN_SENDER_ADDRESS> <RECEIVER> "[(0xFd57b4ddBf88a4e07fF4e34C487b99af2Fe82a05,100)]" 1
```

6. Of course, you can always withdraw tokens you sent to the [`BasicTokenSender.sol`](./src/BasicTokenSender.sol) for fees, or from [`BasicMessageReceiver.sol`](./src/BasicMessageReceiver.sol) if you received them there.

For example, to withdraw ERC20 tokens, run:

```shell
cast send <CONTRACT_WITH_FUNDS_ADDRESS> --rpc-url <RPC_ENDPOINT> --private-key=$PRIVATE_KEY "withdrawToken(address,address)" <BENEFICIARY_ADDRESS> <TOKEN_TO_WITHDRAW_ADDRESS>
```

And to withdraw Native coins, run:

```shell
cast send <CONTRACT_WITH_FUNDS_ADDRESS> --rpc-url <RPC_ENDPOINT> --private-key=$PRIVATE_KEY "withdraw(address)" <BENEFICIARY_ADDRESS>
```

### Program: Send & Receive Tokens and Data
- Transfer tokens and data across multiple chains.

1. **Deploy [`ProgrammableTokenTransfers.sol`](./src/ProgrammableTokenTransfers.sol)**: to the **source blockchain**, using the `script/Deploy.s.sol:DeployProgrammableTokens` smart contract:
2. **Fund Contract** (to deployed contract)
    - The example below demonstrates how you can send 0.1 Mode Sepolia ETH to your contract.
```shell
cast send <PROGRAMMABLE_TOKEN_TRANSFERS_ADDRESS> --rpc-url modeSepolia --private-key=$PRIVATE_KEY --value 0.1ether
```
    - Send Mode Sepolia LINK to your contract via another `cast send` command:

```shell
cast send $SOURCE_LINK_ADDRESS "transfer(address,uint256)" $PROGRAMMABLE_TOKENS_ADDRESS 1000000000000000000 --rpc-url modeSepolia --private-key=$PRIVATE_KEY
```

4. Deploy the [`ProgrammableTokenTransfers.sol`](./src/ProgrammableTokenTransfers.sol) smart contract to the **destination blockchain**, using the `script/Deploy.s.sol:DeployProgrammableTokens` smart contract, as you did in step number one (todo: `--sig "run(uint8)" -- 0`)

At this point, you have one **sender** contract on the source blockchain, and one **receiver** contract on the destination blockchain. Please note that [`ProgrammableTokenTransfers.sol`](./src/ProgrammableTokenTransfers.sol) can both send & receive tokens and data, hence we have two identical instances on both source and destination blockchains.

5. Send a message, using the `script/Program.s.sol:SendTokensAndData` smart contract:

For example, if you want to send a "Hello World" message alongside 100 units of CCIP-BnM from Mode Sepolia to Ethereum Sepolia, type:

```shell
forge script ./script/Program.s.sol:SendTokensAndData -vvv --broadcast --rpc-url modeSepolia --sig "run(address,uint8,address,string,address,uint256)" -- <PROGRAMMABLE_TOKEN_TRANSFERS_ADDRESS_ON_SOURCE_BLOCKCHAIN> 0 <PROGRAMMABLE_TOKEN_TRANSFERS_ADDRESS_ON_DESTINATION_BLOCKCHAIN> "Hello World" 0xFd57b4ddBf88a4e07fF4e34C487b99af2Fe82a05 100
```

6. Once the CCIP message is finalized on the destination blockchain, you can see the details of the latest CCIP message received, by running the following command:

```shell
cast call <PROGRAMMABLE_TOKEN_TRANSFERS_ADDRESS_ON_DESTINATION_BLOCKCHAIN> "getLastReceivedMessageDetails()" --rpc-url ethereumSepolia
```

### MessageSender: Send & Receive Cross-Chain Messages and Pay with Native Coins

To send simple Text Cross-Chain Messages and pay for CCIP fees in Native Tokens, follow the next steps:

1. Deploy the [`BasicMessageSender.sol`](./src/BasicMessageSender.sol) smart contract on the **source blockchain**, using the `script/Message.s.sol:DeployMessageSender` smart contract:

For example, if you want to send a simple cross-chain message from Mode Sepolia, run:

```shell
forge script ./script/Message.s.sol:DeployMessageSender -vvv --broadcast --rpc-url modeSepolia --sig "run(uint8)" -- 2
```

2. Fund the [`BasicMessageSender.sol`](./src/BasicMessageSender.sol) smart contract with Native Coins, either manually using your wallet or by using the `cast send` command. For example, if you want to send 0.1 Mode Sepolia ETH, run:

```shell
cast send <BASIC_MESSAGE_SENDER_ADDRESS> --rpc-url modeSepolia --private-key=$PRIVATE_KEY --value 0.1ether
```

3. Deploy the [`BasicMessageReceiver.sol`](./src/BasicMessageReceiver.sol) smart contract to the **destination blockchain**. For this purpose, you can reuse the `script/Deploy.s.sol:DeployMessageReceiver` smart contract from the second example:

```solidity
function run(SupportedNetworks destination) external;
```

For example, to deploy it to Ethereum Sepolia, run:

```shell
forge script ./script/Example02.s.sol:DeployMessageReceiver -vvv --broadcast --rpc-url ethereumSepolia --sig "run(uint8)" -- 0
```

4. Finally, send a cross-chain message using the `script/Message.s.sol:SendMessage` smart contract:

```solidity
function run(
    address payable sender,
    SupportedNetworks destination,
    address receiver,
    string memory message,
    BasicMessageSender.PayFeesIn payFeesIn
) external;
```

For example, if you want to send a "Hello World" message type:

```shell
forge script ./script/Message.s.sol:SendMessage -vvv --broadcast --rpc-url modeSepolia --sig "ru
n(address,uint8,address,string,uint8)" -- <BASIC_MESSAGE_SENDER_ADDRESS> 0 <MESSAGE_RECEIVER_ADDRESS> "Hello World"
0
```

5. Once the CCIP message is finalized on the destination blockchain, you can see the details about the latest message using the `script/Example02.s.sol:GetLatestMessageDetails` smart contract:

```solidity
function run(address basicMessageReceiver) external view;
```

For example,

```shell
forge script ./script/Example02.s.sol:GetLatestMessageDetails -vvv --broadcast --rpc-url ethereumSepolia --sig "run(address)" -- <MESSAGE_RECEIVER_ADDRESS>
```

6. You can always withdraw tokens for Chainlink CCIP fees from the [`BasicMessageSender.sol`](./src/BasicMessageSender.sol) smart contract using the `cast send` command:

```shell
cast send <BASIC_MESSAGE_SENDER_ADDRESS> --rpc-url modeSepolia --private-key=$PRIVATE_KEY "withdraw(address)" <BENEFICIARY_ADDRESS>
```

### MessageSender: Send & Receive Cross-Chain Messages and Pay with LINK Tokens

To send simple Text Cross-Chain Messages and pay for CCIP fees in LINK Tokens, follow the next steps:

1. Deploy the [`BasicMessageSender.sol`](./src/BasicMessageSender.sol) smart contract on the **source blockchain**, using the `script/Message.s.sol:DeployMessageSender` smart contract:

```solidity
function run(SupportedNetworks source) external;
```

For example, if you want to send a simple cross-chain message from Mode Sepolia, run:

```shell
forge script ./script/Message.s.sol:DeployMessageSender -vvv --broadcast --rpc-url modeSepolia --sig "run(uint8)" -- 2
```

2. Fund the [`BasicMessageSender.sol`](./src/BasicMessageSender.sol) smart contract with Testnet LINKs, either manually using your wallet or by using the `cast send` command. For example, if you want to send 1 Mode Sepolia LINK, run:

```shell
cast send <LINK_TOKEN_SENDER_ADDRESS> "transfer(address,uint256)" <BASIC_MESSAGE_SENDER_ADDRESS> 1000000000000000000 --rpc-url modeSepolia --private-key=$PRIVATE_KEY
```

3. Deploy the [`BasicMessageReceiver.sol`](./src/BasicMessageReceiver.sol) smart contract to the **destination blockchain**. For this purpose, you can reuse the `script/Example02.s.sol:DeployMessageReceiver` smart contract from the second example:

```solidity
function run(SupportedNetworks destination) external;
```

For example, to deploy it to Ethereum Sepolia, run:

```shell
forge script ./script/Example02.s.sol:DeployMessageReceiver -vvv --broadcast --rpc-url ethereumSepolia --sig "run(uint8)" -- 0
```

4. Finally, send a cross-chain message using the `script/Message.s.sol:SendMessage` smart contract:

```solidity
function run(
    address payable sender,
    SupportedNetworks destination,
    address receiver,
    string memory message,
    BasicMessageSender.PayFeesIn payFeesIn
) external;
```

For example, if you want to send a "Hello World" message type:

```shell
forge script ./script/Message.s.sol:SendMessage -vvv --broadcast --rpc-url modeSepolia --sig "ru
n(address,uint8,address,string,uint8)" -- <BASIC_MESSAGE_SENDER_ADDRESS> 0 <MESSAGE_RECEIVER_ADDRESS> "Hello World"
1
```

5. Once the CCIP message is finalized on the destination blockchain, you can see the details about the latest message using the `script/Example02.s.sol:GetLatestMessageDetails` smart contract:

```solidity
function run(address basicMessageReceiver) external view;
```

For example,

```shell
forge script ./script/Example02.s.sol:GetLatestMessageDetails -vvv --broadcast --rpc-url ethereumSepolia --sig "run(address)" -- <MESSAGE_RECEIVER_ADDRESS>
```

6. You can always withdraw tokens for Chainlink CCIP fees from the [`BasicMessageSender.sol`](./src/BasicMessageSender.sol) smart contract using the `cast send` command:

```shell
cast send <BASIC_MESSAGE_SENDER_ADDRESS> --rpc-url modeSepolia --private-key=$PRIVATE_KEY "withdrawToken(address,address)" <BENEFICIARY_ADDRESS> <LINK_TOKEN_SENDER_ADDRESS>
```

depending on whether you filled the [`SourceMinter.sol`](./src/SourceMinter.sol) contract with `Native (0)` or `LINK (1)` in step number 3.


---

# Resources

- Check the [Official Chainlink Documentation](https://docs.chain.link/ccip).