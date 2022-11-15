// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.7.5;

contract ReEntrance
{
    bool private locked;

    modifier reEntrance()
    {
        require(!locked, "Function is Locked!");
        locked = true;
        _;
        locked = false;
    }
}
