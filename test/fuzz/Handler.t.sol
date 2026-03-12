//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {DSCEngine} from "../../src/DSCEngine.sol";
import {Test} from "forge-std/Test.sol";
import {DecentralisedStableCoin} from "../../src/DecentralisedStableCoin.sol";

contract Handler is Test {

    DSCEngine public dscEngine;
    DecentralisedStableCoin public dsc;

    address public user = makeAddr("User");

    uint256 public constant AMOUNT_COLLATERAL = 10 ether;

    constructor(DSCEngine _dscEngine , DecentralisedStableCoin _dsc){
        dscEngine = _dscEngine;
        dsc = _dsc;
    }

    
}