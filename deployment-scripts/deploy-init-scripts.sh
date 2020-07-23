#!/bin/bash

# Must be run in the directory with the init-scripts (spaces in names in Bash can cause issues)
token=$1
workspaceUrl=$2

initScriptsPath="dbfs:/init-scripts"

######################################################################################
# Create directory for Init Scripts
######################################################################################
JSON="{ \"path\" : \"$initScriptsPath\" }"

echo "curl https://$workspaceUrl/api/2.0/dbfs/mkdirs -d $JSON"

curl -X POST https://$workspaceUrl/api/2.0/dbfs/mkdirs \
    -H "Authorization: Bearer $token" \
    -H "Content-Type: application/json" \
    --data "$JSON"

######################################################################################
# List Directories (just so we can see if it is created)
######################################################################################
JSON="{ \"path\" : \"dbfs:/\" }"

echo "curl https://$workspaceUrl/api/2.0/dbfs/list -d $JSON"

curl -X GET https://$workspaceUrl/api/2.0/dbfs/list \
    -H "Authorization: Bearer $token" \
    -H "Content-Type: application/json" \
    --data "$JSON"

######################################################################################
# Upload Init Scripts
######################################################################################
replaceSource="./"
replaceDest=""

find . -type f -name "*" -print0 | while IFS= read -r -d '' file; do
    echo "Processing file: $file"
    filename=${file//$replaceSource/$replaceDest}
    echo "New filename: $filename"

    echo "curl -F path=$filename -F content=@$filename https://$workspaceUrl/api/2.0/dbfs/put"

    curl -n https://$workspaceUrl/api/2.0/dbfs/put \
      -H "Authorization: Bearer $token" \
      -F overwrite=true \
      -F path="$initScriptsPath/$filename" \
      -F content=@"$filename"       

    echo ""

done

######################################################################################
# List Init Scripts (just so we can see if it is created)
######################################################################################
JSON="{ \"path\" : \"$initScriptsPath\" }"

echo "curl https://$workspaceUrl/api/2.0/dbfs/list -d $JSON"

curl -X GET https://$workspaceUrl/api/2.0/dbfs/list \
    -H "Authorization: Bearer $token" \
    -H "Content-Type: application/json" \
    --data "$JSON"

echo ""
