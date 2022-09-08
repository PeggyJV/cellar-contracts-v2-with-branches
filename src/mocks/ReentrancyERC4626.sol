// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

import { ERC4626, ERC20, SafeTransferLib } from "src/base/ERC4626.sol";
import { Test, console } from "@forge-std/Test.sol";

contract ReentrancyERC4626 is ERC4626, Test {
    using SafeTransferLib for ERC20;

    constructor(
        ERC20 _asset,
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) ERC4626(_asset, _name, _symbol, _decimals) {}

    function totalAssets() public view override returns (uint256 assets) {
        return asset.balanceOf(address(this));
    }

    function deposit(uint256 assets, address receiver) public override returns (uint256) {
        // transfer shares into this contract
        asset.safeTransferFrom(msg.sender, address(this), assets);

        asset.safeApprove(msg.sender, assets);

        // Try to re-enter into cellar via deposit
        ERC4626(msg.sender).deposit(assets, receiver);

        // This return should never be hit because the above deposit calls fails from re-entrancy.
        return 0;
    }
}
