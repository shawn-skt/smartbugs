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

contract Medical is DataFormat{
    event insertResult(int256 count);
    event updateResult(int256 count);

    TableFactory tableFactory;

    string constant MEIDICAL_RECORD = "medicalRecord";

    constructor() public {
        tableFactory = TableFactory(0x1001);

        tableFactory.createTable(MEIDICAL_RECORD, "idNumber", "userName, userMedicalRecord");

        Table table = tableFactory.openTable(MEIDICAL_RECORD);
        Entry entry_1 = table.newEntry();
        Entry entry_2 = table.newEntry();
        Entry entry_3 = table.newEntry();
        Entry entry_4 = table.newEntry();
        Entry entry_5 = table.newEntry();

        entry_1.set("idNumber", "110108199912121212");
        entry_1.set("userName", "Tom");
        entry_1.set("userMedicalRecord", "心脑血管-心肌梗死");

        entry_2.set("idNumber", "410527199901010101");
        entry_2.set("userName", "Jerry");
        entry_2.set("userMedicalRecord", "感染病-病毒性肝炎");

        entry_3.set("idNumber", "130528199902020202");
        entry_3.set("userName", "Bob");
        entry_3.set("userMedicalRecord", "血液恶性病-白血病");

        entry_4.set("idNumber", "130224199903030303");
        entry_4.set("userName", "Kitty");
        entry_4.set("userMedicalRecord", "肿瘤-恶性肿瘤");

        entry_5.set("idNumber", "452427199904040404");
        entry_5.set("userName", "Sammy");
        entry_5.set("userMedicalRecord", "心脑血管-冠心病");
        
        table.insert("110108199912121212", entry_1);
        table.insert("410527199901010101", entry_2);
        table.insert("130528199902020202", entry_3);
        table.insert("130224199903030303", entry_4);
        table.insert("452427199904040404", entry_5);
    }

    // 插入病历信息
    // 参数(身份证号，姓名，病历信息)
    function insertMeidicalRecord(string memory idNumber, string memory userName, string memory userMedicalRecord) 
    public 
    returns(int256)
    {
        Table table = tableFactory.openTable(MEIDICAL_RECORD);
        Entry entry = table.newEntry();
        int256 count;

        // Set Value
        entry.set("idNumber", idNumber);
        entry.set("userName", userName);
        entry.set("userMedicalRecord", userMedicalRecord);

        count = table.insert(idNumber, entry);
        emit insertResult(count);

        return count;
    }

    // 查询用户病历信息
    // 参数(身份证号, 姓名, 病历信息)   返回值(bool, 错误信息)
    function getUserMedicalRecord(string memory idNumber, string memory userName, string memory userMedicalRecord)
    public
    view
    returns(bool, string memory)
    {
        Table table = tableFactory.openTable(MEIDICAL_RECORD);

        Condition condition = table.newCondition();
        condition.EQ("idNumber", idNumber);

        string memory userNameTemp;
        string memory userMedicalRecordTemp;

        Entries entries = table.select(idNumber, condition);
        if(0 == entries.size())
        {
            return(false, "用户ID出错");
        }
      
        Entry entry = entries.get(0);

        userNameTemp = entry.getString("userName");
        userMedicalRecordTemp = entry.getString("userMedicalRecord");
        if(strMatching(userNameTemp, userName) != true)
        {
            return(false, "姓名错误");
        }
        if(strMatching(userMedicalRecordTemp, userMedicalRecord) != true)
        {
            return(false, "病历信息错误");
        }
      
        return(true, "");
    }
}
