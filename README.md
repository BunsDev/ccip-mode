# ccip-mode
Example demonstrating how to use CCIP on Mode blockchain.

## Chainlink CCIP Starter Kit

> _This repository represents an example of using a Chainlink product or service. It is provided to help you understand how to interact with Chainlink’s systems so that you can integrate them into your own. This template is provided "AS IS" without warranties of any kind, has not been audited, and may be missing key checks or error handling to make the usage of the product more clear. Take everything in this repository as an example and not something to be copy pasted into a production ready service._

This project demonstrates a couple of basic Chainlink CCIP use cases.

## What is Chainlink CCIP?

**Chainlink Cross-Chain Interoperability Protocol (CCIP)** provides a single, simple, and elegant interface through which dApps and web3 entrepreneurs can securely meet all their cross-chain needs, including token transfers and arbitrary messaging.

![basic-architecture](./img/basic-architecture.png)

**Chainlink CCIP Main Functionality**:

1. Transfer Tokens
2. Send Arbitrary Data
3. Send Programmable Tokens

Receiver can be either a smart contract that implements `CCIPReceiver.sol` or an EOA, **but if you send a message and token(s) to EOA, only tokens will arrive**.

## Getting Started

In the next section you can see a couple of basic Chainlink CCIP use case examples. But before that, you need to set up some environment variables, install dependencies, setup environment variables, and compile contracts.

### A. Install Dependencies
```
yarn && make
```

### B. Setup Environment Variables
Copy & paste `.env.example` and name it `.env` and fill in the variables.

```shell
cp .env.example .env
```

After filling out your `.env`, run the following:
```shell
source .env
```

### C. Cast Interactive Setup
Cast enables you to interact directly with a blockchain. Setup your wallet, using the following command: 
```shell
cast wallet address --interactive
```

# Setup Scenario

## [...] Deploy Contracts
In order to interact with our contracts, we first need to deploy them, which is simplified in the [`script/Deploy.s.sol`](./script/Deploy.s.sol) smart contract. 

We have package scripts that enable you to deploy contracts, as follows:

```shell
yarn deploy
```
- [`BasicTokenSender.sol`](./src/BasicTokenSender.sol)
- [`BasicMessageSender.sol`](./src/BasicMessageSender.sol)
- [`BasicMessageReceiver.sol`](./src/BasicMessageReceiver.sol)
- [`ProgrammableTokenTransfers.sol`](./src/ProgrammableTokenTransfers.sol)

## [...] Acquire Test Tokens from Faucet
In order to proceed with transferring tokens, you must first acquire test tokens from your source chain.  The command below, calls a faucet drip function to acquire `ccipBnm` -- also `ccipLnm`, when [transacting on an Ethereum network](https://docs.chain.link/ccip/supported-networks/v1_2_0/testnet#ethereum-sepolia-mode-sepolia):

```shell
forge script ./script/utils/Faucet.s.sol -vvv --broadcast --rpc-url modeSepolia --sig "run(bool)" -- false
```

### [...] Load Contracts with Test Tokens

After acquiring testnet tokens, you will proceed with funding your [Message Sender Contract](./src/BasicMessageSender.sol) and [Programmable Tokens Contract](./src/ProgrammableTokenTransfers.sol). 

- **Native Funding**: the following commands will send **0.1 native tokens** (ETH) to the contracts deployed on your source (Mode Sepolia) and destination (Ethereum Sepolia).


- **LINK Funding**: the following commands will send **1 LINK** to the contracts deployed on your source (Mode Sepolia) and destination (Ethereum Sepolia).

### [...] Fund Message Sender Contract
**with 0.1 Native (ETH)**
```shell
cast send $MESSAGE_SENDER_ADDRESS --rpc-url modeSepolia --value 0.1ether
```

**with 1 LINK**
```shell
cast send $SOURCE_LINK_ADDRESS "transfer(address,uint256)"  $MESSAGE_SENDER_ADDRESS 1000000000000000000 --rpc-url modeSepolia
``` 

### [...] Fund Programmable Tokens Contracts
**with 0.1 Native (ETH)**
```shell
cast send $SOURCE_PROGRAMMABLE_TOKENS_ADDRESS --rpc-url modeSepolia --value 0.1ether && cast send $DESTINATION_PROGRAMMABLE_TOKENS_ADDRESS --rpc-url ethereumSepolia --value 0.1ether
```
**with 1 LINK**
```shell
cast send $SOURCE_LINK_ADDRESS "transfer(address,uint256)" $SOURCE_PROGRAMMABLE_TOKENS_ADDRESS 1000000000000000000 --rpc-url modeSepolia && cast send $DESTINATION_LINK_ADDRESS "transfer(address,uint256)" $DESTINATION_PROGRAMMABLE_TOKENS_ADDRESS 1000000000000000000 --rpc-url ethereumSepolia
```

## Scenarios
> *Before proceeding with this section, please ensure you have completed the steps outlined in the [Setup for Scenario](#setup-for-scenario) section above.*


### [...] Scenario 1: Transfer Tokens
- **1A | Transfer Tokens**: transfer tokens from one EOA on one blockchain to another EOA on another blockchain you can use the `script/Transfer.s.sol` smart contract. 

    - Run the following to send 1 CCIP-BnM from Mode Sepolia to Ethereum Sepolia and to pay for CCIP fees in LINK:
        ```shell
        forge script ./script/Transfer.s.sol -vvv --broadcast --rpc-url modeSepolia --sig "run(uint256,uint8)" -- 1000000000000000000 1
        ```

### [...] Scenario 2: Send Message

- **2A | [...] Transfer Tokens**: run the following to send `1 CCIP-BnM` from Mode Sepolia &rarr; Ethereum Sepolia (fee in ETH):

    ```shell
    forge script ./script/Message.s.sol:CCIPTokenTransfer -vvv --broadcast --rpc-url modeSepolia --sig "run(address,uint256,uint8)" -- 0xFd57b4ddBf88a4e07fF4e34C487b99af2Fe82a05 1000000000000000000 0
    ```

- **2B | [...] Send Cross-Chain Message**: run the following to send "Hello World" as a message:

    ```shell
    forge script ./script/Message.s.sol:SendMessage -vvv --broadcast --rpc-url modeSepolia --sig "run(string,uint8)" -- "Hello World" 0
    ```

- **2C | [...] Get Details**: once the CCIP message is finalized on the destination blockchain, you can see the details about the latest message using the `script/Message.s.sol:GetLatestMessageDetails` smart contract.

    ```shell
    forge script ./script/Message.s.sol:GetLatestMessageDetails -vvv --broadcast --rpc-url ethereumSepolia --sig "run()"
    ```

- **2D | [...] Withdraw Tokens**: finally, you can always withdraw received tokens from the [`BasicMessageSender.sol`](./src/BasicMessageSender.sol) and  [`BasicMessageReceiver.sol`](./src/BasicMessageReceiver.sol) via `cast send` command. 

    - **Message Sender**: you can always withdraw tokens for Chainlink CCIP fees, as follows.

        ```shell
        cast send $MESSAGE_SENDER_ADDRESS --rpc-url modeSepolia "withdraw(address)" $BENEFICIARY_ADDRESS
        ```

    - **Message Receiver**: withdraw 100 units of CCIP-BnM previously sent, run:

        ```shell
        cast send $MESSAGE_RECEIVER_ADDRESS --rpc-url ethereumSepolia "withdrawToken(address,address)" $BENEFICIARY_ADDRESS 0xFd57b4ddBf88a4e07fF4e34C487b99af2Fe82a05
        ```

### [...] Scenario 3: Program Tokens
Our final scenario involves programmable tokens. These enable you to send & receive tokens that contain code that instructs them with code to execute once they are received.

At this point, you have one **sender** contract on the source blockchain, and one **receiver** contract on the destination blockchain. Please note that [`ProgrammableTokenTransfers.sol`](./src/ProgrammableTokenTransfers.sol) can both send & receive tokens and data, hence we have two identical instances on both source and destination blockchains.

**3A | Send Message**: send a message, using the `script/Program.s.sol:SendTokensAndData` smart contract:

Use the following to send a "Hello World" `message` alongside 100 (`amount`) units of the CCIP-BnM (`token`) from Mode Sepolia to Ethereum Sepolia:

```shell
forge script ./script/Program.s.sol:SendTokensAndData -vvv --broadcast --rpc-url modeSepolia --sig "run(string,address,uint256)" -- "Hello World" 0xFd57b4ddBf88a4e07fF4e34C487b99af2Fe82a05 100
```

**3B | Get Details**: once the CCIP message is finalized on the destination blockchain, you can see the details of the latest CCIP message received, by running the following command:

```shell
cast call $DESTINATION_PROGRAMMABLE_TOKENS_ADDRESS "getLastReceivedMessageDetails()" --rpc-url ethereumSepolia
```


---

# Resources

- Check the [Official Chainlink Documentation](https://docs.chain.link/ccip).
- [Comprehensive CCIP Flowchart](https://docs.chain.link/images/ccip/manual-execution.png)