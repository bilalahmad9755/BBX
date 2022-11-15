// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "./BBX_Token.sol";
import "./interfaces/iBBX.sol";
import "./libraries/SafeMath.sol";
import "./interfaces/iDT.sol";

contract Protocols is Ownable
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
    }
    struct pkgVesting
    {
        uint256 purchaseBlock;
        uint256 expiryBlock;
    }
    struct Day
    {
        uint256 Start;
        uint256 End;
    }

    mapping(uint256 => Protocol) public protocolInfo; // id -> protocol
    mapping(uint256 => mapping(address => pkgVesting[])) public userInfo;   // pkgId -> user -> [purchase, expiry]
    mapping(uint256 => mapping(uint256 => mapping(address => uint256)))public purchaseCountPerDay;   // id => dayend => user => purchase Count of that day...
    address public BBXaddress;
    address public DTaddress;
    uint256 public maxLimitPerDay;
    uint256 public blocksPerDay;
    Day public currentDay;
    uint256 burnRate = 500; // 5%

    constructor(address _BBX, address _DT, uint256 _maxBuyingLimit, uint256 _blocksPerDay)
    {
        BBXaddress = _BBX;
        DTaddress = _DT;
        maxLimitPerDay = _maxBuyingLimit;
        blocksPerDay = _blocksPerDay;
        initialize();
    }

    function initialize() private
    {
        currentDay.Start = block.number;
        currentDay.End = currentDay.Start.add(blocksPerDay);
    }

    function createProtocol(uint256 _id, string memory _name, uint256 _price, uint256 _reward, uint256 _vesting) external onlyOwner
    {

        require(protocolInfo[_id].id != _id, "Protocol Already Exists!");
        Protocol memory _newProtocol = Protocol({
            id: _id,
            name: _name,
            price: _price,
            reward: _reward,
            vesting: _vesting
        });
        protocolInfo[_id] = _newProtocol;
        updateDay();
    }

    function updateDay()public
    {
        if(block.number > currentDay.End)
        {
            currentDay.Start = currentDay.End;
            currentDay.End = currentDay.End.add(blocksPerDay);
        }
    }

    modifier checkLimitPerDay(uint256 _id)
    {
        updateDay();
        // here we will use dayEnd BlockNumber so that it would be constant for all users!
        require(purchaseCountPerDay[_id][currentDay.End][msg.sender] < maxLimitPerDay, "Max Purchased Limit!");
        _;
    }

    function purchaseProtocol(uint256 _id) public checkLimitPerDay(_id)
    {
        iBBX ibbx = iBBX(BBXaddress);
        iDT idt = iDT(DTaddress);
        // transfer Tokens in BBX pool
        ibbx.transferFrom(msg.sender, address(this), protocolInfo[_id].price);
        // increment user purchase count of day
        purchaseCountPerDay[_id][currentDay.End][msg.sender] = purchaseCountPerDay[_id][currentDay.End][msg.sender] + 1;
        // mint BBX Reward and add to pool
        ibbx.mint(address(this), protocolInfo[_id].reward);
        // mint DT Reward and add to pool
        idt.mint(address(this), protocolInfo[_id].reward);
        // calculating and burn 5% of BBX
        uint256 burningAmount = protocolInfo[_id].price.mul(burnRate.div(10000));
        ibbx.burn(burningAmount);
        // store user info
        pkgVesting memory _pkgVesting = pkgVesting({purchaseBlock:block.number, expiryBlock: block.number.add(protocolInfo[_id].vesting)});
        userInfo[_id][msg.sender].push(_pkgVesting);
    }

    function getReward(uint256 _id)public
    {
        updateDay();
        // calculating reward of all expired pkgs of same protocol...
        uint256 claimableReward = 0;
        pkgVesting memory _record;

        for(uint256 i=0; i<= userInfo[_id][msg.sender].length; i++)
        {
           _record = userInfo[_id][msg.sender][i];
           if(_record.expiryBlock < block.number)
           {
               claimableReward = claimableReward + protocolInfo[_id].reward;
               userInfo[_id][msg.sender][i] = userInfo[_id][msg.sender][userInfo[_id][msg.sender].length - 1];
               userInfo[_id][msg.sender].pop();
           }
           else
           {
               i = 0;
           }
        }
        //after calculating reward...

    }
   



}