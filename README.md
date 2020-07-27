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
      - NOTE: For testing purposes create two more resource groups "something-QA" and "something-Prod".  Also grant the service principal access.
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
- An Azure Resource Group is created (if it does not exist)
  - The Dev stage creates a resouce group named "Databricks-MyProject-Dev"
  - The QA stage creates a resouce group named "Databricks-MyProject-QA"
  - The QA stage creates a resouce group named "Databricks-MyProject-Prod"
  - You can change these to your naming schema if you perfer

- An Azure Databricks workspace is created
  - The Dev stage creates a resouce group named "Databricks-MyProject-Dev"
  - The QA stage creates a resouce group named "Databricks-MyProject-QA"
  - The QA stage creates a resouce group named "Databricks-MyProject-Prod"
  - You can change these to your naming schema if you perfer

- An Azure KeyVault is created
  - The Dev stage creates a resouce group named "KeyVault-MyProject-Dev"
  - The QA stage creates a resouce group named "KeyVault-MyProject-QA"
  - The QA stage creates a resouce group named "KeyVault-MyProject-Prod"
  - You can change these to your naming schema if you perfer

- KeyVault Secrets are downloaded
  - This allows you to have a KeyVault per Environemnt (Dev, QA, Prod)
  - A lot of customers deploy QA and Prod to different Azure Subscriptions, so this allows each environment to be secured appropreiately.  The Pipeline Template just references KeyVault secret names and each environment will be able to obtain the secrets is requires.

- Init Scripts are deployed
   - The script obtains an Azure AD authorization token using the Service Principal in KeyVault.  This token is then used to call the Databricks REST API
   - A DBFS path of dbfs:/init-scripts is created
   - All init scripts are then uploaded 
   - Init scripts are deploy before clusters since clusters can reference them

- Clusters are deployed
   - The script obtains an Azure AD authorization token using the Service Principal in KeyVault.  This token is then used to call the Databricks REST API
   - New clusters created
   - Existing clusters are updated
   - Clusters are then Stopped (so either change this or understand they are stopped). You might get a cores quota warning, but we will stop the clusters anyway, so it might not be an issue

- Notebooks are deployed
   - The script obtains an Azure AD authorization token using the Service Principal in KeyVault.  This token is then used to call the Databricks REST API
   - The are deployed to the /Users folder under a new folder that your specify.  The folder is not under any specific user, it will be at the root.

- Add you own items!
  - Cut and paste the code from one of the above tasks.
  - Think about the order of operations.  If you are creating a Databricks Job and it references a cluster, then you should deploy the Job after the clusters.
  - NOTE: If you need to inject a value (e.g. Databricks "cluster_id"), you can see the technique in the deploy-clusters.sh script.

