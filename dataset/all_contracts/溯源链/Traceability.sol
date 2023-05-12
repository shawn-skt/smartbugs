pragma solidity ^0.4.25;
pragma experimental ABIEncoderV2;

contract Goods {
    struct TraceData {
        address addr;     //Operator address
        int16 status;     //goods status
        uint timestamp;   //Operator time
        string remark;    //Digested Data
    }
    uint64 _goodsId; 
    int16 _status;   //current status
    TraceData[] _traceData;
    
    event newStatus( address addr, int16 status, uint timestamp, string remark);
    
    constructor(uint64 goodsId) public {
        _goodsId = goodsId;
        _traceData.push(TraceData({addr:msg.sender, status:0, timestamp:now, remark:"create"}));
        emit newStatus(msg.sender, 0, now, "create");
    }
    
    function changeStatus(int16 goodsStatus, string memory remark) public {
        _status = goodsStatus;
        _traceData.push(TraceData({addr:msg.sender, status:goodsStatus, timestamp:now, remark:remark}));
        emit newStatus(msg.sender, goodsStatus, now, remark);
    }
      
    function getStatus() public view returns(int16) {
        return _status;
    }
    
    function getTraceInfo() public view returns(TraceData[] memory _data) {
        return _traceData;
    }
}

contract Traceability {
    struct GoodsData {
        Goods traceGoods;
        bool valid;
    }
    bytes32 _category;
    mapping(uint64 => GoodsData) private _goods;
    constructor(bytes32  goodsTp) public {
        _category = goodsTp;
    }
    
    event newGoodsEvent(uint64 goodsId);
    
    function createGoods(uint64 goodsId) public returns(Goods) {
        require(!_goods[goodsId].valid, "id really exists");
        
        _goods[goodsId].valid = true;
        Goods traceGoods = new Goods(goodsId);
        emit newGoodsEvent(goodsId);
        _goods[goodsId].traceGoods = traceGoods;
        return traceGoods;
    }
    
    function changeGoodsStatus(uint64 goodsId, int16 goodsStatus, string memory remark) public {
        require(_goods[goodsId].valid, "not exists");
         _goods[goodsId].traceGoods.changeStatus(goodsStatus, remark);
    }
      
     function getStatus(uint64 goodsId) public view returns(int16) {
         require(_goods[goodsId].valid, "not exists");
         return _goods[goodsId].traceGoods.getStatus();
    }

     function getGoods(uint64 goodsId) public view returns(Goods) {
         require(_goods[goodsId].valid, "not exists");
         return _goods[goodsId].traceGoods;
    }
}
