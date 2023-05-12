pragma solidity ^0.4.4;
/*
 *       Copyright© (2018-2019) WeBank Co., Ltd.
 *
 *       This file is part of weidentity-contract.
 *
 *       weidentity-contract is free software: you can redistribute it and/or modify
 *       it under the terms of the GNU Lesser General Public License as published by
 *       the Free Software Foundation, either version 3 of the License, or
 *       (at your option) any later version.
 *
 *       weidentity-contract is distributed in the hope that it will be useful,
 *       but WITHOUT ANY WARRANTY; without even the implied warranty of
 *       MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *       GNU Lesser General Public License for more details.
 *
 *       You should have received a copy of the GNU Lesser General Public License
 *       along with weidentity-contract.  If not, see <https://www.gnu.org/licenses/>.
 */

contract AuthorityIssuerData {

    // Error codes
    uint constant private RETURN_CODE_SUCCESS = 0;
    uint constant private RETURN_CODE_FAILURE_ALREADY_EXISTS = 500201;
    uint constant private RETURN_CODE_FAILURE_NOT_EXIST = 500202;
    uint constant private RETURN_CODE_NAME_ALREADY_EXISTS = 500203;
    uint constant private RETURN_CODE_UNRECOGNIZED = 500204;

    struct AuthorityIssuer {
        // [0]: name, [1]: desc, [2-11]: extra string
        bytes32[16] attribBytes32;
        // [0]: create date, [1]: update date, [2-11]: extra int
        // [15]: flag for recognition status (0: unrecognized, 1: recognized)
        int[16] attribInt;
        bytes accValue;
    }

    mapping (address => AuthorityIssuer) private authorityIssuerMap;
    address[] private authorityIssuerArray;
    mapping (bytes32 => address) private uniqueNameMap;
    uint recognizedIssuerCount = 0;

    RoleController private roleController;

    // Constructor
    function AuthorityIssuerData(address addr) public {
        roleController = RoleController(addr);
    }

    function isAuthorityIssuer(
        address addr
    ) 
        public 
        constant 
        returns (bool) 
    {
        if (!roleController.checkRole(addr, roleController.ROLE_AUTHORITY_ISSUER())) {
            return false;
        }
        if (authorityIssuerMap[addr].attribBytes32[0] == bytes32(0)) {
            return false;
        }
        return true;
    }

    function addAuthorityIssuerFromAddress(
        address addr,
        bytes32[16] attribBytes32,
        int[16] attribInt,
        bytes accValue
    )
        public
        returns (uint)
    {
        if (authorityIssuerMap[addr].attribBytes32[0] != bytes32(0)) {
            return RETURN_CODE_FAILURE_ALREADY_EXISTS;
        }
        if (isNameDuplicate(attribBytes32[0])) {
            return RETURN_CODE_NAME_ALREADY_EXISTS;
        }

        // Actual Role must be granted by calling recognizeAuthorityIssuer()
        // roleController.addRole(addr, roleController.ROLE_AUTHORITY_ISSUER());

        AuthorityIssuer memory authorityIssuer = AuthorityIssuer(attribBytes32, attribInt, accValue);
        authorityIssuerMap[addr] = authorityIssuer;
        authorityIssuerArray.push(addr);
        uniqueNameMap[attribBytes32[0]] = addr;
        return RETURN_CODE_SUCCESS;
    }
    
    function recognizeAuthorityIssuer(address addr) public returns (uint) {
        if (!roleController.checkPermission(tx.origin, roleController.MODIFY_AUTHORITY_ISSUER())) {
            return roleController.RETURN_CODE_FAILURE_NO_PERMISSION();
        }
        if (authorityIssuerMap[addr].attribBytes32[0] == bytes32(0)) {
            return RETURN_CODE_FAILURE_NOT_EXIST;
        }
        // Set role and flag
        roleController.addRole(addr, roleController.ROLE_AUTHORITY_ISSUER());
        recognizedIssuerCount = recognizedIssuerCount + 1;
        authorityIssuerMap[addr].attribInt[15] = int(1);
        return RETURN_CODE_SUCCESS;
    }

    function deRecognizeAuthorityIssuer(address addr) public returns (uint) {
        if (!roleController.checkPermission(tx.origin, roleController.MODIFY_AUTHORITY_ISSUER())) {
            return roleController.RETURN_CODE_FAILURE_NO_PERMISSION();
        }
        // Remove role and flag
        roleController.removeRole(addr, roleController.ROLE_AUTHORITY_ISSUER());
        recognizedIssuerCount = recognizedIssuerCount - 1;
        authorityIssuerMap[addr].attribInt[15] = int(0);
        return RETURN_CODE_SUCCESS;
    }

    function deleteAuthorityIssuerFromAddress(
        address addr
    ) 
        public 
        returns (uint)
    {
        if (authorityIssuerMap[addr].attribBytes32[0] == bytes32(0)) {
            return RETURN_CODE_FAILURE_NOT_EXIST;
        }
        if (!roleController.checkPermission(tx.origin, roleController.MODIFY_AUTHORITY_ISSUER())) {
            return roleController.RETURN_CODE_FAILURE_NO_PERMISSION();
        }
        roleController.removeRole(addr, roleController.ROLE_AUTHORITY_ISSUER());
        
        if (authorityIssuerMap[addr].attribInt[15] == int(1)) {
            recognizedIssuerCount = recognizedIssuerCount - 1;
        }
        
        uniqueNameMap[authorityIssuerMap[addr].attribBytes32[0]] = address(0x0);
        delete authorityIssuerMap[addr];
        uint datasetLength = authorityIssuerArray.length;
        for (uint index = 0; index < datasetLength; index++) {
            if (authorityIssuerArray[index] == addr) { 
                break; 
            }
        } 
        if (index != datasetLength-1) {
            authorityIssuerArray[index] = authorityIssuerArray[datasetLength-1];
        }
        delete authorityIssuerArray[datasetLength-1];
        authorityIssuerArray.length--;
        return RETURN_CODE_SUCCESS;
    }

    function getDatasetLength() 
        public 
        constant 
        returns (uint) 
    {
        return authorityIssuerArray.length;
    }

    function getAuthorityIssuerFromIndex(
        uint index
    ) 
        public 
        constant 
        returns (address) 
    {
        return authorityIssuerArray[index];
    }

    function getAuthorityIssuerInfoNonAccValue(
        address addr
    )
        public
        constant
        returns (bytes32[16], int[16])
    {
        bytes32[16] memory allBytes32;
        int[16] memory allInt;
        for (uint index = 0; index < 16; index++) {
            allBytes32[index] = authorityIssuerMap[addr].attribBytes32[index];
            allInt[index] = authorityIssuerMap[addr].attribInt[index];
        }
        return (allBytes32, allInt);
    }

    function getAuthorityIssuerInfoAccValue(
        address addr
    ) 
        public 
        constant 
        returns (bytes) 
    {
        return authorityIssuerMap[addr].accValue;
    }

    function isNameDuplicate(
        bytes32 name
    )
        public
        constant
        returns (bool) 
    {
        if (uniqueNameMap[name] == address(0x0)) {
            return false;
        }
        return true;
    }

    function getAddressFromName(
        bytes32 name
    )
        public
        constant
        returns (address)
    {
        return uniqueNameMap[name];
    }

    function getRecognizedIssuerCount() 
        public 
        constant 
        returns (uint) 
    {
        return recognizedIssuerCount;
    }
}

contract CptData {
    // CPT ID has been categorized into 3 zones: 0 - 999 are reserved for system CPTs,
    //  1000-2000000 for Authority Issuer's CPTs, and the rest for common WeIdentiy DIDs.
    uint constant public AUTHORITY_ISSUER_START_ID = 1000;
    uint constant public NONE_AUTHORITY_ISSUER_START_ID = 2000000;
    uint private authority_issuer_current_id = 1000;
    uint private none_authority_issuer_current_id = 2000000;

    AuthorityIssuerData private authorityIssuerData;

    function CptData(
        address authorityIssuerDataAddress
    ) 
        public
    {
        authorityIssuerData = AuthorityIssuerData(authorityIssuerDataAddress);
    }

    struct Signature {
        uint8 v; 
        bytes32 r; 
        bytes32 s;
    }

    struct Cpt {
        //store the weid address of cpt publisher
        address publisher;
        // [0]: cpt version, [1]: created, [2]: updated, [3]: the CPT ID
        int[8] intArray;
        // [0]: desc
        bytes32[8] bytes32Array;
        //store json schema
        bytes32[128] jsonSchemaArray;
        //store signature
        Signature signature;
    }

    mapping (uint => Cpt) private cptMap;
    uint[] private cptIdList;

    function putCpt(
        uint cptId, 
        address cptPublisher, 
        int[8] cptIntArray, 
        bytes32[8] cptBytes32Array,
        bytes32[128] cptJsonSchemaArray, 
        uint8 cptV, 
        bytes32 cptR, 
        bytes32 cptS
    ) 
        public 
        returns (bool) 
    {
        Signature memory cptSignature = Signature({v: cptV, r: cptR, s: cptS});
        cptMap[cptId] = Cpt({publisher: cptPublisher, intArray: cptIntArray, bytes32Array: cptBytes32Array, jsonSchemaArray:cptJsonSchemaArray, signature: cptSignature});
        cptIdList.push(cptId);
        return true;
    }

    function getCptId(
        address publisher
    ) 
        public 
        constant
        returns 
        (uint cptId)
    {
        if (authorityIssuerData.isAuthorityIssuer(publisher)) {
            while (isCptExist(authority_issuer_current_id)) {
                authority_issuer_current_id++;
            }
            cptId = authority_issuer_current_id++;
            if (cptId >= NONE_AUTHORITY_ISSUER_START_ID) {
                cptId = 0;
            }
        } else {
            while (isCptExist(none_authority_issuer_current_id)) {
                none_authority_issuer_current_id++;
            }
            cptId = none_authority_issuer_current_id++;
        }
    }

    function getCpt(
        uint cptId
    ) 
        public 
        constant 
        returns (
        address publisher, 
        int[8] intArray, 
        bytes32[8] bytes32Array,
        bytes32[128] jsonSchemaArray, 
        uint8 v, 
        bytes32 r, 
        bytes32 s) 
    {
        Cpt memory cpt = cptMap[cptId];
        publisher = cpt.publisher;
        intArray = cpt.intArray;
        bytes32Array = cpt.bytes32Array;
        jsonSchemaArray = cpt.jsonSchemaArray;
        v = cpt.signature.v;
        r = cpt.signature.r;
        s = cpt.signature.s;
    } 

    function getCptPublisher(
        uint cptId
    ) 
        public 
        constant 
        returns (address publisher)
    {
        Cpt memory cpt = cptMap[cptId];
        publisher = cpt.publisher;
    }

    function getCptIntArray(
        uint cptId
    ) 
        public 
        constant 
        returns (int[8] intArray)
    {
        Cpt memory cpt = cptMap[cptId];
        intArray = cpt.intArray;
    }

    function getCptJsonSchemaArray(
        uint cptId
    ) 
        public 
        constant 
        returns (bytes32[128] jsonSchemaArray)
    {
        Cpt memory cpt = cptMap[cptId];
        jsonSchemaArray = cpt.jsonSchemaArray;
    }

    function getCptBytes32Array(
        uint cptId
    ) 
        public 
        constant 
        returns (bytes32[8] bytes32Array)
    {
        Cpt memory cpt = cptMap[cptId];
        bytes32Array = cpt.bytes32Array;
    }

    function getCptSignature(
        uint cptId
    ) 
        public 
        constant 
        returns (uint8 v, bytes32 r, bytes32 s) 
    {
        Cpt memory cpt = cptMap[cptId];
        v = cpt.signature.v;
        r = cpt.signature.r;
        s = cpt.signature.s;
    }

    function isCptExist(
        uint cptId
    ) 
        public 
        constant 
        returns (bool)
    {
        int[8] memory intArray = getCptIntArray(cptId);
        if (intArray[0] != 0) {
            return true;
        } else {
            return false;
        }
    }

    function getDatasetLength() public constant returns (uint) {
        return cptIdList.length;
    }

    function getCptIdFromIndex(uint index) public constant returns (uint) {
        return cptIdList[index];
    }
}
contract WeIdContract {

    RoleController private roleController;

    mapping(address => uint) changed;

    uint firstBlockNum;

    uint lastBlockNum;
    
    uint weIdCount = 0;

    mapping(uint => uint) blockAfterLink;

    modifier onlyOwner(address identity, address actor) {
        require (actor == identity);
        _;
    }

    bytes32 constant private WEID_KEY_CREATED = "created";
    bytes32 constant private WEID_KEY_AUTHENTICATION = "/weId/auth";

    // Constructor - Role controller is required in delegate calls
    function WeIdContract(
        address roleControllerAddress
    )
        public
    {
        roleController = RoleController(roleControllerAddress);
        firstBlockNum = block.number;
        lastBlockNum = firstBlockNum;
    }

    event WeIdAttributeChanged(
        address indexed identity,
        bytes32 key,
        bytes value,
        uint previousBlock,
        int updated
    );

    event WeIdHistoryEvent(
        address indexed identity,
        uint previousBlock,
        int created
    );

    function getLatestRelatedBlock(
        address identity
    ) 
        public 
        constant 
        returns (uint) 
    {
        return changed[identity];
    }

    function getFirstBlockNum() 
        public 
        constant 
        returns (uint) 
    {
        return firstBlockNum;
    }

    function getLatestBlockNum() 
        public 
        constant 
        returns (uint) 
    {
        return lastBlockNum;
    }

    function getNextBlockNumByBlockNum(uint currentBlockNum) 
        public 
        constant 
        returns (uint) 
    {
        return blockAfterLink[currentBlockNum];
    }

    function getWeIdCount() 
        public 
        constant 
        returns (uint) 
    {
        return weIdCount;
    }

    function createWeId(
        address identity,
        bytes auth,
        bytes created,
        int updated
    )
        public
        onlyOwner(identity, msg.sender)
    {
        WeIdAttributeChanged(identity, WEID_KEY_CREATED, created, changed[identity], updated);
        WeIdAttributeChanged(identity, WEID_KEY_AUTHENTICATION, auth, changed[identity], updated);
        changed[identity] = block.number;
        if (block.number > lastBlockNum) {
            blockAfterLink[lastBlockNum] = block.number;
        }
        WeIdHistoryEvent(identity, lastBlockNum, updated);
        if (block.number > lastBlockNum) {
            lastBlockNum = block.number;
        }
        weIdCount++;
    }

    function delegateCreateWeId(
        address identity,
        bytes auth,
        bytes created,
        int updated
    )
        public
    {
        if (roleController.checkPermission(msg.sender, roleController.MODIFY_AUTHORITY_ISSUER())) {
            WeIdAttributeChanged(identity, WEID_KEY_CREATED, created, changed[identity], updated);
            WeIdAttributeChanged(identity, WEID_KEY_AUTHENTICATION, auth, changed[identity], updated);
            changed[identity] = block.number;
            if (block.number > lastBlockNum) {
                blockAfterLink[lastBlockNum] = block.number;
            }
            WeIdHistoryEvent(identity, lastBlockNum, updated);
            if (block.number > lastBlockNum) {
                lastBlockNum = block.number;
            }
            weIdCount++;
        }
    }

    function setAttribute(
        address identity, 
        bytes32 key, 
        bytes value, 
        int updated
    ) 
        public 
        onlyOwner(identity, msg.sender)
    {
        WeIdAttributeChanged(identity, key, value, changed[identity], updated);
        changed[identity] = block.number;
    }

    function delegateSetAttribute(
        address identity,
        bytes32 key,
        bytes value,
        int updated
    )
        public
    {
        if (roleController.checkPermission(msg.sender, roleController.MODIFY_AUTHORITY_ISSUER())) {
            WeIdAttributeChanged(identity, key, value, changed[identity], updated);
            changed[identity] = block.number;
        }
    }

    function isIdentityExist(
        address identity
    ) 
        public 
        constant 
        returns (bool) 
    {
        if (0x0 != identity && 0 != changed[identity]) {
            return true;
    }
        return false;
    }
}


contract RoleController {

    /**
     * The universal NO_PERMISSION error code.
     */
    uint constant public RETURN_CODE_FAILURE_NO_PERMISSION = 500000;

    /**
     * Role related Constants.
     */
    uint constant public ROLE_AUTHORITY_ISSUER = 100;
    uint constant public ROLE_COMMITTEE = 101;
    uint constant public ROLE_ADMIN = 102;

    /**
     * Operation related Constants.
     */
    uint constant public MODIFY_AUTHORITY_ISSUER = 200;
    uint constant public MODIFY_COMMITTEE = 201;
    uint constant public MODIFY_ADMIN = 202;
    uint constant public MODIFY_KEY_CPT = 203;

    mapping (address => bool) private authorityIssuerRoleBearer;
    mapping (address => bool) private committeeMemberRoleBearer;
    mapping (address => bool) private adminRoleBearer;

    function RoleController() public {
        authorityIssuerRoleBearer[msg.sender] = true;
        adminRoleBearer[msg.sender] = true;
        committeeMemberRoleBearer[msg.sender] = true;
    }

    /**
     * Public common checkPermission logic.
     */
    function checkPermission(
        address addr,
        uint operation
    ) 
        public 
        constant 
        returns (bool) 
    {
        if (operation == MODIFY_AUTHORITY_ISSUER) {
            if (adminRoleBearer[addr] || committeeMemberRoleBearer[addr]) {
                return true;
            }
        }
        if (operation == MODIFY_COMMITTEE) {
            if (adminRoleBearer[addr]) {
                return true;
            }
        }
        if (operation == MODIFY_ADMIN) {
            if (adminRoleBearer[addr]) {
                return true;
            }
        }
        if (operation == MODIFY_KEY_CPT) {
            if (authorityIssuerRoleBearer[addr]) {
                return true;
            }
        }
        return false;
    }

    /**
     * Add Role.
     */
    function addRole(
        address addr,
        uint role
    ) 
        public 
    {
        if (role == ROLE_AUTHORITY_ISSUER) {
            if (checkPermission(tx.origin, MODIFY_AUTHORITY_ISSUER)) {
                authorityIssuerRoleBearer[addr] = true;
            }
        }
        if (role == ROLE_COMMITTEE) {
            if (checkPermission(tx.origin, MODIFY_COMMITTEE)) {
                committeeMemberRoleBearer[addr] = true;
            }
        }
        if (role == ROLE_ADMIN) {
            if (checkPermission(tx.origin, MODIFY_ADMIN)) {
                adminRoleBearer[addr] = true;
            }
        }
    }

    /**
     * Remove Role.
     */
    function removeRole(
        address addr,
        uint role
    ) 
        public 
    {
        if (role == ROLE_AUTHORITY_ISSUER) {
            if (checkPermission(tx.origin, MODIFY_AUTHORITY_ISSUER)) {
                authorityIssuerRoleBearer[addr] = false;
            }
        }
        if (role == ROLE_COMMITTEE) {
            if (checkPermission(tx.origin, MODIFY_COMMITTEE)) {
                committeeMemberRoleBearer[addr] = false;
            }
        }
        if (role == ROLE_ADMIN) {
            if (checkPermission(tx.origin, MODIFY_ADMIN)) {
                adminRoleBearer[addr] = false;
            }
        }
    }

    /**
     * Check Role.
     */
    function checkRole(
        address addr,
        uint role
    ) 
        public 
        constant 
        returns (bool) 
    {
        if (role == ROLE_AUTHORITY_ISSUER) {
            return authorityIssuerRoleBearer[addr];
        }
        if (role == ROLE_COMMITTEE) {
            return committeeMemberRoleBearer[addr];
        }
        if (role == ROLE_ADMIN) {
            return adminRoleBearer[addr];
        }
    }
}


contract CptController {

    // Error codes
    uint constant private CPT_NOT_EXIST = 500301;
    uint constant private AUTHORITY_ISSUER_CPT_ID_EXCEED_MAX = 500302;
    uint constant private CPT_PUBLISHER_NOT_EXIST = 500303;
    uint constant private CPT_ALREADY_EXIST = 500304;
    uint constant private NO_PERMISSION = 500305;

    // Default CPT version
    int constant private CPT_DEFAULT_VERSION = 1;

    WeIdContract private weIdContract;
    RoleController private roleController;

    // Reserved for contract owner check
    address private internalRoleControllerAddress;
    address private owner;

    // CPT and Policy data storage address separately
    address private cptDataStorageAddress;
    address private policyDataStorageAddress;

    function CptController(
        address cptDataAddress,
        address weIdContractAddress
    ) 
        public
    {
        owner = msg.sender;
        weIdContract = WeIdContract(weIdContractAddress);
        cptDataStorageAddress = cptDataAddress;
    }

    function setPolicyData(
        address policyDataAddress
    )
        public
    {
        if (msg.sender != owner || policyDataAddress == 0x0) {
            return;
        }
        policyDataStorageAddress = policyDataAddress;
    }

    function setRoleController(
        address roleControllerAddress
    )
        public
    {
        if (msg.sender != owner || roleControllerAddress == 0x0) {
            return;
        }
        roleController = RoleController(roleControllerAddress);
        if (roleController.ROLE_ADMIN() <= 0) {
            return;
        }
        internalRoleControllerAddress = roleControllerAddress;
    }

    event RegisterCptRetLog(
        uint retCode, 
        uint cptId, 
        int cptVersion
    );

    event UpdateCptRetLog(
        uint retCode, 
        uint cptId, 
        int cptVersion
    );

    function registerCptInner(
        uint cptId,
        address publisher, 
        int[8] intArray, 
        bytes32[8] bytes32Array,
        bytes32[128] jsonSchemaArray, 
        uint8 v, 
        bytes32 r, 
        bytes32 s,
        address dataStorageAddress
    )
        private
        returns (bool)
    {
        if (!weIdContract.isIdentityExist(publisher)) {
            RegisterCptRetLog(CPT_PUBLISHER_NOT_EXIST, 0, 0);
            return false;
        }
        CptData cptData = CptData(dataStorageAddress);
        if (cptData.isCptExist(cptId)) {
            RegisterCptRetLog(CPT_ALREADY_EXIST, cptId, 0);
            return false;
        }

        // Authority related checks. We use tx.origin here to decide the authority. For SDK
        // calls, publisher and tx.origin are normally the same. For DApp calls, tx.origin dictates.
        uint lowId = cptData.AUTHORITY_ISSUER_START_ID();
        uint highId = cptData.NONE_AUTHORITY_ISSUER_START_ID();
        if (cptId < lowId) {
            // Only committee member can create this, check initialization first
            if (internalRoleControllerAddress == 0x0) {
                RegisterCptRetLog(NO_PERMISSION, cptId, 0);
                return false;
            }
            if (!roleController.checkPermission(tx.origin, roleController.MODIFY_AUTHORITY_ISSUER())) {
                RegisterCptRetLog(NO_PERMISSION, cptId, 0);
                return false;
            }
        } else if (cptId < highId) {
            // Only authority issuer can create this, check initialization first
            if (internalRoleControllerAddress == 0x0) {
                RegisterCptRetLog(NO_PERMISSION, cptId, 0);
                return false;
            }
            if (!roleController.checkPermission(tx.origin, roleController.MODIFY_KEY_CPT())) {
                RegisterCptRetLog(NO_PERMISSION, cptId, 0);
                return false;
            }
        }

        intArray[0] = CPT_DEFAULT_VERSION;
        cptData.putCpt(cptId, publisher, intArray, bytes32Array, jsonSchemaArray, v, r, s);

        RegisterCptRetLog(0, cptId, CPT_DEFAULT_VERSION);
        return true;
    }

    function registerCpt(
        uint cptId,
        address publisher, 
        int[8] intArray, 
        bytes32[8] bytes32Array,
        bytes32[128] jsonSchemaArray, 
        uint8 v, 
        bytes32 r, 
        bytes32 s
    )
        public
        returns (bool)
    {
        return registerCptInner(cptId, publisher, intArray, bytes32Array, jsonSchemaArray, v, r, s, cptDataStorageAddress);
    }

    function registerPolicy(
        uint cptId,
        address publisher, 
        int[8] intArray, 
        bytes32[8] bytes32Array,
        bytes32[128] jsonSchemaArray, 
        uint8 v, 
        bytes32 r, 
        bytes32 s
    )
        public
        returns (bool)
    {
        return registerCptInner(cptId, publisher, intArray, bytes32Array, jsonSchemaArray, v, r, s, policyDataStorageAddress);
    }

    function registerCptInner(
        address publisher, 
        int[8] intArray, 
        bytes32[8] bytes32Array,
        bytes32[128] jsonSchemaArray, 
        uint8 v, 
        bytes32 r, 
        bytes32 s,
        address dataStorageAddress
    ) 
        private 
        returns (bool) 
    {
        if (!weIdContract.isIdentityExist(publisher)) {
            RegisterCptRetLog(CPT_PUBLISHER_NOT_EXIST, 0, 0);
            return false;
        }
        CptData cptData = CptData(dataStorageAddress);

        uint cptId = cptData.getCptId(publisher); 
        if (cptId == 0) {
            RegisterCptRetLog(AUTHORITY_ISSUER_CPT_ID_EXCEED_MAX, 0, 0);
            return false;
        }
        int cptVersion = CPT_DEFAULT_VERSION;
        intArray[0] = cptVersion;
        cptData.putCpt(cptId, publisher, intArray, bytes32Array, jsonSchemaArray, v, r, s);

        RegisterCptRetLog(0, cptId, cptVersion);
        return true;
    }

    function registerCpt(
        address publisher, 
        int[8] intArray, 
        bytes32[8] bytes32Array,
        bytes32[128] jsonSchemaArray, 
        uint8 v, 
        bytes32 r, 
        bytes32 s
    ) 
        public 
        returns (bool) 
    {
        return registerCptInner(publisher, intArray, bytes32Array, jsonSchemaArray, v, r, s, cptDataStorageAddress);
    }

    function registerPolicy(
        address publisher, 
        int[8] intArray, 
        bytes32[8] bytes32Array,
        bytes32[128] jsonSchemaArray, 
        uint8 v, 
        bytes32 r, 
        bytes32 s
    ) 
        public 
        returns (bool) 
    {
        return registerCptInner(publisher, intArray, bytes32Array, jsonSchemaArray, v, r, s, policyDataStorageAddress);
    }

    function updateCptInner(
        uint cptId, 
        address publisher, 
        int[8] intArray, 
        bytes32[8] bytes32Array,
        bytes32[128] jsonSchemaArray, 
        uint8 v, 
        bytes32 r, 
        bytes32 s,
        address dataStorageAddress
    ) 
        private 
        returns (bool) 
    {
        if (!weIdContract.isIdentityExist(publisher)) {
            UpdateCptRetLog(CPT_PUBLISHER_NOT_EXIST, 0, 0);
            return false;
        }
        CptData cptData = CptData(dataStorageAddress);
        if (!roleController.checkPermission(tx.origin, roleController.MODIFY_AUTHORITY_ISSUER())
            && publisher != cptData.getCptPublisher(cptId)) {
            UpdateCptRetLog(NO_PERMISSION, 0, 0);
            return false;
        }
        if (cptData.isCptExist(cptId)) {
            int[8] memory cptIntArray = cptData.getCptIntArray(cptId);
            int cptVersion = cptIntArray[0] + 1;
            intArray[0] = cptVersion;
            int created = cptIntArray[1];
            intArray[1] = created;
            cptData.putCpt(cptId, publisher, intArray, bytes32Array, jsonSchemaArray, v, r, s);
            UpdateCptRetLog(0, cptId, cptVersion);
            return true;
        } else {
            UpdateCptRetLog(CPT_NOT_EXIST, 0, 0);
            return false;
        }
    }

    function updateCpt(
        uint cptId, 
        address publisher, 
        int[8] intArray, 
        bytes32[8] bytes32Array,
        bytes32[128] jsonSchemaArray, 
        uint8 v, 
        bytes32 r, 
        bytes32 s
    )
        public
        returns (bool)
    {
        return updateCptInner(cptId, publisher, intArray, bytes32Array, jsonSchemaArray, v, r, s, cptDataStorageAddress);
    }

    function updatePolicy(
        uint cptId, 
        address publisher, 
        int[8] intArray, 
        bytes32[8] bytes32Array,
        bytes32[128] jsonSchemaArray, 
        uint8 v, 
        bytes32 r, 
        bytes32 s
    )
        public
        returns (bool)
    {
        return updateCptInner(cptId, publisher, intArray, bytes32Array, jsonSchemaArray, v, r, s, policyDataStorageAddress);
    }

    function queryCptInner(
        uint cptId,
        address dataStorageAddress
    ) 
        private 
        constant 
        returns (
        address publisher, 
        int[] intArray, 
        bytes32[] bytes32Array,
        bytes32[] jsonSchemaArray, 
        uint8 v, 
        bytes32 r, 
        bytes32 s)
    {
        CptData cptData = CptData(dataStorageAddress);
        publisher = cptData.getCptPublisher(cptId);
        intArray = getCptDynamicIntArray(cptId, dataStorageAddress);
        bytes32Array = getCptDynamicBytes32Array(cptId, dataStorageAddress);
        jsonSchemaArray = getCptDynamicJsonSchemaArray(cptId, dataStorageAddress);
        (v, r, s) = cptData.getCptSignature(cptId);
    }

    function queryCpt(
        uint cptId
    ) 
        public 
        constant 
        returns 
    (
        address publisher, 
        int[] intArray, 
        bytes32[] bytes32Array,
        bytes32[] jsonSchemaArray, 
        uint8 v, 
        bytes32 r, 
        bytes32 s)
    {
        return queryCptInner(cptId, cptDataStorageAddress);
    }

    function queryPolicy(
        uint cptId
    ) 
        public 
        constant 
        returns 
    (
        address publisher, 
        int[] intArray, 
        bytes32[] bytes32Array,
        bytes32[] jsonSchemaArray, 
        uint8 v, 
        bytes32 r, 
        bytes32 s)
    {
        return queryCptInner(cptId, policyDataStorageAddress);
    }

    function getCptDynamicIntArray(
        uint cptId,
        address dataStorageAddress
    ) 
        public
        constant 
        returns (int[])
    {
        CptData cptData = CptData(dataStorageAddress);
        int[8] memory staticIntArray = cptData.getCptIntArray(cptId);
        int[] memory dynamicIntArray = new int[](8);
        for (uint i = 0; i < 8; i++) {
            dynamicIntArray[i] = staticIntArray[i];
        }
        return dynamicIntArray;
    }

    function getCptDynamicBytes32Array(
        uint cptId,
        address dataStorageAddress
    ) 
        public 
        constant 
        returns (bytes32[])
    {
        CptData cptData = CptData(dataStorageAddress);
        bytes32[8] memory staticBytes32Array = cptData.getCptBytes32Array(cptId);
        bytes32[] memory dynamicBytes32Array = new bytes32[](8);
        for (uint i = 0; i < 8; i++) {
            dynamicBytes32Array[i] = staticBytes32Array[i];
        }
        return dynamicBytes32Array;
    }

    function getCptDynamicJsonSchemaArray(
        uint cptId,
        address dataStorageAddress
    ) 
        public 
        constant 
        returns (bytes32[])
    {
        CptData cptData = CptData(dataStorageAddress);
        bytes32[128] memory staticBytes32Array = cptData.getCptJsonSchemaArray(cptId);
        bytes32[] memory dynamicBytes32Array = new bytes32[](128);
        for (uint i = 0; i < 128; i++) {
            dynamicBytes32Array[i] = staticBytes32Array[i];
        }
        return dynamicBytes32Array;
    }

    function getPolicyIdList(uint startPos, uint num)
        public
        constant
        returns (uint[])
    {
        CptData cptData = CptData(policyDataStorageAddress);
        uint totalLength = cptData.getDatasetLength();
        uint dataLength;
        if (totalLength < startPos) {
            return new uint[](1);
        } else if (totalLength <= startPos + num) {
            dataLength = totalLength - startPos;
        } else {
            dataLength = num;
        }
        uint[] memory result = new uint[](dataLength);
        for (uint i = 0; i < dataLength; i++) {
            result[i] = cptData.getCptIdFromIndex(startPos + i);
        }
        return result;
    }

    function getCptIdList(uint startPos, uint num)
        public
        constant
        returns (uint[])
    {
        CptData cptData = CptData(cptDataStorageAddress);
        uint totalLength = cptData.getDatasetLength();
        uint dataLength;
        if (totalLength < startPos) {
            return new uint[](1);
        } else if (totalLength <= startPos + num) {
            dataLength = totalLength - startPos;
        } else {
            dataLength = num;
        }
        uint[] memory result = new uint[](dataLength);
        for (uint i = 0; i < dataLength; i++) {
            result[i] = cptData.getCptIdFromIndex(startPos + i);
        }
        return result;
    }

    function getTotalCptId() public constant returns (uint) {
        CptData cptData = CptData(cptDataStorageAddress);
        return cptData.getDatasetLength();
    }

    function getTotalPolicyId() public constant returns (uint) {
        CptData cptData = CptData(policyDataStorageAddress);
        return cptData.getDatasetLength();
    }

    // --------------------------------------------------------
    // Credential Template storage related funcs
    // store the cptId and blocknumber
    mapping (uint => uint) credentialTemplateStored;
    event CredentialTemplate(
        uint cptId,
        bytes credentialPublicKey,
        bytes credentialProof
    );

    function putCredentialTemplate(
        uint cptId,
        bytes credentialPublicKey,
        bytes credentialProof
    )
        public
    {
        CredentialTemplate(cptId, credentialPublicKey, credentialProof);
        credentialTemplateStored[cptId] = block.number;
    }

    function getCredentialTemplateBlock(
        uint cptId
    )
        public
        constant
        returns(uint)
    {
        return credentialTemplateStored[cptId];
    }

    // --------------------------------------------------------
    // Claim Policy storage belonging to v.s. Presentation, Publisher WeID, and CPT
    // Store the registered Presentation Policy ID (uint) v.s. Claim Policy ID list (uint[])
    mapping (uint => uint[]) private claimPoliciesFromPresentation;
    mapping (uint => address) private claimPoliciesWeIdFromPresentation;
    // Store the registered CPT ID (uint) v.s. Claim Policy ID list (uint[])
    mapping (uint => uint[]) private claimPoliciesFromCPT;

    uint private presentationClaimMapId = 1;

    function putClaimPoliciesIntoPresentationMap(uint[] uintArray) public {
        claimPoliciesFromPresentation[presentationClaimMapId] = uintArray;
        claimPoliciesWeIdFromPresentation[presentationClaimMapId] = msg.sender;
        RegisterCptRetLog(0, presentationClaimMapId, CPT_DEFAULT_VERSION);
        presentationClaimMapId ++;
    }

    function getClaimPoliciesFromPresentationMap(uint presentationId) public constant returns (uint[], address) {
        return (claimPoliciesFromPresentation[presentationId], claimPoliciesWeIdFromPresentation[presentationId]);
    }
    
    function putClaimPoliciesIntoCptMap(uint cptId, uint[] uintArray) public {
        claimPoliciesFromCPT[cptId] = uintArray;
        RegisterCptRetLog(0, cptId, CPT_DEFAULT_VERSION);
    }
    
    function getClaimPoliciesFromCptMap(uint cptId) public constant returns (uint[]) {
        return claimPoliciesFromCPT[cptId];
    }
}
