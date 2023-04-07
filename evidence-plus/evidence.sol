pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable@4.8.0/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable@4.8.0/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable@4.8.0/proxy/utils/UUPSUpgradeable.sol";

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract Evidence is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() initializer public {
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}

    uint8 threshold; //投票阈值

    mapping(address => Auditors) private auditors; //审核方集合

    struct Auditors {
        bool status;
        bytes32 did;
    }

    address[] auditorsArray;

    mapping(bytes32 => SaveRequest) private saveRequests; //存证请求数据集合

    struct SaveRequest {
        bytes32 hash;
        address owner;
        address creator;
        uint8 voted;
        bytes remaks;
        uint256 timestamp;
        uint8 status;
        Voters[] voters;
    }

    struct Voters {
        address voter;
        bool status;
        bytes32 did;
    }

    struct Evidence {
        bytes32 hash;
        address owner;
        bytes remaks;
        uint256 timestamp;
        bool status;
    }

    event SetThreshold(address indexed operator, uint8 threshold); //设置投票阈值

    event ConfigureAuditor(
        address indexed operator,
        address auditor,
        bool approvals
    ); //添加审核方

    event CreateSaveRequest(
        address indexed operator,
        bytes32 hash,
        address owner
    ); //提交存证请求

    event DeleteSaveRequest(
        address indexed operator,
        bytes32 hash,
        address owner
    ); //删除存证请求
    
    event VoteSaveRequest(
        address indexed operator,
        bytes32 hash,
        address voter
    ); //批准存证请求
    
    event SetStatus(
        address indexed operator,
        bytes32 hash,
        bool status
    ); //设置状态


    modifier validateHash(bytes32 hash) {
        require(hash != 0, "Not valid hash");
        _;
    }

    //设置投票阈值
    function setThreshold(uint8 number) public onlyOwner {
        threshold = number;

        emit SetThreshold(msg.sender, number);
    }

    //添加审核方：auditor审核方账户、approval授权标识
    function configureAuditor(address auditor, bool approval, bytes32 did) public onlyOwner {
        auditors[auditor].status = approval;
        auditors[auditor].did = did;

        auditorsArray.push(auditor);

        emit ConfigureAuditor(msg.sender, auditor, approval);
    }

    //提交存证请求
    function createSaveRequest(
        bytes32 hash,
        address owner,
        bytes memory remaks
    ) public validateHash(hash) {
        saveRequests[hash].hash = hash;
        saveRequests[hash].owner = owner;
        saveRequests[hash].creator = msg.sender;
        saveRequests[hash].voted = 0;
        saveRequests[hash].remaks = remaks;
        saveRequests[hash].timestamp = block.timestamp;
        saveRequests[hash].status = 0;

        emit CreateSaveRequest(msg.sender, hash, owner);
    }

    //删除存证请求
    function deleteSaveRequest(bytes32 hash) public {
        require(saveRequests[hash].hash == hash, "request not found");

        SaveRequest storage request = saveRequests[hash];
        require(request.creator == msg.sender, "no permission");
        //检查是否已通过投票
        require(request.status != 1, "passed votes cannot be deleted");

        delete saveRequests[hash];

        emit DeleteSaveRequest(msg.sender, hash, request.owner);
    }

    //查看存证请求
    function getRequestData(
        bytes32 hash
    ) public view returns (SaveRequest memory) {
        require(saveRequests[hash].hash == hash, "request not found");
        SaveRequest storage request = saveRequests[hash];
        return request;
    }

    //批准存证请求
    function voteSaveRequest(
        bytes32 hash,
        bool status
    ) public validateHash(hash) {
        require(auditors[msg.sender].status == true, "Not allowed to vote"); //是否为审核方
        require(saveRequests[hash].hash == hash, "request not found"); //hash是否存在

        SaveRequest storage request = saveRequests[hash];

        //msg.sender是否已投过票
        bool voted = false;
        for (uint i = 0; i < request.voters.length; i++) {
            if (request.voters[i].voter == msg.sender) {
                voted = true;
                break;
            }
        }
        require(voted == false, "Voter already voted");

        require(request.status != 1, "Voter already voted"); //是否已完成投票

        request.voters.push(Voters(msg.sender, status, auditors[msg.sender].did));
        request.voted++;

        //投票状态投票中0、通过1、不通过2
        uint8 voteStatus = 0;
        uint8 number = 0;
        for (uint i = 0; i < request.voters.length; i++) {
            if (request.voters[i].status == status) {
                if (status == true) {
                    number++;
                    if (number >= threshold) {
                        voteStatus = 1;
                        break;
                    }
                } else if (status == false) {
                    number++;
                    if (number > auditorsArray.length - threshold) {
                        voteStatus = 2;
                        break;
                    }
                }
            }
        }

        if (voteStatus == 1) {
            setData(hash, request.owner, request.remaks, block.timestamp);
        }
        request.status = voteStatus;

        emit VoteSaveRequest(msg.sender, hash, request.owner);
    }

    mapping(bytes32 => Evidence) private evidences;

    function setData(
        bytes32 hash,
        address owner,
        bytes memory remaks,
        uint256 timestamp
    ) private {
        require(hash != 0, "Not valid hash");
        evidences[hash].hash = hash;
        evidences[hash].owner = owner;
        evidences[hash].remaks = remaks;
        evidences[hash].timestamp = timestamp;
        evidences[hash].status = true;
    }

    //查看存证数据
    function getEvidence(bytes32 hash) public view returns (Evidence memory) {
        
        require(evidences[hash].hash == hash, "Evidence not found");
        require(evidences[hash].status == true, "The certificate data has been disabled");
        return evidences[hash];
    }

    //设置存证数据状态
    function setStatus(bytes32 hash, bool status) public {
        evidences[hash].status = status;
        
        emit SetStatus(msg.sender, hash, status);
    }


}
