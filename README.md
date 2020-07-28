# Azure-Databricks-Dev-Ops
Complete end to end sample of doing DevOps with Azure Databricks.  This is based on working with lots of customers who have requested that they can reference a documented apporach. The included code utilizes KeyVault for each environement and uses Azure AD authorization tokens to call the Databricks REST API.

This will show you how to deploy your Databricks assests via Azure Dev Ops Pipelines so that your Notebooks, Clusters, Jobs and Init Scipts are automatically deployed and configured per environment.

![alt tag](https://raw.githubusercontent.com/AdamPaternostro/Azure-Databricks-Dev-Ops/master/images/Databricks-Dev-Ops.gif)

## How to deploy this in your subscription
- Create a service principal that will be used for your DevOps pipeline.
   - Option A (easy security)
      - Add the service principal to the Contributor role to your Subscription.
   - Option B (fine grain security)
      - Create three resource groups
         - Databricks-MyProject-Dev
         - Databricks-MyProject-QA
         - Databricks-MyProject-Prod
      - Grant the service principal to the Contributor role to each Resource Group

- Create an Azure Dev Ops project
- Click on the Repo icon on the left menu 
  - Select "Import" 
  - Enter the URL: ```https://github.com/AdamPaternostro/Azure-Databricks-Dev-Ops```

- Click on the Pipeline icon on the left menu 
  - Click "Create Pipeline"
  - Click "Azure Repos Git"
  - Click on your Repo
  - Click the arrow on the "Run" button and select Save (don't run it, just save it)

- Click on the Gear icon (bottom left)
  - Click Service Connections
  - Click Create Service Connection
  - Click Azure Resource Manager
  - Click Service Principal (manual)
  - Fill in the Fields
    - You will need the values from when you created a service principal
    - You can name your connection something like "DatabricksDevOpsConnection" 
    - NOTE: You can also create a service connection per subscription if you would be deploying to different subscriptions.
  - Click Verify and Save

- Click on the Pipeline icon on the left menu
  - Select your pipeline
  - Click Run
    - Fill in the fields (only **bold** are not the defaults)
       - Notebooks Relative Path in Git: notebooks/MyProject
       - Notebooks Deployment Path to Databricks: /MyProject
       - Resource Group Name: Databricks-MyProject (NOTE: "-Dev" will be appended)
       - Azure Region: EastUS2
       - Databricks workspace name: Databricks-MyProject
       - KeyVault name: KeyVault-MyProject
       - Azure Subscription Id: **replace this 00000000-0000-0000-0000-000000000000**
       - Azure Resource Connection Name: **DatabricksDevOpsConnection**
       - Deployment Mode: **Initialize KeyVault**
       - ![alt tag](https://raw.githubusercontent.com/AdamPaternostro/Azure-Databricks-Dev-Ops/master/images/Deployment-Mode.png)
       - Click "Run"

- You should see the following
![alt tag](https://raw.githubusercontent.com/AdamPaternostro/Azure-Databricks-Dev-Ops/master/images/DevOps-Stages-Environments.png)

- The first time the pipeline will create your Databricks workspace and KeyVault.  **It will skip all the other steps!**

  - The pipeline will create 3 environment Dev, QA, Prod in DevOps
  - The pileline will create 3 Azure resource groups
    ![alt tag](https://raw.githubusercontent.com/AdamPaternostro/Azure-Databricks-Dev-Ops/master/images/DeployedResourceGroups.png)
  - In the Azure Portal
     - Go to the KeyVault created in each Azure resource group (repeat this for Dev, QA, Prod)
     - Click on Access Policies
         - NOTE: You might have to wait a few minutes to add the policies, mine gave a error at first and then was okay.
         - Click Add Access Policy
            - Configure from template: "Secret Management"
            - Key Permissions "0 Selected" 
            - Secret Permissions "2 Selected" (select Get and List)
            - Certificate Permissins "0 Selected" 
            - Select your Azure Pipeline Service Principal (you can enter the Client ID (Guid) in the search box)
            - Click Add
            - Click Save
         - Repeat the above steps and add yourself as a Full Secret management 
            - Select the template "Secret Management"
            - **Leave** all the Secret Permissions selected
            - Select yourself as the Principal
            - Click Add
            - Click Save
     - Click on Secrets
       - Click Generate / Import
       - You should see 4 secrets: databricks-dev-ops-subscription-id,databricks-dev-ops-tenant-id,databricks-dev-ops-client-id,databricks-dev-ops-client-secret
       - You need to set these values.  These values are a Service Principal that will call over to the Databricks workspace using the Databricks REST API.
          - Option 1 (Create a new service principal)
          - Option 2 (Use the same DevOps service principal)
          - In either case you need to make the service principal a **contributor** of the Databricks workspace or a contributor in the resource group in which the workspace resides.  You need to set this in Azure.
       - Click on each secret and click "New Version" and set the secret value
          - databricks-dev-ops-subscription-id: 00000000-0000-0000-0000-000000000000
          - databricks-dev-ops-tenant-id: 00000000-0000-0000-0000-000000000000
          - databricks-dev-ops-client-id: 00000000-0000-0000-0000-000000000000
          - databricks-dev-ops-client-secret: "some crazy string"

- Re-run the pipeline 
   - Set the parameters
       - Azure Subscription Id: **replace this 00000000-0000-0000-0000-000000000000**
       - Azure Resource Connection Name: **DatabricksDevOpsConnection**
       - Deployment Mode: **Databricks**  (this is the default, so you really do not need to select it)
   - The pipeline should now deploy your Databricks artifacts  

- Setting Approvals (so your pipeline does not deploy to QA or Prod without an Approval)
  - In Azure DevOps click on the Environments menu on the left
  - Click on an Environment
  - Clickon the "..." in the top right
  - Select on Approvals and checks
  - Click on Approvals


## What Happens during the Pipeline
- An Azure Resource Group is created (if it does not exist)
  - The Dev stage creates a resouce group named "Databricks-MyProject-Dev"
  - The QA stage creates a resouce group named "Databricks-MyProject-QA"
  - The QA stage creates a resouce group named "Databricks-MyProject-Prod"
  - You can change these to your naming schema if you prefer

- An Azure Databricks workspace is created
  - The Dev stage creates a resouce group named "Databricks-MyProject-Dev"
  - The QA stage creates a resouce group named "Databricks-MyProject-QA"
  - The QA stage creates a resouce group named "Databricks-MyProject-Prod"
  - You can change these to your naming schema if you prefer

- An Azure KeyVault is created
  - The Dev stage creates a resouce group named "KeyVault-MyProject-Dev"
  - The QA stage creates a resouce group named "KeyVault-MyProject-QA"
  - The QA stage creates a resouce group named "KeyVault-MyProject-Prod"
  - You can change these to your naming schema if you prefer

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

- Jobs are deployed
   - The script obtains an Azure AD authorization token using the Service Principal in KeyVault.  This token is then used to call the Databricks REST API
   - Jobs are deployed as follows:
      - Get the list of Jobs and Clusters (we need this for cluster ids)
      - Process the each jobs.json
      - Search the list of jobs based upon the job name
      - If the jobs does not exists
         - If there the attribute "existing_cluster_id" exists in the JSON, replace the value by looking up the Cluster Id and call "Create"
         - NOTE: YOU DO NOT PUT YOUR CLUSTER ID in the existing cluster id field.  You need to put the Cluster name and this script will swap it out for you.  Your cluster id will change per environment.
         - If there is not attribute "existing_cluster_id" the just call "Create"
      - If the job exists
         - If there the attribute "existing_cluster_id" exists in the JSON, replace the value by looking up the Cluster Id
         - Take the entire JSON (in the file) and place it under a new attribute named "new_settings"
         - Inject the attribute "job_id" and set the value
         - Call "Reset" which is "Update"
   ![alt tag](https://raw.githubusercontent.com/AdamPaternostro/Azure-Databricks-Dev-Ops/master/images/Databricks-Jobs-Deployed.png)

- Add you own items!
  - Cut and paste the code from one of the above tasks.
  - Think about the order of operations.  If you are creating a Databricks Job and it references a cluster, then you should deploy the Job after the clusters.
  - NOTE: If you need to inject a value (e.g. Databricks "cluster_id"), you can see the technique in the deploy-clusters.sh script.  Some items liek when you deploy a job might refer a cluster id that you must set during the deployment.



## How to use with your own Databricks code
- Create a resource group in Azure named "Databricks-MyProject-WorkArea"
- Create a Databricks workspace in Azure named "Databricks-MyProject-WorkArea" in the above resource group
- Link your Databricks to source control
   - https://docs.databricks.com/notebooks/github-version-control.html
- Create or import some notebooks (NOTE: This repo has some from Databricks imported for demo purposes)
- Link the Notebook to the Azure DevOps repo 
- Save your Notebook
- Re-run the pipeline and the Notebook should be pushed to Dev, QA and Prod


## Notes
- You can used your own KeyVault
  - The DevOps service principal just needs access to read the keys.
  - Just add the secrets to your KeyVault and grant the service principal access via a policy.
- I do not use the Databricks CLI.  
  - I know there are some DevOps Marketplace items that will deploy Notebooks, etc.  The reason for this is that customers have had issues with the CLI installing on top of one another and their DevOps pipelines break.  The Databricks REST API calls are simple and installing the CLI adds a dependency which could break.


## Potential Improvements
- Have the dev ops pipeline test for the existance of a KeyVault if you want to eliminate the Mode parameter (Intialize-KeyVault | Databricks)
- Seperate the tasks into another repo and call then from this pipeline.  This would make the tasks more re-useable, especially accross many differnet Git repos.  
   - See https://docs.microsoft.com/en-us/azure/devops/pipelines/process/templates?view=azure-devops#use-other-repositories
- Need to update this based upon the new Data Science Git Projects instead of using the Notebook per Git integration.
   - Databricks has a new feature where Notebooks do not need to be indiviually linked.  
- Deal with deploying Hive/Metastore table changes/scripts
- Deal with deploying Mount Points.  
   - Most customers run a Notebook (one time) and then delete it.