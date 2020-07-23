# Azure-Databricks-Dev-Ops
Complete end to end sample of doing DevOps with Azure Databricks.  This is based on working with lots of customers who have requested that they can reference a documented apporach.


## Steps
- Create a resource group in Azure named "Databricks-MyProject-WorkArea"
- Create a Databricks workspace in Azure named "Databricks-MyProject-WorkArea" in the above resource group
- Link your Databricks to source control: https://docs.databricks.com/notebooks/github-version-control.html
- Create or import some notebooks (NOTE: This repo has some from Databricks imported for demo purposes)

## What Happens
- Clusters are deployed
    - New clusters created
    - Existing clusters are updated
    - Clusters are then Stopped (so either change this or understand they are stopped). You might get a cores quota warning, but we will stop the clusters anyway, so it might not be an issue
- Notebooks are deployed
    - The are deployed to the /Users folder?



## Why aren't we using the Azure AD token to login to Databricks API?
- If you are familiar with this (https://docs.microsoft.com/en-us/azure/databricks/dev-tools/api/latest/aad/app-aad-token) you can login to Databricks with an AD token.
- The problem with the token is that it requires an interactive (browser) login.  That does not really work for DevOps...
- I created this a while back (https://github.com/AdamPaternostro/Azure-Databricks-CI-CD-Initial-Token) and I will be using something simular in this template.  We need to create our Databricks workspace via ARM template, but then cannot connect to the workspace without an API key.  We cannot generate a key in Azure, we need to login to the workspace and create the key.  Once we have the key we can place it in KeyVault and then re-run the Pipeline.  So, the very first time, the pipeline will fail and you need to get the key manually so the pipeline can use the value.

## Notes
- This assumes you have a service principal that is a subscription contributor. If not then you need to create the resource group by hand and give the service principal access to the resource group (contributor).