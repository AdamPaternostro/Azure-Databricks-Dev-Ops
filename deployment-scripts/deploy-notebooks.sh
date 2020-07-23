#!/bin/bash

# Must be run in the directory with the notebooks (spaces in names in Bash can cause issues)
token=$1
workspaceUrl=$2
notebookPath=$3

replaceSource="./"
replaceDest=""

find . -type f -name "*" -print0 | while IFS= read -r -d '' file; do

    echo "Processing file: $file"

    filename=${file//$replaceSource/$replaceDest}

    echo "New filename: $filename"

    language=""
    if [[ "$filename" == *sql ]]
    then
        language="SQL"
    fi

    if [[ "$filename" == *scala ]]
    then
        language="SCALA"
    fi

    if [[ "$filename" == *py ]]
    then
        language="PYTHON"
    fi

    if [[ "$filename" == *r ]]
    then
        language="R"
    fi

    echo "curl -F language=$language -F path=$notebookPath/$filename -F content=@$filename https://$workspaceUrl/api/2.0/workspace/import"

    curl -n \
      -H "Authorization: Bearer $token" \
      -F language="$language" \
      -F path="$notebookPath/$filename" \
      -F content=@"$filename" \
      https://$workspaceUrl/api/2.0/workspace/import  

    echo ""  

done

