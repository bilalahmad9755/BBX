// SPDX-License-Identifier: Unlicensed
pragma solidity 0.7.5;

import "./Isynth.sol";
interface Istaking{
    function GetSynthInfo(address synthAddress) external view returns(Isynth);
}
