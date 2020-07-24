#!/bin/bash

# https://docs.microsoft.com/en-us/azure/databricks/dev-tools/api/latest/aad/service-prin-aad-token
# Create a service principal and a secret
# Make the service principal a contributor of the resource group or databricks workspace 
# Note: This uses "jq" for JSON parsing

tenant_id="<<REPLACE-ME>>"
client_id="<<REPLACE-ME>>"
client_secret="<<REPLACE-ME>>"
subscription_id="<<REPLACE-ME>>"
resourceGroup="<<REPLACE-ME>>"
workspaceName="<<REPLACE-ME>>"
resourceId="/subscriptions/$subscription_id/resourceGroups/$resourceGroup/providers/Microsoft.Databricks/workspaces/$workspaceName"
azure_databricks_resource_id="2ff814a6-3304-4ab8-85cb-cd0e6f879c1d"


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
# Sample Databricks REST API call
######################################################################################
curl -X GET \
  -H "Authorization:Bearer $accessToken" \
  -H "X-Databricks-Azure-SP-Management-Token: $managementToken" \
  -H "X-Databricks-Azure-Workspace-Resource-Id: $resourceId" \
  https://$workspaceUrl/api/2.0/clusters/list