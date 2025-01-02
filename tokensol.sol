// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenomicsToken is ERC20, Ownable {
    uint256 public taxRate; // Tax rate in basis points (e.g., 100 = 1%)
    address public taxWallet;

    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        uint256 _taxRate,
        address _taxWallet
    ) ERC20(name, symbol) {
        require(_taxWallet != address(0), "Invalid tax wallet address");
        require(_taxRate <= 1000, "Tax rate too high"); // Max 10%

        taxRate = _taxRate;
        taxWallet = _taxWallet;

        _mint(msg.sender, initialSupply * (10 ** decimals()));
    }

    function setTaxRate(uint256 _taxRate) external onlyOwner {
        require(_taxRate <= 1000, "Tax rate too high");
        taxRate = _taxRate;
    }

    function setTaxWallet(address _taxWallet) external onlyOwner {
        require(_taxWallet != address(0), "Invalid tax wallet address");
        taxWallet = _taxWallet;
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        uint256 tax = (amount * taxRate) / 10000;
        uint256 netAmount = amount - tax;

        if (tax > 0) {
            _transfer(_msgSender(), taxWallet, tax);
        }
        _transfer(_msgSender(), recipient, netAmount);

        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        uint256 tax = (amount * taxRate) / 10000;
        uint256 netAmount = amount - tax;

        if (tax > 0) {
            _transfer(sender, taxWallet, tax);
        }
        _transfer(sender, recipient, netAmount);

        uint256 currentAllowance = allowance(sender, _msgSender());
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }
}
