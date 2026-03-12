// total supply of dsc should be less than the total value of collateral in the system
// getter functions should work correctly

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {DSCEngine} from "../../src/DSCEngine.sol";
import {Test} from "forge-std/Test.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {DecentralisedStableCoin} from "../../src/DecentralisedStableCoin.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract InvariantsTest is StdInvariant , Test {

    DSCEngine public dscEngine;
    DecentralisedStableCoin public dsc;
    HelperConfig public config;
    DeployDSC public deployer;
    address weth;
    address wbtc;

    function setUp() external{
        deployer = new DeployDSC();
        (dscEngine , dsc, config) = deployer.run();
        targetContract(address(dscEngine));
        (,,weth,wbtc,) = config.activeNetworkConfig();
    }

    function invariant_protocolMustHaveMoreValueThanTotalSupply() public view{
        uint256 totalSupply = dsc.totalSupply();
        uint256 total

    }
}

