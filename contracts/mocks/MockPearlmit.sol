// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract MockPearlmit {
    constructor(string memory name, string memory version, address owner, uint256 nativeValueToCheckPauseState) {}

    function approve(uint256 tokenType, address token, uint256 id, address operator, uint200 amount, uint48 expiration)
        external
    {}

    function transferFromERC20(address owner, address to, address token, uint256 amount)
        external
        returns (bool isError)
    {
        IERC20(token).transferFrom(owner, to, amount);
        return false;
    }

    function transferFromERC721(address owner, address to, address token, uint256 id) external returns (bool isError) {
        IERC721(token).safeTransferFrom(owner, to, id, "");
        return false;
    }

    function transferFromERC1155(address owner, address to, address token, uint256 id, uint256 amount)
        external
        returns (bool isError)
    {
        IERC1155(token).safeTransferFrom(owner, to, id, amount, "");
        return false;
    }
}
