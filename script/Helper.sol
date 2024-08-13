// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract Helper {
    // Supported Networks
    enum SupportedNetworks {
        ETHEREUM_SEPOLIA,   // 0
        MODE_SEPOLIA        // 919
    }

    mapping(SupportedNetworks enumValue => string humanReadableName)
        public networks;

    enum PayFeesIn {
        Native,
        LINK
    }

    // Chain IDs
    uint64 constant chainIdEthereumSepolia = 16015286601757825753;
    uint64 constant chainIdModeSepolia = 829525985033418733;

    // Router Addresses
    address constant routerEthereumSepolia =
        0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59;
    address constant routerModeSepolia =
        0xc49ec0eB4beb48B8Da4cceC51AA9A5bD0D0A4c43;

    // Link Addresses (can be used as fee)
    address constant linkEthereumSepolia =
        0x779877A7B0D9E8603169DdbD7836e478b4624789;
    address constant linkModeSepolia =
        0x925a4bfE64AE2bFAC8a02b35F78e60C29743755d;

    // Wrapped Native Addresses
    address constant wethEthereumSepolia =
        0x097D90c9d3E0B50Ca60e1ae45F6A81010f9FB534;
    address constant wethModeSepolia =
        0x4200000000000000000000000000000000000006;

    // CCIP-BnM Addresses
    address constant ccipBnMEthereumSepolia =
        0xFd57b4ddBf88a4e07fF4e34C487b99af2Fe82a05;
    address constant ccipBnMModeSepolia =
        0xFd57b4ddBf88a4e07fF4e34C487b99af2Fe82a05;

    // CCIP-LnM Addresses
    address constant ccipLnMEthereumSepolia =
        0x466D489b6d36E7E3b824ef491C225F5830E81cC1;
    address constant clCcipLnMModeSepolia =
        0x466D489b6d36E7E3b824ef491C225F5830E81cC1;

    constructor() {
        networks[SupportedNetworks.ETHEREUM_SEPOLIA] = "Ethereum Sepolia";
        networks[SupportedNetworks.MODE_SEPOLIA] = "Mode Sepolia";
    }

    function getDummyTokensFromNetwork(
        SupportedNetworks network
    ) internal pure returns (address ccipBnM, address ccipLnM) {
        if (network == SupportedNetworks.ETHEREUM_SEPOLIA) {
            return (ccipBnMEthereumSepolia, ccipLnMEthereumSepolia);
        } else if (network == SupportedNetworks.MODE_SEPOLIA) {
            return (ccipBnMModeSepolia, clCcipLnMModeSepolia);
        }
    }

    function getConfigFromNetwork(
        SupportedNetworks network
    )
        internal
        pure
        returns (
            address router,
            address linkToken,
            address wrappedNative,
            uint64 chainId
        )
    {
        if (network == SupportedNetworks.ETHEREUM_SEPOLIA) {
            return (
                routerEthereumSepolia,
                linkEthereumSepolia,
                wethEthereumSepolia,
                chainIdEthereumSepolia
            );
        } else if (network == SupportedNetworks.MODE_SEPOLIA) {
            return (
                routerModeSepolia,
                linkModeSepolia,
                wethModeSepolia,
                chainIdModeSepolia
            );
        }
    }
}
