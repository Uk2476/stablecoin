//SPDX_License-Identifier: MIT
pragma solidity ^0.8.18;

import {DecentralisedStableCoin} from "./DecentralisedStableCoin.sol";

contract DSCEngine {
    DecentralisedStableCoin public immutable i_dsc;

    constructor(address dscAddress) {
        i_dsc = DecentralisedStableCoin(dscAddress);
    }
}