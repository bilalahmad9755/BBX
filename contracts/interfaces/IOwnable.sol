// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.7.5;


interface IOwnable {
  function owner() external view returns (address);
  
  function pushManagement( address newOwner_ ) external;
  
  function pullManagement() external;
}
