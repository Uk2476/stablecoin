//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ERC20Burnable, ERC20} from "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

contract DecentralisedStableCoin is ERC20Burnable, Ownable {
    error InvalidAddress();
    error AmountMustBeGreaterThanZero();
    error InsufficientBalance();

    constructor() ERC20("DecentralisedStableCoin" , "DSC"){}

    function mint(address to, uint256 amount) external onlyOwner {
        if (to == address(0)) {
            revert InvalidAddress();
        }
        if (amount <= 0) {
            revert AmountMustBeGreaterThanZero();
        }
        _mint(to, amount);
    }

    function burn(uint256 amount) public override onlyOwner {
        if (amount <= 0) {
            revert AmountMustBeGreaterThanZero();
        }
        if (balanceOf(msg.sender) < amount) {
            revert InsufficientBalance();
        }
        super.burn(amount);
    }

}