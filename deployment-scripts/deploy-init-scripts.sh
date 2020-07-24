#!/bin/bash

# Must be run in the directory with the init-scripts (spaces in names in Bash can cause issues)
# Must be run in the directory with the clusters (spaces in names in Bash can cause issues)
tenant_id=$1
client_id=$2
client_secret=$3
subscription_id=$4
resourceGroup=$5
workspaceName=$6

azure_databricks_resource_id="2ff814a6-3304-4ab8-85cb-cd0e6f879c1d"
resourceId="/subscriptions/$subscription_id/resourceGroups/$resourceGroup/providers/Microsoft.Databricks/workspaces/$workspaceName"

initScriptsPath="dbfs:/init-scripts"

######################################################################################
# Get access tokens for Databricks API
######################################################################################

accessToken=$(curl -X POST https://login.microsoftonline.com/$tenant_id/oauth2/token \
  -F resource=$azure_databricks_resource_id \
  -F client_id=$client_id \
  -F grant_type=client_credentials \
  -F client_secret=$client_secret | jq .access_token --raw-output) 

managementToken=$(curl -X POST https://login.microsoftonline.com/$tenant_id/oauth2/token \
  -F resource=https://management.core.windows.net/ \
  -F client_id=$client_id \
  -F grant_type=client_credentials \
  -F client_secret=$client_secret | jq .access_token --raw-output) 


######################################################################################
# Get Databricks workspace URL (e.g. adb-5946405904802522.2.azuredatabricks.net)
######################################################################################
workspaceUrl=$(curl -X GET \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $managementToken" \
        https://management.azure.com/subscriptions/$subscription_id/resourcegroups/$resourceGroup/providers/Microsoft.Databricks/workspaces/$workspaceName?api-version=2018-04-01 \
        | jq .properties.workspaceUrl --raw-output)

echo "Databricks workspaceUrl: $workspaceUrl"



######################################################################################
# Create directory for Init Scripts
######################################################################################
JSON="{ \"path\" : \"$initScriptsPath\" }"

echo "curl https://$workspaceUrl/api/2.0/dbfs/mkdirs -d $JSON"

curl -X POST https://$workspaceUrl/api/2.0/dbfs/mkdirs \
    -H "Authorization:Bearer $accessToken" \
    -H "X-Databricks-Azure-SP-Management-Token: $managementToken" \
    -H "X-Databricks-Azure-Workspace-Resource-Id: $resourceId" \
    -H "Content-Type: application/json" \
    --data "$JSON"

######################################################################################
# List Directories (just so we can see if it is created)
######################################################################################
JSON="{ \"path\" : \"dbfs:/\" }"

echo "curl https://$workspaceUrl/api/2.0/dbfs/list -d $JSON"

curl -X GET https://$workspaceUrl/api/2.0/dbfs/list \
    -H "Authorization:Bearer $accessToken" \
    -H "X-Databricks-Azure-SP-Management-Token: $managementToken" \
    -H "X-Databricks-Azure-Workspace-Resource-Id: $resourceId" \
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
        -H "Authorization:Bearer $accessToken" \
        -H "X-Databricks-Azure-SP-Management-Token: $managementToken" \
        -H "X-Databricks-Azure-Workspace-Resource-Id: $resourceId" \
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
        -H "Authorization:Bearer $accessToken" \
        -H "X-Databricks-Azure-SP-Management-Token: $managementToken" \
        -H "X-Databricks-Azure-Workspace-Resource-Id: $resourceId" \
        -H "Content-Type: application/json" \
        --data "$JSON"

echo ""
