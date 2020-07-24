#!/bin/bash

# TO DO
# You might want to Pin your clusters

# Must be run in the directory with the clusters (spaces in names in Bash can cause issues)
tenant_id=$1
client_id=$2
client_secret=$3
subscription_id=$4
resourceGroup=$5
workspaceName=$6

azure_databricks_resource_id="2ff814a6-3304-4ab8-85cb-cd0e6f879c1d"
resourceId="/subscriptions/$subscription_id/resourceGroups/$resourceGroup/providers/Microsoft.Databricks/workspaces/$workspaceName"

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
# Deploy clusters (Add or Update existing)
######################################################################################

replaceSource="./"
replaceDest=""

# Get a list of clusters so we know if we need to create or edit
clusterList=$(curl GET https://$workspaceUrl/api/2.0/clusters/list \
            -H "Authorization:Bearer $accessToken" \
            -H "X-Databricks-Azure-SP-Management-Token: $managementToken" \
            -H "X-Databricks-Azure-Workspace-Resource-Id: $resourceId" \
            -H "Content-Type: application/json")

find . -type f -name "*" -print0 | while IFS= read -r -d '' file; do

    echo "Processing file: $file"
    filename=${file//$replaceSource/$replaceDest}
    echo "New filename: $filename"


    clusterName=$(cat $filename | jq -r .cluster_name)
    clusterId=$(echo $clusterList | jq -r ".clusters[] | select(.cluster_name == \"$clusterName\") | .cluster_id")

    echo "clusterName: $clusterName"
    echo "clusterId: $clusterId"

    # Test for empty cluster id (meaning it does not exist)
    if [ -z "$clusterId" ];
    then
       echo "Cluster $clusterName does not exists in Databricks workspace, Creating..."
       echo "curl https://$workspaceUrl/api/2.0/clusters/create -d $filename"

       curl -X POST https://$workspaceUrl/api/2.0/clusters/create \
            -H "Authorization:Bearer $accessToken" \
            -H "X-Databricks-Azure-SP-Management-Token: $managementToken" \
            -H "X-Databricks-Azure-Workspace-Resource-Id: $resourceId" \
            -H "Content-Type: application/json" \
            -d @"$filename" 

    else
       echo "Cluster $clusterName exists in Databricks workspace, Updating..."
       echo "curl https://$workspaceUrl/api/2.0/clusters/edit -d $filename"

       # need to inject some JSON into the file
       clusterDef=$(cat $filename)

       newJSON=$(echo $clusterDef | jq ". += {cluster_id: \"$clusterId\"}")
       echo "New Cluster Def"
       echo $newJSON
       echo ""

       curl -X POST https://$workspaceUrl/api/2.0/clusters/edit \
            -H "Authorization:Bearer $accessToken" \
            -H "X-Databricks-Azure-SP-Management-Token: $managementToken" \
            -H "X-Databricks-Azure-Workspace-Resource-Id: $resourceId" \
            -H "Content-Type: application/json" \
            --data "$newJSON"

    fi      
    echo ""  

done


######################################################################################
# Sleep will the above calls complete
######################################################################################
read -p "sleeping" -t 15


######################################################################################
# Stop the clusters
######################################################################################

# Get a list of clusters so we know if we need to create or edit
clusterList=$(curl GET https://$workspaceUrl/api/2.0/clusters/list \
               -H "Authorization:Bearer $accessToken" \
               -H "X-Databricks-Azure-SP-Management-Token: $managementToken" \
               -H "X-Databricks-Azure-Workspace-Resource-Id: $resourceId" \
               -H "Content-Type: application/json")

find . -type f -name "*" -print0 | while IFS= read -r -d '' file; do
    echo "Processing file: $file"
    filename=${file//$replaceSource/$replaceDest}
    echo "New filename: $filename"

    clusterName=$(cat $filename | jq -r .cluster_name)
    clusterId=$(echo $clusterList | jq -r ".clusters[] | select(.cluster_name == \"$clusterName\") | .cluster_id")

    echo "clusterName: $clusterName"
    echo "clusterId: $clusterId"

    # Test for empty cluster id (meaning it does not exist)
    if [ -z "$clusterId" ];
    then
       echo "WARNING: Cluster $clusterName did not have a Cluster Id.  Stopping the cluster will not occur."

    else
       echo "Cluster $clusterName with Cluster ID $clusterId, Stopping..."
       echo "curl https://$workspaceUrl/api/2.0/clusters/delete -d $clusterId"

       newJSON="{ \"cluster_id\" : \"$clusterId\" }"
       echo "Cluster to stop: $newJSON"
   
       # NOTE: permanent-delete is used to "delete" the cluster.  Delete below means "stop" the clustter
       curl -X POST https://$workspaceUrl/api/2.0/clusters/delete \
            -H "Authorization:Bearer $accessToken" \
            -H "X-Databricks-Azure-SP-Management-Token: $managementToken" \
            -H "X-Databricks-Azure-Workspace-Resource-Id: $resourceId" \
            -H "Content-Type: application/json" \
            --data "$newJSON"
    fi     
    echo ""  

done