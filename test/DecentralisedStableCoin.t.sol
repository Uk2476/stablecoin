//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {DecentralisedStableCoin} from "../src/DecentralisedStableCoin.sol";
import {Test} from "forge-std/Test.sol";

contract DecentralisedStableCoinTest is Test {
    DecentralisedStableCoin public Dsc;
    address User = makeAddr("User");

    function setUp() public {
        Dsc = new DecentralisedStableCoin();
    }

    function testMintOnlyOwner() public {
        vm.prank(User);
        vm.expectRevert();
        Dsc.mint(address(this), 10 ether);
    }

    function testMintAmountEqualsZero() public {
        vm.expectRevert();
        Dsc.mint(address(this), 0);
    }

    function testMintSuccess() public {
        Dsc.mint(address(this), 10 ether);
        assertEq(Dsc.balanceOf(address(this)), 10 ether);
    }

    function testBurnOnlyOwner() public {
        vm.prank(User);
        vm.expectRevert();
        Dsc.burn(10 ether);
    }

    function testBurnAmountEqualsZero() public {
        Dsc.mint(address(this), 10 ether);
        vm.expectRevert();
        Dsc.burn(0);
    }

    function testBurnSuccess() public {
        Dsc.mint(address(this), 10 ether);
        Dsc.burn(5 ether);
        assertEq(Dsc.balanceOf(address(this)), 5 ether);
    }

    function testBurnInsufficeentBalance() public {
        Dsc.mint(address(this), 10 ether);
        vm.expectRevert();
        Dsc.burn(15 ether);
    }
}
