# Azure-Databricks-Dev-Ops
Complete end to end sample of doing DevOps with Azure Databricks.  This is based on working with lots of customers who have requested that they can reference a documented apporach. This also securely uses KeyVault for each environement as well as uses Azure AD authorization tokens to call the Databricks REST API.


![alt tag](https://raw.githubusercontent.com/AdamPaternostro/Azure-Databricks-Dev-Ops/master/images/Databricks-Dev-Ops.gif)


## Steps
- Create a resource group in Azure named "Databricks-MyProject-WorkArea"
- Create a Databricks workspace in Azure named "Databricks-MyProject-WorkArea" in the above resource group
- Link your Databricks to source control: https://docs.databricks.com/notebooks/github-version-control.html
- Create or import some notebooks (NOTE: This repo has some from Databricks imported for demo purposes)

## DevOps Pipeline

![alt tag](https://raw.githubusercontent.com/AdamPaternostro/Azure-Databricks-Dev-Ops/master/images/DevOps-Stages-Environments.png)

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
  - Select the Mode: "Initialize-KeyVault"
  ![alt tag](https://raw.githubusercontent.com/AdamPaternostro/Azure-Databricks-Dev-Ops/master/images/Deployment-Mode.png)
  - The first time the pipeline will create your Databricks workspace and KeyVault.  It will skip all the other steps!
  - The pipeline will create 3 environment Dev, QA, Prod.
  - Click on QA and Prod in Azure DevOps and set an Approver required
  - In the Azure Portal
     - Go to the KeyVault created in Azure (repeat this for Dev, QA, Prod)
     - Click on Access Policies
         - NOTE: You might have to wait a few minutes (5+) to add the policies, mine gave a error at first and then was okay.
         - Click Add Access Policy
            - Configure from template: "Secret Management"
            - Key Permissions "0 Selected" (clear values if selected)
            - Secret Permissions "2 Selected" (select Get and List)
            - Certificate Permissins "0 Selected" (clear values if selected)
            - Select your Azure Pipeline Service Principal
            - Click Add
            - Click Save
         - Repeat the above steps and add yourself as a Full Secret management 
            - Select the template "Secret Management"
            - Select yourself as the Princpal
            - Click Add
            - Click Save
     - Click on Secrets
       - Click Generate / Import
       - You should see 4 secrets: databricks-dev-ops-subscription-id,databricks-dev-ops-tenant-id,databricks-dev-ops-client-id,databricks-dev-ops-client-secret
       - You need to set these values
          - Option 1 (Create a new service principal)
          - Option 2 (Use the same DevOps service principal)
          - In either case you need to make the service principal a contributor of the Databricks workspace or a contributor in the resource group in which the workspace resides.
       - Click on each secret and click "New Version" and set the secret value
          - databricks-dev-ops-subscription-id: 00000000-0000-0000-0000-000000000000
          - databricks-dev-ops-tenant-id: 00000000-0000-0000-0000-000000000000
          - databricks-dev-ops-client-id: 00000000-0000-0000-0000-000000000000
          - databricks-dev-ops-client-secret: "some crazy string"

- Re-run the pipeline using Mode "Databricks"
  - The pipeline should now deploy your Databricks artifacts  

- NOTE: If you re-run the pipeline in Mode "Initialize-KeyVault", your KeyVault will be overwritten
  - A better apporach is to test for the existance of the KeyVault during the Pipeline
  - Most customers have IT create their KeyVault for them.  In this case, you just need to KeyVault name they created. 

## What Happens during the Pipeline
- An Azure Resource Group is created (if it does not exist)
  - The Dev stage creates a resouce group named "Databricks-MyProject-Dev"
  - The QA stage creates a resouce group named "Databricks-MyProject-QA"
  - The QA stage creates a resouce group named "Databricks-MyProject-Prod"
  - You can change these to your naming schema if you perfer
  ![alt tag](https://raw.githubusercontent.com/AdamPaternostro/Azure-Databricks-Dev-Ops/master/images/DeployedResourceGroups.png)

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
   ![alt tag](https://raw.githubusercontent.com/AdamPaternostro/Azure-Databricks-Dev-Ops/master/images/Databricks-Clusters-Deployed.png)

- Notebooks are deployed
   - The script obtains an Azure AD authorization token using the Service Principal in KeyVault.  This token is then used to call the Databricks REST API
   - The are deployed to the /Users folder under a new folder that your specify.  The folder is not under any specific user, it will be at the root.
   ![alt tag](https://raw.githubusercontent.com/AdamPaternostro/Azure-Databricks-Dev-Ops/master/images/Databricks-Notebooks-Deployed.png)

- Add you own items!
  - Cut and paste the code from one of the above tasks.
  - Think about the order of operations.  If you are creating a Databricks Job and it references a cluster, then you should deploy the Job after the clusters.
  - NOTE: If you need to inject a value (e.g. Databricks "cluster_id"), you can see the technique in the deploy-clusters.sh script.

## Notes
- You do not need to have the pipeline create a KeyVault.  If you perfer you can just use one that exists in a central location. The DevOps service principal just needs access to read the keys.
- I do not use the Databricks CLI.  I know there are some DevOps Marketplace items that will deploy Notebooks, etc.  The reason for this is that customers have had issues with the CLI installing on top of one another and their DevOps pipelines break.  The Databricks REST API calls are simple and installing the CLI adds a dependency which could break.
- To deploy a cluster, Databricks shows you the JSON that is required.

## Potential Improvements
- Have the dev ops pipeline test for the existance of a KeyVault if you want to eliminate the Mode parameter (Intialize-KeyVault | Databricks)
- Seperate the tasks into another repo and call then from this pipeline.  This would make it more manageable.  See https://docs.microsoft.com/en-us/azure/devops/pipelines/process/templates?view=azure-devops#use-other-repositories
- Need to update this based upon the new Data Science Git Projects instead of using the Notebook per Git integration
- Deal with deploying Hive/Metastore table changes/scripts
- Deal with deploying Mount Points.  Most customers run a Notebook (one time) and then delete it.
