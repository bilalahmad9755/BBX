// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "./OlympusERC20Token.sol";
import './libraries/SafeMath.sol';


contract BBX is OlympusERC20Token {
    using SafeMath for uint256;
    mapping(address => bool) public isWhiteListed;

    constructor(string memory _name, string memory _symbol) OlympusERC20Token(_name, _symbol){
    }
    
    address feeTo;
    uint256 public taxRate;
    // 100000 -> 100%
    // 10000 -> 10%
    // 1000 -> 1%
    // 100 -> 0.1%
    // 10 -> 0.01%
    // 1 -> 0.001%

    function setWhileList(address _entity)public onlyOwner returns(bool _success)
    {
        isWhiteListed[_entity] = true;
        return isWhiteListed[_entity];
    }
    function delWhiteList(address _entity)public onlyOwner returns(bool _success)
    {
        isWhiteListed[_entity] = false;
        return isWhiteListed[_entity];
    }
    function setTax(uint256 _tax) public onlyOwner {
        taxRate = _tax;
    }

    function setFeeTo(address _feeTo) public onlyOwner {
        feeTo = _feeTo;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        if(isWhiteListed[msg.sender] || isWhiteListed[recipient])
        {
            _transfer(msg.sender, recipient, amount);
            return true;
        }
        else
        {
        uint256 fee = amount.mul(taxRate).div(100000);
        uint256 amountAfterFee = amount.sub(fee);
        _transfer(msg.sender, recipient, amountAfterFee);
        _transfer(msg.sender, feeTo, fee);
        return true;
        }
        
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        if(isWhiteListed[msg.sender] || isWhiteListed[recipient] || isWhiteListed[sender])
        {
            _transfer(sender, recipient, amount);
            _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
            return true;
        }
        else
        {
        uint256 fee = amount.mul(taxRate).div(100000);
        uint256 amountAfterFee = amount.sub(fee);
        _transfer(sender, recipient, amountAfterFee);
        _transfer(sender, feeTo, fee);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
        }
        
    }
}