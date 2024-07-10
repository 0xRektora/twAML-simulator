// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {IPearlmit} from "contracts/interfaces/IPearlmit.sol";
import {ICluster} from "contracts/interfaces/ICluster.sol";

/*

████████╗ █████╗ ██████╗ ██╗ ██████╗  ██████╗ █████╗ 
╚══██╔══╝██╔══██╗██╔══██╗██║██╔═══██╗██╔════╝██╔══██╗
   ██║   ███████║██████╔╝██║██║   ██║██║     ███████║
   ██║   ██╔══██║██╔═══╝ ██║██║   ██║██║     ██╔══██║
   ██║   ██║  ██║██║     ██║╚██████╔╝╚██████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
   
*/

struct ERC721PermitStruct {
    address spender;
    uint256 tokenId;
    uint256 nonce;
    uint256 deadline;
}

interface ITapToken {
    struct TapTokenConstructorData {
        uint256 epochDuration;
        address endpoint;
        address contributors;
        address earlySupporters;
        address supporters;
        address lTap;
        address dao;
        address airdrop;
        uint256 governanceEid;
        address owner;
        address tapTokenSenderModule;
        address tapTokenReceiverModule;
        address extExec;
        IPearlmit pearlmit;
        ICluster cluster;
    }
}

struct ERC20PermitStruct {
    address owner;
    address spender;
    uint256 value;
    uint256 nonce;
    uint256 deadline;
}
