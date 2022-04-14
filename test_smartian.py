# Use for testing the Smartian class
from src.output_parser.Smartian import Smartian


if __name__ == "__main__":
    path = r".\src\output_parser\test_smartian.txt"
    with open(path, 'r') as f:
        str_output = f.read()
    smartian = Smartian()
    parse_output_results = smartian.parse(str_output)
    run = smartian.parseSarif(parse_output_results, "test path")
    print(run)