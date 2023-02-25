// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";

import "src/mock/tokens/ERC20Mock.sol";

contract TestERC20Mock is Test {
    ERC20Mock token;

    function setUp() public {
        token = new ERC20Mock("TestToken", "TT", 18);
    }

    function testDecimals() public {
        assertEq(token.decimals(), 18, "ok");
    }
}
