// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "./BBX_Token.sol";
import "./interfaces/iBBX.sol";
import "./libraries/SafeMath.sol";
import "./interfaces/iDT.sol";

contract ProtocolsV2 is Ownable
{
    using SafeMath for uint256;

    // fee 1%   --> 100
    // fee 10%  --> 1000
    // fee 100% --> 10000

    struct Protocol
    {
        uint256 id;
        string name;
        uint256 price;
        uint256 reward;
        uint256 vesting;
        uint256 perDayPurchaseLimit;
    }

    struct userPkg
    {
        uint256 lastPurchase; // when last pkg was purchased...
        uint256 pkgCount;    // per day pkg count...
        uint256[] claim;    // expiry of purchased pkgs
    }

    mapping(uint256 => Protocol) public protocolInfo;
    mapping(address => mapping(uint256 => userPkg))public userInfo;
    address public BBXaddress;
    address public DTaddress;
    uint256 burnRate = 500;

     constructor(address _BBX, address _DT)
    {
        BBXaddress = _BBX;
        DTaddress = _DT;
    }

    function currentTime()public view returns(uint256 _time)
    {
        return block.timestamp;
    }

    function createProtocol(uint256 _id, string memory _name, uint256 _price, uint256 _reward, uint256 _vesting, uint256 _perDayPurchaseLimit) external onlyOwner
    {

        require(protocolInfo[_id].id != _id, "Protocol Already Exists!");
        Protocol memory _newProtocol = Protocol({
            id: _id,
            name: _name,
            price: _price,
            reward: _reward,
            vesting: _vesting * 1 minutes,  // defined in days...(testing for minutes!)
            perDayPurchaseLimit: _perDayPurchaseLimit
        });
        protocolInfo[_id] = _newProtocol;
    
    }

    modifier checkLimitPerDay(uint256 _id)
    {
        require((userInfo[msg.sender][_id].pkgCount < protocolInfo[_id].perDayPurchaseLimit) || ((userInfo[msg.sender][_id].lastPurchase + 10 minutes < block.timestamp)), "Max Purchasing Limit Error");
        _;
    }

    function purchaseProtocol(uint256 _id) public checkLimitPerDay(_id) 
    {
        iBBX(BBXaddress).transferFrom(msg.sender, address(this), protocolInfo[_id].price);
        if((userInfo[msg.sender][_id].lastPurchase + 10 minutes) > block.timestamp) // 24hours not completed after purchasing last protocol...
        {
            userInfo[msg.sender][_id].pkgCount =  userInfo[msg.sender][_id].pkgCount + 1;
            userInfo[msg.sender][_id].claim.push(block.timestamp + protocolInfo[_id].vesting);
        }
        else // after 24 hours of purchasing last protocol or purchasing for first time...
        {
            userInfo[msg.sender][_id].lastPurchase = block.timestamp;
            userInfo[msg.sender][_id].pkgCount = 1;
            userInfo[msg.sender][_id].claim.push(block.timestamp + protocolInfo[_id].vesting);
        }
    }

    function getExpiry(uint256 _id, address _user, uint256 _index)public view returns(uint256 _expiry)
    {
        return userInfo[_user][_id].claim[_index];
    }

    function claimPKG(uint256 _id, uint256 _index)public
    {
        require(userInfo[msg.sender][_id].claim[_index] < block.timestamp, "Pkg NOT Expired!");
        userInfo[msg.sender][_id].claim[_index] = userInfo[msg.sender][_id].claim[userInfo[msg.sender][_id].claim.length - 1];
        userInfo[msg.sender][_id].claim.pop();
        iDT(DTaddress).mint(msg.sender, (protocolInfo[_id].price + protocolInfo[_id].reward));
    }
    


}