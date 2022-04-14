from sarif_om import *
from src.output_parser.SarifHolder import isNotDuplicateRule, parseRule, parseResult, \
    parseArtifact, parseLogicalLocation, isNotDuplicateLogicalLocation

# FALSE

# class Smartian:
#     def __init__(self) -> None:
#         pass

#     def parse(self, str_output):
#         """Parse the output of the smartian tool. 
#         And the return is used for function parseSarif"""
#         output = []
#         current_contract = None
#         lines = str_output.splitlines()
#         for line in lines:
#             if("Fuzz target :" in line):
#                 if(current_contract is not None):
#                     output.append(current_contract)
#                 current_contract = {
#                     'errors': []
#                 }
#                 file = line.replace("[00:00:00:00] Fuzz target : ", '')
#                 contract_name = file.split(".")[0]   #contract_name不一定准确，因为输出中没有合约的名字，只有file名字，如果file名字不是合约的名字，那么contract_name就不对
#                 current_contract['file'] = file
#                 current_contract['name'] = contract_name
#             elif("Save new seed" in line or "Save bug seed" in line):
#                 TX = []
#             elif(") Function: " in line and "TX" in line):
#                 index = line.index(" Function: ") + len(" Function: ")
#                 index2 = line.index(",")
#                 function_name = line[index:index2]
#                 current_contract['function'] = function_name
#                 TX.append(function_name)
#             elif("] Tx#" in line and "found" in line):
#                 index = line.index("] Tx#") + len("] Tx#")
#                 index1 = line.index("found")
#                 tx_num = eval(line[index:index1])
#                 message = line.split(" ")[3]
#                 function_name = TX[tx_num]
#                 current_contract['errors'].append({
#                     'message': message,
#                     'level': "Warning",
#                     'function': function_name,
#                 })
#         if(current_contract is not None):
#             output.append(current_contract)
#         return output
    
#     def parseSarif(self, parse_output_results, file_path_in_repo):
#         """Param parse_output_results is the return of function parse
#         """
#         resultsList = []
#         logicalLocationsList = []
#         rulesList = []

#         for contract in parse_output_results:
#             for result in contract["errors"]:
#                 rule = parseRule(tool="smartian", vulnerability=result["message"])
#                 result = parseResult(tool="smartian", vulnerability=result["message"], level=result["level"],
#                                      uri=file_path_in_repo, logicalLocation=parseLogicalLocation(result["function"],
#                                                                       kind="function"))

#                 resultsList.append(result)

#                 if isNotDuplicateRule(rule, rulesList):
#                     rulesList.append(rule)

#             logicalLocation = parseLogicalLocation(name=contract["function"], kind="function")

#             if isNotDuplicateLogicalLocation(logicalLocation, logicalLocationsList):
#                 logicalLocationsList.append(logicalLocation)
        
#         artifact = parseArtifact(uri=file_path_in_repo)

#         tool = Tool(driver=ToolComponent(name="Smartian", version="1.0", rules=rulesList,
#                                          information_uri="https://github.com/SoftSec-KAIST/Smartian",
#                                          full_description=MultiformatMessageString(
#                                              text="Smartian is a grey-box fuzzer for Ethereum smart contracts. Smartian leverages static and dynamic data-flow analyses to enhance the effectiveness of fuzzing. The technical details of Smartian can be found in our paper \"Smartian: Enhancing Smart Contract Fuzzing with Static and Dynamic Data-Flow Analyses\" published in ASE 2021.")))

#         run = Run(tool=tool, artifacts=[artifact], logical_locations=logicalLocationsList, results=resultsList)

#         return run


