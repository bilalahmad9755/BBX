// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;



interface iBBX {
    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);
    
    function mint( address account_, uint256 amount_ ) external;

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function burn(uint256 amount) external;
}
