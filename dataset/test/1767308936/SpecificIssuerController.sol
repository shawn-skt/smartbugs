pragma solidity ^0.4.4;
/*
 *       Copyright© (2019) WeBank Co., Ltd.
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

contract SpecificIssuerData {

    // Error codes
    uint constant private RETURN_CODE_SUCCESS = 0;
    uint constant private RETURN_CODE_FAILURE_ALREADY_EXISTS = 500501;
    uint constant private RETURN_CODE_FAILURE_NOT_EXIST = 500502;
    uint constant private RETURN_CODE_FAILURE_EXCEED_MAX = 500503;
    uint constant private RETURN_CODE_FAILURE_NO_PERMISSION = 500000;
    uint constant private RETURN_CODE_FAILURE_DEL_EXIST_ISSUER = 500504;

    struct IssuerType {
        // typeName as index, dynamic array as getAt function and mapping as search
        bytes32 typeName;
        address[] fellow;
        mapping (address => bool) isFellow;
        bytes32[8] extra;
        address owner;
        uint256 created;
    }

    mapping (bytes32 => IssuerType) private issuerTypeMap;
    bytes32[] private typeNameArray;

    function registerIssuerType(bytes32 typeName) public returns (uint) {
        if (isIssuerTypeExist(typeName)) {
            return RETURN_CODE_FAILURE_ALREADY_EXISTS;
        }
        address[] memory fellow;
        bytes32[8] memory extra;
        IssuerType memory issuerType = IssuerType(typeName, fellow, extra, tx.origin, now);
        issuerTypeMap[typeName] = issuerType;
        typeNameArray.push(typeName);
        return RETURN_CODE_SUCCESS;
    }

    function removeIssuerType(bytes32 typeName) public returns (uint) {
        if (!isIssuerTypeExist(typeName)) {
            return RETURN_CODE_FAILURE_NOT_EXIST;
        }
        if (issuerTypeMap[typeName].fellow.length != 0) {
            return RETURN_CODE_FAILURE_DEL_EXIST_ISSUER;
        }
        if (issuerTypeMap[typeName].owner != tx.origin) {
            return RETURN_CODE_FAILURE_NO_PERMISSION;
        }
        delete issuerTypeMap[typeName];
        uint datasetLength = typeNameArray.length;
        for (uint index = 0; index < datasetLength; index++) {
            if (typeNameArray[index] == typeName) {
                break;
            }
        }
        if (index != datasetLength-1) {
            typeNameArray[index] = typeNameArray[datasetLength-1];
        }
        delete typeNameArray[datasetLength-1];
        typeNameArray.length--;
        return RETURN_CODE_SUCCESS;
    }

    function getTypeNameSize() public returns (uint) {
        return typeNameArray.length;
    }

    function getTypInfoByIndex(uint index) public returns (bytes32, address, uint256) {
      bytes32 typeName = typeNameArray[index];
      IssuerType memory issuerType = issuerTypeMap[typeName];
      return (typeName, issuerType.owner, issuerType.created);
    }

    function addExtraValue(bytes32 typeName, bytes32 extraValue) public returns (uint) {
        if (!isIssuerTypeExist(typeName)) {
            return RETURN_CODE_FAILURE_NOT_EXIST;
        }
        IssuerType storage issuerType = issuerTypeMap[typeName];
        for (uint index = 0; index < 8; index++) {
            if (issuerType.extra[index] == bytes32(0)) {
                issuerType.extra[index] = extraValue;
                break;
            }
        }
        if (index == 8) {
            return RETURN_CODE_FAILURE_EXCEED_MAX;
        }
        return RETURN_CODE_SUCCESS;
    }

    function getExtraValue(bytes32 typeName) public constant returns (bytes32[8]) {
        bytes32[8] memory extraValues;
        if (!isIssuerTypeExist(typeName)) {
            return extraValues;
        }
        IssuerType memory issuerType = issuerTypeMap[typeName];
        for (uint index = 0; index < 8; index++) {
            extraValues[index] = issuerType.extra[index];
        }
        return extraValues;
    }

    function isIssuerTypeExist(bytes32 name) public constant returns (bool) {
        if (issuerTypeMap[name].typeName == bytes32(0)) {
            return false;
        }
        return true;
    }

    function addIssuer(bytes32 typeName, address addr) public returns (uint) {
        if (isSpecificTypeIssuer(typeName, addr)) {
            return RETURN_CODE_FAILURE_ALREADY_EXISTS;
        }
        if (!isIssuerTypeExist(typeName)) {
            return RETURN_CODE_FAILURE_NOT_EXIST;
        }
        issuerTypeMap[typeName].fellow.push(addr);
        issuerTypeMap[typeName].isFellow[addr] = true;
        return RETURN_CODE_SUCCESS;
    }

    function removeIssuer(bytes32 typeName, address addr) public returns (uint) {
        if (!isSpecificTypeIssuer(typeName, addr) || !isIssuerTypeExist(typeName)) {
            return RETURN_CODE_FAILURE_NOT_EXIST;
        }
        address[] memory fellow = issuerTypeMap[typeName].fellow;
        uint dataLength = fellow.length;
        for (uint index = 0; index < dataLength; index++) {
            if (addr == fellow[index]) {
                break;
            }
        }
        if (index != dataLength-1) {
            issuerTypeMap[typeName].fellow[index] = issuerTypeMap[typeName].fellow[dataLength-1];
        }
        delete issuerTypeMap[typeName].fellow[dataLength-1];
        issuerTypeMap[typeName].fellow.length--;
        issuerTypeMap[typeName].isFellow[addr] = false;
        return RETURN_CODE_SUCCESS;
    }

    function isSpecificTypeIssuer(bytes32 typeName, address addr) public constant returns (bool) {
        if (issuerTypeMap[typeName].isFellow[addr] == false) {
            return false;
        }
        return true;
    }

    function getSpecificTypeIssuers(bytes32 typeName, uint startPos) public constant returns (address[50]) {
        address[50] memory fellow;
        if (!isIssuerTypeExist(typeName)) {
            return fellow;
        }

        // Calculate actual dataLength via batch return for better perf
        uint totalLength = getSpecificTypeIssuerLength(typeName);
        uint dataLength;
        if (totalLength < startPos) {
            return fellow;
        } else if (totalLength <= startPos + 50) {
            dataLength = totalLength - startPos;
        } else {
            dataLength = 50;
        }

        // dynamic -> static array data copy
        for (uint index = 0; index < dataLength; index++) {
            fellow[index] = issuerTypeMap[typeName].fellow[index + startPos];
        }
        return fellow;
    }

    function getSpecificTypeIssuerLength(bytes32 typeName) public constant returns (uint) {
        if (!isIssuerTypeExist(typeName)) {
            return 0;
        }
        return issuerTypeMap[typeName].fellow.length;
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


/**
 * @title SpecificIssuerController
 * Controller contract managing issuers with specific types info.
 */

contract SpecificIssuerController {

    SpecificIssuerData private specificIssuerData;
    RoleController private roleController;

    // Event structure to store tx records
    uint constant private OPERATION_ADD = 0;
    uint constant private OPERATION_REMOVE = 1;

    event SpecificIssuerRetLog(uint operation, uint retCode, bytes32 typeName, address addr);

    // Constructor.
    function SpecificIssuerController(
        address specificIssuerDataAddress,
        address roleControllerAddress
    )
        public
    {
        specificIssuerData = SpecificIssuerData(specificIssuerDataAddress);
        roleController = RoleController(roleControllerAddress);
    }

    function registerIssuerType(bytes32 typeName) public {
        uint result = specificIssuerData.registerIssuerType(typeName);
        SpecificIssuerRetLog(OPERATION_ADD, result, typeName, 0x0);
    }

    function isIssuerTypeExist(bytes32 typeName) public constant returns (bool) {
        return specificIssuerData.isIssuerTypeExist(typeName);
    }

    function addIssuer(bytes32 typeName, address addr) public {
        if (!roleController.checkPermission(tx.origin, roleController.MODIFY_KEY_CPT())) {
            SpecificIssuerRetLog(OPERATION_ADD, roleController.RETURN_CODE_FAILURE_NO_PERMISSION(), typeName, addr);
            return;
        }
        uint result = specificIssuerData.addIssuer(typeName, addr);
        SpecificIssuerRetLog(OPERATION_ADD, result, typeName, addr);
    }

    function removeIssuer(bytes32 typeName, address addr) public {
        if (!roleController.checkPermission(tx.origin, roleController.MODIFY_KEY_CPT())) {
            SpecificIssuerRetLog(OPERATION_REMOVE, roleController.RETURN_CODE_FAILURE_NO_PERMISSION(), typeName, addr);
            return;
        }
        uint result = specificIssuerData.removeIssuer(typeName, addr);
        SpecificIssuerRetLog(OPERATION_REMOVE, result, typeName, addr);
    }

    function addExtraValue(bytes32 typeName, bytes32 extraValue) public {
        if (!roleController.checkPermission(tx.origin, roleController.MODIFY_KEY_CPT())) {
            SpecificIssuerRetLog(OPERATION_ADD, roleController.RETURN_CODE_FAILURE_NO_PERMISSION(), typeName, 0x0);
            return;
        }
        uint result = specificIssuerData.addExtraValue(typeName, extraValue);
        SpecificIssuerRetLog(OPERATION_ADD, result, typeName, 0x0);
    }

    function getExtraValue(bytes32 typeName) public constant returns (bytes32[]) {
        bytes32[8] memory tempArray = specificIssuerData.getExtraValue(typeName);
        bytes32[] memory resultArray = new bytes32[](8);
        for (uint index = 0; index < 8; index++) {
            resultArray[index] = tempArray[index];
        }
        return resultArray;
    }

    function isSpecificTypeIssuer(bytes32 typeName, address addr) public constant returns (bool) {
        return specificIssuerData.isSpecificTypeIssuer(typeName, addr);
    }

    function getSpecificTypeIssuerList(bytes32 typeName, uint startPos, uint num) public constant returns (address[]) {
        if (num == 0 || !specificIssuerData.isIssuerTypeExist(typeName)) {
            return new address[](50);
        }

        // Calculate actual dataLength via batch return for better perf
        uint totalLength = specificIssuerData.getSpecificTypeIssuerLength(typeName);
        uint dataLength;
        if (totalLength < startPos) {
            return new address[](50);
        } else {
            if (totalLength <= startPos + num) {
                dataLength = totalLength - startPos;
            } else {
                dataLength = num;
            }
        }

        address[] memory resultArray = new address[](dataLength);
        address[50] memory tempArray;
        tempArray = specificIssuerData.getSpecificTypeIssuers(typeName, startPos);
        uint tick;
        if (dataLength <= 50) {
            for (tick = 0; tick < dataLength; tick++) {
                resultArray[tick] = tempArray[tick];
            }
        } else {
            for (tick = 0; tick < 50; tick++) {
                resultArray[tick] = tempArray[tick];
            }
        }
        return resultArray;
    }

    function getSpecificTypeIssuerSize(bytes32 typeName) public constant returns (uint) {
        return specificIssuerData.getSpecificTypeIssuerLength(typeName);
    }

    function getIssuerTypeList(
        uint startPos,
        uint num
    )
        public
        constant
        returns (bytes32[] typeNames, address[] owners, uint256[] createds)
    {
        uint totalLength = specificIssuerData.getTypeNameSize();

        uint dataLength;
        // Calculate actual dataLength
        if (totalLength < startPos) {
          return (new bytes32[](0), new address[](0), new uint256[](0));
        } else if (totalLength <= startPos + num) {
          dataLength = totalLength - startPos;
        } else {
          dataLength = num;
        }

        typeNames = new bytes32[](dataLength);
        owners = new address[](dataLength);
        createds = new uint256[](dataLength);
        for (uint index = 0; index < dataLength; index++) {
          (bytes32 typeName, address owner, uint256 created) = specificIssuerData.getTypInfoByIndex(startPos + index);
          typeNames[index] = typeName;
          owners[index] = owner;
          createds[index] = created;
        }
        return (typeNames, owners, createds);
    }

    function removeIssuerType(bytes32 typeName) public {
        uint result = specificIssuerData.removeIssuerType(typeName);
        SpecificIssuerRetLog(OPERATION_REMOVE, result, typeName, 0x0);
    }

    function getIssuerTypeCount()
        public
        constant
        returns (uint)
    {
        return specificIssuerData.getTypeNameSize();
    }
}

