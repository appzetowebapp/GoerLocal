#!/bin/bash

# Check if arguments are provided
if [ "$#" -lt 2 ]; then
    echo "Usage: ./generate.sh <ClassName> <path_to_json_file> [output_file_name]"
    echo "Example: ./generate.sh ProductData scripts/test.json"
    exit 1
fi

# Run the dart generator
dart scripts/model_generator.dart "$1" "$2" "$3"
