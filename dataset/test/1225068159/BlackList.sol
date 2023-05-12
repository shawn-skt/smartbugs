// SPDX-License-Identifier: SimPL-2.0
pragma solidity>=0.4.24 <0.6.11;
// pragma experimental ABIEncoderV2;

contract TableFactory {
    function openTable(string memory) public view returns (Table) {} //open table
    function createTable(string memory, string memory, string memory) public returns (int256) {} //create table
}

//select condition
contract Condition {
    function EQ(string memory, int256) public view{}
    function EQ(string memory, string memory) public view{}

    function NE(string memory, int256) public view{}
    function NE(string memory, string memory) public view{}

    function GT(string memory, int256) public view{}
    function GE(string memory, int256) public view{}

    function LT(string memory, int256) public view{}
    function LE(string memory, int256) public view{}

    function limit(int256) public view{}
    function limit(int256, int256) public view{}
}

//one record
contract Entry {
    function getInt(string memory) public view returns (int256) {}
    function getUInt(string memory) public view returns (uint256) {}
    function getAddress(string memory) public view returns (address) {}
    function getBytes64(string memory) public view returns (bytes1[64] memory) {}
    function getBytes32(string memory) public view returns (bytes32) {}
    function getString(string memory) public view returns (string memory) {}

    function set(string memory, int256) public {}
    function set(string memory, uint256) public {}
    function set(string memory, string memory) public {}
    function set(string memory, address) public {}
}

//record sets
contract Entries {
    function get(int256) public view returns (Entry) {}
    function size() public view returns (int256) {}
}

//Table main contract
contract Table {
    function select(string memory, Condition) public view returns (Entries) {}
    function insert(string memory, Entry) public returns (int256) {}
    function update(string memory, Entry, Condition) public returns (int256) {}
    function remove(string memory, Condition) public returns (int256) {}

    function newEntry() public view returns (Entry) {}
    function newCondition() public view returns (Condition) {}
}

contract KVTableFactory {
    function openTable(string memory) public view returns (KVTable) {}
    function createTable(string memory, string memory, string memory) public returns (int256) {}
}

//KVTable per permiary key has only one Entry
contract KVTable {
    function get(string memory) public view returns (bool, Entry) {}
    function set(string memory, Entry) public returns (int256) {}
    function newEntry() public view returns (Entry) {}
}

contract DataFormat{
    // string matching
   function strMatching(string memory v1, string memory v2)
   internal
   pure
   returns(bool)
   {
      return keccak256(bytes(v1)) == keccak256(bytes(v2));
   }

   // string catenate
    function strCat(string memory v1, string memory v2) 
    internal 
    pure
    returns (string memory){
        bytes memory v1Bytes = bytes(v1);
        bytes memory v2Bytes = bytes(v2);

        string memory result = new string(v1Bytes.length + v2Bytes.length);
        bytes memory resultBytes = bytes(result);
      
        uint k = 0;
        uint i = 0;
        for (i = 0; i < v1Bytes.length; i++){
           resultBytes[k++] = v1Bytes[i];
        }
        for (i = 0; i < v2Bytes.length; i++) {
           resultBytes[k++] = v2Bytes[i];
        }
        
        return string(resultBytes);
        
   }


    function strCatWithSymbol(string memory v1, string memory v2) 
    internal
    pure
    returns (string memory) 
    {
      if(true == strMatching("", v1)){
         v1 = v2;
      }
      else{
         v1 = strCat(v1, ",");
         v1 = strCat(v1, v2);
      }
      return v1;
   }
}

contract Blacklist is DataFormat{
   event insertResult(int256 count);
   event updateResult(int256 count);
   event removeResult(int256 count);


   TableFactory tableFactory;

   string constant BLACK_LIST_TABLE_NAME = "blacklist";

   string[] allUserId;

      constructor() public {
      // Set tableFactory address 
      tableFactory = TableFactory(0x1001);

      //
      tableFactory.createTable(BLACK_LIST_TABLE_NAME, "userId", "userState");
   }

    
    // 初始化用户账户状态表;    用户状态默认值 1 ： 正常账户
    // 参数数据格式（userId）    返回值（插入数据条数）
   function initUserState(string memory userId)
   public
   returns(int256)
   {
      Table table = tableFactory.openTable(BLACK_LIST_TABLE_NAME);
      Entry entry = table.newEntry();

      // Set Value
      entry.set("userId", userId);
      entry.set("userState", "1");
     
      int256 count = table.insert(userId, entry);
      emit insertResult(count);

      return count;
   }

   // 更新用户账户状态, 正常 -> 拉黑
   // 参数数据格式（userId）    返回值（更新数据条数）
   function changeUserState(string memory userId)
   public
   returns(int256)
   {
      Table table = tableFactory.openTable(BLACK_LIST_TABLE_NAME);
      Entry entry = table.newEntry();

      // 记录黑名单账户
      allUserId.push(userId);
      
      //已完成状态 0
      entry.set("userState", "0");

      Condition condition = table.newCondition();
      condition.EQ("userId", userId);

      int256 count = table.update(userId, entry, condition);
      emit updateResult(count);
      return count;
   }


   // 获得用户账户状态
   // 参数数据格式（userId）   返回值（"1" -> 正常；"0" -> 拉黑）
   function getUserState(string memory userId)
   public
   view
   returns(string memory)
   {
      Table table = tableFactory.openTable(BLACK_LIST_TABLE_NAME);
      string memory userState;

      Condition condition = table.newCondition();
      condition.EQ("userId", userId);

      Entries entries = table.select(userId, condition);
      if(0 == entries.size())
      {
         return("该ID不存在");
      }
      
      Entry entry = entries.get(0);

      userState= entry.getString("userState");
      
      return(userState);
   }

    // 获取所有黑名单账户
   function getAllBlacklistUser()
   public
   view
   returns(string[] memory, uint256)
   {
        uint256 blacklistNum = allUserId.length;
        return(allUserId, blacklistNum);
   }
}
