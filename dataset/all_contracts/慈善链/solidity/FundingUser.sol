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

contract FundingUser is DataFormat{
   event insertResult(int256 count);
   event updateResult(int256 count);
   event removeResult(int256 count);

   TableFactory tableFactory;

   string constant FUNDING_USER_TABLE_NAME = "fundingUser";

   constructor() public {
      // Set tableFactory address 
      tableFactory = TableFactory(0x1001);

      //资助用户(allFundingNumStr, 对应allFundingUser的金额)
      tableFactory.createTable(FUNDING_USER_TABLE_NAME, "userId", "allFundingUser, allFundingNumStr, fundingTime, score");
   }

    // 初始化用户资助表
    // 参数数据格式（userId）    返回值（插入数据条数）
   function initFundingInfo(string memory userId)
   public
   returns(int256)
   {
      Table table = tableFactory.openTable(FUNDING_USER_TABLE_NAME);
      Entry entry = table.newEntry();

      // Set Value
      entry.set("userId", userId);
      entry.set("allFundingUser", "");
      entry.set("allFundingNumStr", "");
      entry.set("fundingTime", "");
      entry.set("score", int256(0));
     
      int256 count = table.insert(userId, entry);
      emit insertResult(count);

      return count;
   }

   // 用户进行资助后，更新资助信息
   // 参数数据格式（userId，资助金额int，资助对象Id，资助金额string，资助时间）    返回值（更新数据条数）
   // 测试数据 1."2" "200" "伍羽放" "200" "2020-10-12"   2."2" "500" "赵双" "500" "2021-10-12"
   function updateFundingInfo(string memory userId, int256 fundsNumInt, string memory fundingId, string memory fundsNumStr, string memory fundingTime)
   public
   returns(int256)
   {
      Table table = tableFactory.openTable(FUNDING_USER_TABLE_NAME);
      
      Condition condition = table.newCondition();
      condition.EQ("userId", userId);

      // Get current fundsSum
      Entry entry = table.select(userId, condition).get(0);

      //资助者对象Id拼接
      string memory allFundingUser = entry.getString("allFundingUser");
      allFundingUser = strCatWithSymbol(allFundingUser, fundingId);

      // 每名资助者的金额
      // 资助金额拼接
      string memory allFundingNumStr = entry.getString("allFundingNumStr");
      allFundingNumStr = strCatWithSymbol(allFundingNumStr, fundsNumStr);

      //资助者时间拼接
      string memory allFundingTime = entry.getString("fundingTime");
      allFundingTime = strCatWithSymbol(allFundingTime, fundingTime);

      int256 score = entry.getInt("score");
      score = score + (fundsNumInt * 10);

      entry.set("allFundingUser", allFundingUser);
      entry.set("allFundingNumStr", allFundingNumStr);
      entry.set("fundingTime", allFundingTime);
      entry.set("score", score);

      int256 count = table.update(userId, entry, condition);
      emit updateResult(count);

      return count;
   }

   // 获得资助者当前资助数据
   // 参数数据格式（userId）   返回值（所有资助对象Id，所有资助对象金额，对应资助时间，总积分）
   function getUserFundingInfo(string memory userId)
   public
   view
   returns(string memory, string memory, string memory, int256)
   {
      Table table = tableFactory.openTable(FUNDING_USER_TABLE_NAME);

      Condition condition = table.newCondition();
      condition.EQ("userId", userId);

      Entries entries = table.select(userId, condition);
      if(0 == entries.size())
      {
         return("","","",-1);
      }
      
      Entry entry = entries.get(0);
      //allFundingUser, allFundingNumStr, fundingTime, score
      string memory allFundingUser = entry.getString("allFundingUser");
      string memory allFundingNumStr = entry.getString("allFundingNumStr");
      string memory fundingTime = entry.getString("fundingTime");
      int256 score = entry.getInt("score");
      
      return(allFundingUser, allFundingNumStr, fundingTime, score);
   }

}