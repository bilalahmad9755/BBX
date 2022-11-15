// SPDX-License-Identifier: Unlicensed
pragma solidity 0.7.5;
interface Isynth {
    function mint(address account,uint256 amount) external returns (bool);
    function burn(address account,uint256 amount) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function chainlinkPrice() external view returns (uint256);
    function SynthPrice() external view returns (uint256);
    function synthToUsd(uint256 amount) external view returns (uint256);
    function usdToSynth(uint256 amount) external view returns (uint256);


}
