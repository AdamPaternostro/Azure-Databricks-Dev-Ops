#!/bin/bash

# NOTE:
# The JSON for a Job that runs on an Existing Cluster MUST USE the Cluster Name for the Cluster Id!!!
# This script will look up the cluster id based upon the cluster name!

# Algorithm
# 1. Get the list of Jobs and Clusters (we need this for cluster ids)
# 2. Process the first jobs.json
# 3. Search the list of jobs based upon the job name
# 4. If the jobs does not exists
#    - If there the attribute "existing_cluster_id" exists in the JSON, replace the value by looking up the Cluster Id and call "Create"
#    - If there is not attribute "existing_cluster_id" the just call "Create"
# 5. If the job exists
#    - If there the attribute "existing_cluster_id" exists in the JSON, replace the value by looking up the Cluster Id
#    - Take the entire JSON (in the file) and place it under a new attribute named "new_settings"
#    - Inject the attribute "job_id" and set the value
#    - Call "Reset"

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
# Deploy jobs (Add or Update existing)
######################################################################################

replaceSource="./"
replaceDest=""

# Get a list of clusters so we know the clusters ids
clusterList=$(curl GET https://$workspaceUrl/api/2.0/clusters/list \
            -H "Authorization:Bearer $accessToken" \
            -H "X-Databricks-Azure-SP-Management-Token: $managementToken" \
            -H "X-Databricks-Azure-Workspace-Resource-Id: $resourceId" \
            -H "Content-Type: application/json")

# Get a list of clusters so we know the clusters ids
jobList=$(curl GET https://$workspaceUrl/api/2.0/jobs/list \
            -H "Authorization:Bearer $accessToken" \
            -H "X-Databricks-Azure-SP-Management-Token: $managementToken" \
            -H "X-Databricks-Azure-Workspace-Resource-Id: $resourceId" \
            -H "Content-Type: application/json")

# Algorithm
# 1. Get the list of Jobs and Clusters (we need this for cluster ids)
# 2. Process the first jobs.json
# 3. Search the list of jobs based upon the job name
# 4. If the jobs does not exists
#    - If there the attribute "existing_cluster_id" exists in the JSON, replace the value by looking up the Cluster Id and call "Create"
#    - If there is not attribute "existing_cluster_id" the just call "Create"
# 5. If the job exists
#    - If there the attribute "existing_cluster_id" exists in the JSON, replace the value by looking up the Cluster Id
#    - Take the entire JSON (in the file) and place it under a new attribute named "new_settings"
#    - Inject the attribute "job_id" and set the value
#    - Call "Reset"

find . -type f -name "*" -print0 | while IFS= read -r -d '' file; do

    echo "Processing file: $file"
    filename=${file//$replaceSource/$replaceDest}
    echo "New filename: $filename"

    jobName=$(cat $filename | jq -r .name)
    jobId=$(echo $jobList | jq -r ".jobs[] | select(.settings.name == \"$jobName\") | .job_id")
    echo "jobName: $jobName"
    echo "jobId: $jobId"

    existing_cluster_id_ClusterName=$(cat $filename | jq -r .existing_cluster_id)
    echo "existing_cluster_id_ClusterName: $existing_cluster_id_ClusterName"
    if [ $existing_cluster_id_ClusterName = "null" ];
    then
        clusterId=""
    else
        clusterId=$(echo $clusterList | jq -r ".clusters[] | select(.cluster_name == \"$existing_cluster_id_ClusterName\") | .cluster_id")
    fi
    echo "clusterId: $clusterId"

    # Check for error
    if [ $existing_cluster_id_ClusterName = "null" &&  $clusterId = "" ];
    then
        echo "ERROR: The job specifics an existing cluster name of ($existing_cluster_id_ClusterName), but not cluster with that name was found in the Databricks workspace."
        exit 1;
    fi

    json=$(cat $filename)
    echo "Job JSON $json"

    # Set the cluster id
    if [ -z "$clusterId" ];
    then
        echo "The job does not use an existing cluster (no need to set cluster id)"
    else
        echo "Setting existing_cluster_id"
        json=$(echo $json | jq -r ".existing_cluster_id = \"$clusterId\"")
        echo "Job JSON (with cluster id) $json"
    fi

    # Create a new job or update (reset) one
    if [ -z "$jobId" ];
    then
       echo "The Job $jobName does not exists in Databricks workspace, Creating..."
       echo "curl https://$workspaceUrl/api/2.0/jobs/create --data {json}"
   
       curl -X POST https://$workspaceUrl/api/2.0/jobs/create \
            -H "Authorization:Bearer $accessToken" \
            -H "X-Databricks-Azure-SP-Management-Token: $managementToken" \
            -H "X-Databricks-Azure-Workspace-Resource-Id: $resourceId" \
            -H "Content-Type: application/json" \
            --data "$json"

    else
       echo "Job $jobName exists in Databricks workspace, Updating..."

       # Inject the Job Id
       json="{ \"job_id\" : $jobId, \"new_settings\": $json }"
       echo "Job JSON (with job id) $json"

       echo "curl https://$workspaceUrl/api/2.0/jobs/reset--data {json}"

       curl -X POST https://$workspaceUrl/api/2.0/jobs/reset \
            -H "Authorization:Bearer $accessToken" \
            -H "X-Databricks-Azure-SP-Management-Token: $managementToken" \
            -H "X-Databricks-Azure-Workspace-Resource-Id: $resourceId" \
            -H "Content-Type: application/json" \
            --data "$json"

    fi      
    echo ""  

done
