#!/bin/bash

# Must be run in the directory with the notebooks (spaces in names in Bash can cause issues)
token=$1
workspaceUrl=$2
notebookPath=$3

######################################################################################
# Remove existing notebooks 
######################################################################################
JSON="{ \"path\" : \"$notebookPath/$filename\", \"recursive\": true }"
echo "Delete Notebooks: $JSON"
   
echo "curl https://$workspaceUrl/api/2.0/workspace/delete -d $clusterId"

curl -X POST https://$workspaceUrl/api/2.0/workspace/delete \
    -H "Authorization: Bearer $token" \
    -H "Content-Type: application/json" \
    --data "$JSON"



######################################################################################
# Create path
######################################################################################
JSON="{ \"path\" : \"$notebookPath/$filename\" }"
echo "Creating Path: $JSON"
   
echo "curl https://$workspaceUrl/api/2.0/workspace/mkdirs -d $clusterId"

curl -X POST https://$workspaceUrl/api/2.0/workspace/mkdirs \
    -H "Authorization: Bearer $token" \
    -H "Content-Type: application/json" \
    --data "$JSON"


######################################################################################
# Deploy notebooks
######################################################################################
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

    curl -n https://$workspaceUrl/api/2.0/workspace/import  
      -H "Authorization: Bearer $token" \
      -F language="$language" \
      -F path="$notebookPath/$filename" \
      -F content=@"$filename"       

    echo ""  

done
