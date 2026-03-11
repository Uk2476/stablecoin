//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {DecentralisedStableCoin} from "../src/DecentralisedStableCoin.sol";
import {Test} from "forge-std/Test.sol";

contract DecentralisedStableCoinTest is Test {
    DecentralisedStableCoin public Dsc ;
    address User = makeAddr("User");

    function setUp() public {
        Dsc = new DecentralisedStableCoin();
        vm.deal(User, 100 ether);
        vm.deal(msg.sender, 100 ether);
    }


    
}