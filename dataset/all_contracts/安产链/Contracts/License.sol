pragma solidity 0.4.25;
pragma experimental ABIEncoderV2;
contract Enterprise{
    string name; 
    string representative;
    string addr;
    string enterpriseType;
    string enterpriseLimit; //公司基本信息

    string encryptedDataIpfs;
    string encryptedDataHash;

    string reportIpfs;
    string reportHash;

    address licenseAddress;
    ReportEvaluation evaluation;
    
    constructor() {
        encryptedDataIpfs = "";
        reportIpfs = "";
        licenseAddress = 0;
    }

    // function set_data(string data) public{
    //     encryptedDataIpfs = data;
    // }

    // function set_report(string report) public{
    //     reportIpfs = report; 
    // }
    
    function setLicense() public {
            licenseAddress = msg.sender;
    }
    
    function set(string data,string report) private{
        encryptedDataIpfs = data;
        reportIpfs = report; 
    }

    function get()constant returns(string,string,address){
        return (encryptedDataIpfs, reportIpfs, licenseAddress );
    }
    
    function getReport() constant returns(string){
        return reportIpfs;
    }

    function getLicenseAddress() constant returns(address){
        return licenseAddress;
    }
    
    function setInformation(string _name,string _representative,string _addr,string _enterpriseType,string _enterpriseLimit) public {
        name = _name; 
        representative = _representative;
        addr = _addr;
        enterpriseType = _enterpriseType;
        enterpriseLimit = _enterpriseLimit;
    }

    function getInformation() public returns(string,string,string,string,string){
        return (name,representative,addr,enterpriseType,enterpriseLimit);
    }

    function update(string reporthash,string report,address agency,string [] engineer) public returns(address){
        reportIpfs = report;
        reportHash = reporthash;
        evaluation = new ReportEvaluation(agency,engineer);
        return address(evaluation);
    }

    function updateData(string datahash, string dataipfs) public {
        encryptedDataIpfs = dataipfs;
        encryptedDataHash = datahash;
    }
}
contract License{
    Enterprise ent;
    // 证书内容；
    // 安评材料地址；
    // 安评师ID；
    // 安评机构ID；
    // 有效期/撤销；
    string name; 
    string representative;
    string addr;
    string enterpriseType;
    string enterpriseLimit; //公司基本信息

    string license;
    string dataIpfs;
    string reportIpfs;
    address agency;
    string[] engineer;
    uint expiration;
    string licenseStatus = "待审查";

    function showInfo() constant returns(string,string,string,address,string[]){
        return (license,dataIpfs,reportIpfs,agency,engineer);
    }

    function getInfo() constant returns(string, string, string, string, string, uint,string){
        return (name, representative, addr, enterpriseType, enterpriseLimit, expiration,licenseStatus);
    }


    function addLicense(address enterprise,address _agency,string[] _engineer){
        expiration = now + 3*365*24*60*60 * 1000;
        ent = Enterprise(enterprise);
        ent.setLicense();
        (dataIpfs,reportIpfs,) = ent.get();
        (name,representative,addr,enterpriseType,enterpriseLimit) = ent.getInformation();
        (agency,engineer) = (_agency,_engineer);
        ent.setLicense();
    }

    function revokeLicense(){
        licenseStatus = "已撤销";
    }

    function updateStatus(string status){
        licenseStatus = status;
    }
}

contract Management{
    // enum entityType{ AGENCY,AUDIT,ENTERPRISE }
    
    struct entityInfo{
        address accountAddr;
        address contractAddr;
        string pubKey;
        string field;
        // entityType accountType;
    }
    mapping (string => entityInfo) auditMap;
    mapping (string => entityInfo) agencyMap;
    mapping (string => entityInfo) enterpriseMap;
    string[] auditList;
    string[] agencyList;
    string[] enterpriseList;
    address[] auditAddressList;
    address[] agencyAddressList;

    function addAudit(string name, address accountAddr, string pubKey,string field) public {
        auditMap[name] = entityInfo(accountAddr, 0x0,pubKey,field);
        auditList.push(name);
        auditAddressList.push(accountAddr);
    }
    
    function addAgency(string name, address accountAddr, address contractAddr ,string pubKey, string field ) public {
        agencyMap[name] = entityInfo(accountAddr,contractAddr,pubKey,field);
        agencyList.push(name);
        agencyAddressList.push(contractAddr);
    }

    function addEnterprise(string name, address accountAddr,address contractAddr, string pubKey, string field) public {
        enterpriseMap[name] = entityInfo(accountAddr,contractAddr,pubKey,field);
        enterpriseList.push(name);
    }
    
    function getAuditAccnountAddr(string name) public view returns(address){
        return auditMap[name].accountAddr;
    }
    function getAuditPubKey(string name) public view returns(string) {
        return auditMap[name].pubKey;
    }
    function getAuditField(string name) public view returns(string){
        return auditMap[name].field;
    }
    
    function getAgencyAccountAddr(string name) public view returns(address) {
        return agencyMap[name].accountAddr;
    }
    function getAgencyContractAddr(string name) public view returns(address){
        return agencyMap[name].contractAddr;
    }
    function getAgencyPubKey(string name) public view returns(string) {
        return agencyMap[name].pubKey;
    }
    function getAgencyField(string name) public view returns(string){
        return agencyMap[name].field;
    }
    
    function getEnterpriseAccountAddr(string name) public view returns(address) {
        return enterpriseMap[name].accountAddr;
    }
    function getEnterpriseContractAddr(string name) public view returns(address){
        return enterpriseMap[name].contractAddr;
    }
    function getEnterprisePubKey(string name) public view returns(string) {
        return enterpriseMap[name].pubKey;
    }
    function getEnterpriseField(string name) public view returns(string){
        return enterpriseMap[name].field;
    }
    

    function getAuditList() public view returns(string[],address[]){
        return (auditList,auditAddressList);
    }
    function getAgencyList() public view returns(string[],address[]){
        return (agencyList,agencyAddressList);
    }
    function getEnterpriseList() public view returns(string[]){
        return enterpriseList;
    }
}

interface randomNumber {
    function getRandomNumber(uint256 userProvidedSeed) external returns (bytes32 );
    function get() external returns (uint256);
} //获取随机数的接口

contract ReportEvaluation{
    // address[] allAgency; //所有机构列表
    
    address licenseAddress;
    mapping (uint256 => uint) public resultMap;//用于生成随机数
    Management systemManagement;

    uint256[] randomAgencyIndex;
    address[] randomAgencyAddress;
    string[] randomAgencyName;
    string[] pubKey;

    address[] allAgency;
    string[] allAgencyName;

    address enterprise;//被评定的企业
    address relatedAgency; // 发证机构
    string[] relatedEngineer; //相关安评师
    string business;
    uint start;
    uint confirmTimes;
    
    address randomNumberAddress = 0x2ab1a8217e2e471784d0c5cbe01fba1d243c2e47;
    randomNumber randGen =  randomNumber(randomNumberAddress);
    
    function addAgency(address agency) public returns(address[]){
        allAgency.length = allAgency.push(agency);
        return allAgency;
    } //test


    //添加安评机构列表
    function addAgencyList(address[] agencyList) public returns(address[]) {
        uint i;
        for (i = 0 ; i < agencyList.length; i++){
            allAgency.push(agencyList[i]);
        }
        return allAgency;
    }

    function getAgencyList(address managementAddress) public {
        systemManagement = Management(managementAddress);
        (allAgencyName,allAgency) = systemManagement.getAgencyList();
    }

    function showAgencyList() constant public returns (address[], string[]) {
        return (allAgency, allAgencyName);
    }

    function getLicenseAddr() constant public returns (address) {
        return licenseAddress;
    }
    
    //合约初始化
    constructor(address agency,string[] engineer) {
        start = 0;
        confirmTimes = 0;
        relatedAgency = agency;
        relatedEngineer = engineer;
        enterprise = msg.sender;
    }

    function randFromOracle(uint256 seed,uint256 total) public returns(uint256) {
        randGen.getRandomNumber(seed);
        return randGen.get() % total;
    }


    
    function genNextRand(uint256 seed,uint256 total) public view returns (uint256) {
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.number, seed)));
        return randomNumber%total;
    }


    function randomAgency(uint256 length,uint256 total) public returns(uint256[]){
        delete randomAgencyIndex;
        uint256 rand;
        uint256 len;
        uint256 nonce;
        len = length;
        nonce = randFromOracle(now,total);
        while (len>0){
            rand = genNextRand(nonce,total);
            if(resultMap[rand] != 1){
                resultMap[rand] = 1;
                randomAgencyIndex.push(rand);
                nonce++;
                len--;
            }
            else{
                nonce++;
            }
        }
        for(uint256 i = 0 ; i < randomAgencyIndex.length;i++){
            delete resultMap[randomAgencyIndex[i]];
        }
        return randomAgencyIndex;
    }
    
    function startEvaluation() public returns(address[]){
        if(start == 0){
            start = 1;
            randomAgency(3, allAgency.length);
            randomAgencyAddress.push(allAgency[randomAgencyIndex[0]]);
            randomAgencyAddress.push(allAgency[randomAgencyIndex[1]]);
            randomAgencyAddress.push(allAgency[randomAgencyIndex[2]]);
        }
        return randomAgencyAddress;
    }


    //安评机构审核通过
    function confirm(){
        uint i;
        for(i=0;i<randomAgencyIndex.length;i++){
            if(allAgency[randomAgencyIndex[i]] == msg.sender){
                delete randomAgencyIndex[i];
                confirmTimes++;
                if(confirmTimes>2){
                    License newLicense = License(licenseAddress);
                    newLicense.updateStatus("有效");
                }
                break;
            }
        }
    }

    // 安评机构审核不通过 返回生成的仲裁合约地址
    function deny() public returns(address){
        uint i;
        for(i=0;i<randomAgencyIndex.length;i++){
            if(allAgency[randomAgencyIndex[i]] == msg.sender){
                // 触发仲裁，修改licenseStatus
                License newLicense = License(licenseAddress);
                newLicense.updateStatus("待仲裁");
                Arbitrate newArbitrate = new Arbitrate(enterprise);
                return address(newArbitrate);
            }
        }
    }

    //开始审核后，生成证书，并更新业务列表
    function businessUpdate() public returns(address){
        License newLicense;
        newLicense = new License();
        newLicense.addLicense(enterprise,relatedAgency,relatedEngineer); //调用发证合约
        Enterprise _enterprise = Enterprise(enterprise);
        address licenseAddr = _enterprise.getLicenseAddress();
        business = _enterprise.getReport();
        Agency agency = Agency(relatedAgency);//更新安评机构
        agency.addBusiness(relatedEngineer, now , licenseAddr,"评价");
        //更新业务
        licenseAddress = address(newLicense);
        return address(newLicense);
    } 

    function test() public view returns(uint,uint,address,address,string[]){
        return (start,confirmTimes,enterprise,relatedAgency,relatedEngineer);
    }
    function test2() public view returns(address[],uint256[],address[]){
        return (allAgency,randomAgencyIndex,randomAgencyAddress);
    }
    
}

contract Agency {
    //安评师列表合约地址
    address engList;

    //机构公钥证书
    string agencyCert;

    //业务信息   
    struct businessInfo{ 
        uint time;
        address licenseAddr;
        string businessType;
    }

    //安评机构业务列表
    businessInfo[] businessList;


    //信用评价合约地址
    address creditAddr;

    //资质分
    int credit;
    

    //设置机构证书
    function setAgencyCert(string cert) public {
        agencyCert = cert;
    }

    //获取机构证书
    function getAgencyCert() public view returns(string) {
        return agencyCert;
    }

    //设置安评师列表合约的合约地址 ，以便addbusiness 
    function setEngListAddr(address addr) public {
        engList = addr;
    }

    //获取安评师列表合约地址
    function getEngListAddr() public view returns (address){
        return engList;
    }

    function confirm(address evaluationAddress, string[] id) public {
        ReportEvaluation evaluation = ReportEvaluation(evaluationAddress);
        address licenseAddr = evaluation.getLicenseAddr();
        addBusiness(id, now, licenseAddr, "审查");
        evaluation.confirm();
    }

    // 不通过审核
    function deny(address evaluationAddress, string[] id) public returns(address) {
        ReportEvaluation evaluation = ReportEvaluation(evaluationAddress);
        address licenseAddr = evaluation.getLicenseAddr();
        addBusiness(id, now, licenseAddr, "审查");
        return evaluation.deny();
    }
    
    // 为机构添加业务，同时为多个安评师添加业务，indexes记录安评师索引。
    function addBusiness(string[] id ,uint time,address licenseAddr,string businessType) public {
        businessInfo memory tempInfo ;
        tempInfo.time = time;
        tempInfo.licenseAddr = licenseAddr;
        tempInfo.businessType = businessType;
        businessList.push(tempInfo);
        uint i;
        for(i =0; i< id.length;i ++){
            EngineerList(engList).addBusiness(id[i],time,licenseAddr,businessType);
        }
        updateCredit();
    }
    
    //输出当前机构参与的所有业务
    function showBusiness() public view returns(businessInfo[]){
        return businessList;
    }

    //设置信用评价合约地址
    function setCreditAddr(address addr) public {
        creditAddr = addr;
    }

    //获取信用评价合约地址
    function getCreditAddr() public view returns(address){
        return creditAddr;
    }

    //更新信用分
    function updateCredit() public {
        require(creditAddr != address(0), "creditAddr must be set before updateCredit");
        credit = Credit(creditAddr).computeAgencyCredit(businessList);
    }

    //获取信用分
    function getCredit() public view returns(int) {
        return credit;
    }
}

contract EngineerList{
    //业务内容，包括时间、证书地址、业务类型
    struct businessInfo{ 
        uint time;
        address licenseAddr;
        string businessType;
    }

    //安评师信息，包括安评师姓名、安评师所属领域、安评师证书、安评师所属安评机构、安评师业务列表
    struct engineerInfo{
        string name;
        string field;
        string safetyEvaluationCertificate;
        string agency; 
        int credit;
        businessInfo[] businessList;
    }

    //以安评师证书id为索引创建Map
    mapping (string => engineerInfo) engineerMap;

    //信用合约地址
    address creditAddr;

    
    //添加安评师，
    function addEngineer(string _name, string id, string _field,string _cert,string _agency) public  {
        engineerMap[id].name = _name;
        engineerMap[id].field = _field;
        engineerMap[id].safetyEvaluationCertificate = _cert;
        engineerMap[id].agency = _agency;
    }

    //获取安评师信息，输入安评师证书id
    function getEngineer(string id) public view returns(engineerInfo){
        return engineerMap[id];
    }

    //删除安评师所属安评机构
    function deleteAgency(string id ) public{
        engineerMap[id].agency ="";
    }

    //安评师设置新机构
    function setAgency(string id,string agen) public {
        if ( bytes(engineerMap[id].agency).length == 0 && bytes(agen).length != 0)  {
            engineerMap[id].agency = agen;            
        }
    }

    //为安评师添加新业务信息
    function addBusiness(string id,uint time,address addr,string bType) public {
        businessInfo memory tempBusiness;
        tempBusiness.time = time;
        tempBusiness.licenseAddr = addr;
        tempBusiness.businessType = bType;
        engineerMap[id].businessList.push(tempBusiness);
        updateCredit(id);
    }

    function setCreditContractAddr(address addr) public  {
        creditAddr = addr;
    }
    function getCreditContractAddr() public view returns(address) {
        return creditAddr;
    } 

    function updateCredit(string id ) public  {
        require(creditAddr != address(0), "creditAddr must be set before updateCredit");
        engineerMap[id].credit = Credit(creditAddr).computeEngineerCredit(engineerMap[id].businessList);
    }
    
    function getCredit(string id) public view returns(int){
        return engineerMap[id].credit;
    }
}


contract Credit{

    function computeEngineerCredit(EngineerList.businessInfo[] businessList) payable public returns (int) {
        uint i;
        int credit = 0;
        for (i =0; i< businessList.length; i++){
            credit +=10;
        }
        return credit + 60;
    }
    
    function computeAgencyCredit(Agency.businessInfo[] businessList) payable public  returns (int ) {
        uint i;
        int credit = 0;
        for (i =0; i< businessList.length; i++){
            credit +=10;
        }
        return credit + 60;
    }
    
}

contract Arbitrate{
    mapping (uint256 => uint) public resultMap;//用于生成随机数
    address licenseAddress;
    address enterpriseAddress;
    address[] allAudit;
    uint256[] randomAuditIndex;
    address[] randomAuditAddress;    
    string[] allAuditName;
    string[] randomAuditName;
    Enterprise newEnterprise;
    Management systemManagement;
    uint confirmTimes;
    uint start;

    address randomNumberAddress = 0x2ab1a8217e2e471784d0c5cbe01fba1d243c2e47;
    randomNumber randGen =  randomNumber(randomNumberAddress);

    constructor(address _enterpriseAddress){
        enterpriseAddress = _enterpriseAddress;
        newEnterprise = Enterprise(_enterpriseAddress);
        (,,licenseAddress) = newEnterprise.get();

        License newLicense = License(licenseAddress);
        newLicense.updateStatus("待仲裁");
    }

    //添加监管部门
    function addAudit(address audit) public returns(address[]){
        allAudit.length = allAudit.push(audit);
        return allAudit;
    } 


    //获取监管部门列表
    function addAuditList(address[] auditList) public returns(address[]) {
        uint i;
        for (i = 0 ; i < auditList.length; i++){
            allAudit.push(auditList[i]);
        }
        return allAudit;
    }

    //输入管理合约地址  初始化监管部门列表
    function getAuditList(address managementAddress) public {
        systemManagement = Management(managementAddress);
        (allAuditName,allAudit) = systemManagement.getAuditList();
    }


    function randFromOracle(uint256 seed,uint256 total) public returns(uint256) {
        randGen.getRandomNumber(seed);
        return randGen.get() % total;
    }


    
    function genNextRand(uint256 seed,uint256 total) public view returns (uint256) {
        uint256 rand = uint256(keccak256(abi.encodePacked(block.number, seed)));
        return rand%total;
    }


    //随机选择监管部门
    function randomAudit(uint256 length,uint256 total) public returns(uint256[]){
        uint256 r;
        uint256 len;
        uint256 nonce;
        len = length;
        nonce = randFromOracle(now,total);
        while (len>0){
            r = genNextRand(nonce,total);
            if(resultMap[r] != 1){
                resultMap[r] = 1;
                randomAuditIndex.push(r);
                nonce++;
                len--;
            }
            else{
                nonce++;
            }
        }
        return randomAuditIndex;
    }


    //开始仲裁 返回选出的监管部门的名称和公钥
    function startAudition() public returns(string[],string[], address[]){
        string[] pubKey;
        
        if(start == 0){
            start = 1;
            randomAudit(3, allAuditName.length);
            // randomAuditIndex = [0];
            randomAuditName.push(allAuditName[randomAuditIndex[0]]);
            randomAuditName.push(allAuditName[randomAuditIndex[1]]);
            randomAuditName.push(allAuditName[randomAuditIndex[2]]);
            randomAuditAddress.push(allAudit[randomAuditIndex[0]]);
            randomAuditAddress.push(allAudit[randomAuditIndex[1]]);
            randomAuditAddress.push(allAudit[randomAuditIndex[2]]);
            pubKey.push(systemManagement.getAuditPubKey(randomAuditName[0]));
            pubKey.push(systemManagement.getAuditPubKey(randomAuditName[1]));
            pubKey.push(systemManagement.getAuditPubKey(randomAuditName[2]));
        }

        return (randomAuditName,pubKey, randomAuditAddress);
    }

    //监管部门通过
    function confirm() returns (bool) {
        uint i;
        for(i=0;i<randomAuditIndex.length;i++){
            if(allAudit[randomAuditIndex[i]] == msg.sender){
                // delete randomAuditIndex[i];
                confirmTimes++;
                if(confirmTimes>2){
                    License newLicense = License(licenseAddress);
                    newLicense.updateStatus("有效");
                }
                return true;
            }
        }
        return false;
    }

    // 监管部门审核不通过
    function deny() returns (bool) {
        uint i;
        for(i=0;i<randomAuditIndex.length;i++){
            if(allAudit[randomAuditIndex[i]] == msg.sender){
                // 触发仲裁，修改licenseStatus
                License newLicense = License(licenseAddress);
                newLicense.updateStatus("仲裁不通过");
                return true;
            }
        }

        return false;
    }


}




