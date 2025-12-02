"""Module for adding MSA to JSON files."""

import os
import argparse
from pathlib import Path
import json
import tempfile

from abcfold.scripts.add_mmseqs_msa import add_msa_to_json


def validate_json_file(value):
    """
    Validate that the input is a JSON file with a .json suffix.
    """
    if not value.endswith(".json"):
        raise argparse.ArgumentTypeError(
            f"Input file must have a .json suffix: {value}"
        )
    if not Path(value).exists():
        raise argparse.ArgumentTypeError(f"Input file does not exist: {value}")
    return value


def process_input_json(args):
    """Function to process the input JSON file and generate output JSON file
    using abcfold and MMSEQS databases."""
    with open(args.input_json, "r", encoding="utf-8") as f:
        input_params = json.load(f)

    with tempfile.TemporaryDirectory() as temp_dir_str:
        temp_dir = Path(temp_dir_str)
        if not args.output_json:
            input_json = Path(args.input_json)
            run_json = temp_dir.joinpath(
                input_json.name.replace(".json", "_mmseqs.json")
            )
        else:
            run_json = Path(args.output_json)

        input_params = add_msa_to_json(
            input_json=input_json,
            mmseqs_db=args.mmseqs_database,
            templates=args.templates,
            num_templates=args.num_templates,
            chai_template_output=temp_dir.joinpath("all_chains.m8"),
            custom_template=args.custom_template,
            custom_template_chain=args.custom_template_chain,
            target_id=args.target_id,
            input_params=input_params,
            output_json=run_json,
            to_file=True,
        )


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="add msa to json")
    parser.add_argument(
        "input_json",
        type=validate_json_file,
        help="Path to the input JSON in AlphaFold3 format",
    )
    parser.add_argument(
        "--output_json",
        help="[optional] Specify the path of the output ABCFold json file, this \
can be used to run subsequent runs of ABCFold with the same input features (e.g. MSA)",
    )
    parser.add_argument(
        "--mmseqs2",
        help="Use MMseqs2 for MSA generation and template \
searching (if used with --templates flag)",
    )
    parser.add_argument(
        "--mmseqs_database",
        help="The database directory for the generation of the MSA. This \
is only required if using a local installation of MMseqs2",
    )
    parser.add_argument(
        "--templates", action="store_true", help="[optional] Enable template search"
    )
    parser.add_argument(
        "--num_templates",
        type=int,
        default=20,
        help="[optional] The number of templates to use (default: 20)",
    )
    parser.add_argument(
        "--target_id",
        nargs="+",
        help="[conditionally required] The ID of the sequence that the \
custom template relates to. This is only required if modelling a complex. \
If providing a list of custom templates, the target_id must be a list of \
the same length as the custom template list",
    )
    parser.add_argument(
        "--custom_template",
        nargs="+",
        help="[optional] Path to a custom template file in mmCif format or a list \
of paths to custom template files in mmCif format. If providing a list of \
custom templates, you must also provide a list of custom template chains.",
    )
    parser.add_argument(
        "--custom_template_chain",
        nargs="+",
        help="[conditionally required] The chain ID of the chain to use in your \
custom template. This is only required if using a multi-chain template. If \
providing a list of custom templates, you must also provide a list of custom \
template chains of the same length as the custom template list",
    )
    args = parser.parse_args()

    process_input_json(args)
