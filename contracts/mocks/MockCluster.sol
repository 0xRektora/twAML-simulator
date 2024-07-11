// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

contract MockCluster {
    constructor(uint32 _lzChainId, address _owner) {}

    function hasRole(address, bytes32) external pure returns (bool) {
        return true;
    }
}
