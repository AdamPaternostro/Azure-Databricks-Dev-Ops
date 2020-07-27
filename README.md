# Azure-Databricks-Dev-Ops
Complete end to end sample of doing DevOps with Azure Databricks.  This is based on working with lots of customers who have requested that they can reference a documented apporach.


## Steps
- Create a resource group in Azure named "Databricks-MyProject-WorkArea"
- Create a Databricks workspace in Azure named "Databricks-MyProject-WorkArea" in the above resource group
- Link your Databricks to source control: https://docs.databricks.com/notebooks/github-version-control.html
- Create or import some notebooks (NOTE: This repo has some from Databricks imported for demo purposes)

## DevOps Pipeline
- Create a new Azure DevOps Project
- Import the code (or link to GitHub) under the repository menu
- Create a Service Principal in Azure
   - If you can make the service principal a subscription contributor 
   - If you cannot set permissions this high
      - Create a resource group name "something-Dev"
      - Grant the service principal contributor access to the resource group
      - NOTE: For testing purposes create two more resource groups "something-QA" and "something-Prod".  Also grant the service principal access
- Create a new service connection in Azure DevOps
- Create a new Pipeline in Azure and select the existing pipeline (azure-pipelines.yml)
- Run the pipeline
  - The first time the pipeline will create your Databricks workspace and KeyVault.  It will then fail!
     - Go to the KeyVault created in Azure
     - Grant the service principal access to read the secrets: databricks_dev_ops_subscription_id,databricks_dev_ops_tenant_id,databricks_dev_ops_client_id,databricks_dev_ops_client_secret
     - Set the values for the secrets.  Use the same service principal as above.  You will need to generate a secret.
- Re-run the pipeline
  - The pipeline should now deploy your Databricks artifacts     

## What Happens during the Pipeline
- Init Scripts are deployed
   - A DBFS path of dbfs:/init-scripts is created
   - All init scripts are then uploaded 
   - Init scripts are deploy before clusters since clusters can reference them
- Clusters are deployed
   - New clusters created
   - Existing clusters are updated
   - Clusters are then Stopped (so either change this or understand they are stopped). You might get a cores quota warning, but we will stop the clusters anyway, so it might not be an issue
- Notebooks are deployed
   - The are deployed to the /Users folder under a new folder that your specify.  The folder is not under any specific user, it will be at the root.
- Add you own item!
  - Cut and paste the code from one of the above tasks.
  - Think about the order of operations.  If you are creating a Databricks Job and it references a cluster, then you should deploy the Job after the clusters.
  - NOTE: If you need to inject a value (e.g. Databricks "cluster_id"), you can see the technique in the deploy-clusters.sh script.



## Why aren't we using the Azure AD token to login to Databricks API?
- If you are familiar with this (https://docs.microsoft.com/en-us/azure/databricks/dev-tools/api/latest/aad/app-aad-token) you can login to Databricks with an AD token.
- The problem with the token is that it requires an interactive (browser) login.  That does not really work for DevOps...
- I created this a while back (https://github.com/AdamPaternostro/Azure-Databricks-CI-CD-Initial-Token) and I will be using something simular in this template.  We need to create our Databricks workspace via ARM template, but then cannot connect to the workspace without an API key.  We cannot generate a key in Azure, we need to login to the workspace and create the key.  Once we have the key we can place it in KeyVault and then re-run the Pipeline.  So, the very first time, the pipeline will fail and you need to get the key manually so the pipeline can use the value.

## Notes
- This assumes you have a service principal that is a subscription contributor. If not then you need to create the resource group by hand and give the service principal access to the resource group (contributor).