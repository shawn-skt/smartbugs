from sarif_om import *
from src.output_parser.SarifHolder import isNotDuplicateRule, parseRule, parseResult, \
    parseArtifact, parseLogicalLocation, isNotDuplicateLogicalLocation


class sFuzz:
    def __init__(self) -> None:
        pass

    def parse(self, str_output):
        """Parse the output of the sFuzz tool. 
        And the return is used for function parseSarif"""
        output = []
        current_contract = None
        lines = str_output.splitlines()
        report_line = False
        for line in lines:
            if("AFL Solidity" in line):
                if(current_contract is not None):
                    output.append(current_contract)
                current_contract = {
                    'errors': []
                }
                file = line.split("contracts/")[1]
                contract_name = file.split(".")[0]
                current_contract['file'] = contract_name + '.sol'
                current_contract['name'] = contract_name
            elif("oracle yields" in line):
                report_line = True
            elif(report_line and 'found' in line):
                sep_lines = line.split('┃')
                for sep_line in sep_lines:
                    if('found' in sep_line):
                        message = sep_line.split(':')[0].split()
                        message = '_'.join(message)
                        current_contract['errors'].append({
                            'message': message,
                            'level': "Warning"
                        })
        if(current_contract is not None):
            output.append(current_contract)
        return output
    
    def parseSarif(self, parse_output_results, file_path_in_repo):
        """Param parse_output_results is the return of function parse
        """
        resultsList = []
        logicalLocationsList = []
        rulesList = []

        for contract in parse_output_results:
            for result in contract["errors"]:
                rule = parseRule(tool="sFuzz", vulnerability=result["message"])
                result = parseResult(tool="sFuzz", vulnerability=result["message"], level=result["level"],
                                     uri=file_path_in_repo)

                resultsList.append(result)

                if isNotDuplicateRule(rule, rulesList):
                    rulesList.append(rule)
        
        artifact = parseArtifact(uri=file_path_in_repo)

        tool = Tool(driver=ToolComponent(name="sFuzz", version="0.0.1", rules=rulesList,
                                         information_uri="https://github.com/duytai/sFuzz",
                                         full_description=MultiformatMessageString(
                                             text="sFuzz is a symbolic fuzzer for Ethereum smart contracts.")))

        run = Run(tool=tool, artifacts=[artifact], logical_locations=logicalLocationsList, results=resultsList)

        return run


