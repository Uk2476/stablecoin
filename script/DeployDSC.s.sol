//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {DecentralisedStableCoin} from "../src/DecentralisedStableCoin.sol";
import {DSCEngine} from "../src/DSCEngine.sol";
import {Script} from "forge-std/Script.sol";

contract DeploDSC is Script {

    function run() external returns (DSCEngine , DecentralisedStableCoin) {
        HelperConfig helperConfig = new HelperConfig();


        
        vm.startBroadcast();
        DecentralisedStableCoin dsc = new DecentralisedStableCoin();
        DSCEngine dscEngine = new DSCEngine();
        vm.stopBroadcast();
    }
}

