# AKS API Connectivity

This repository provides a bicep template to deploy an AKS cluster scenario for AKS API connectivity issues.

Clone the repo, go to the directory, and run:

```plain-text
az deployment sub create --name <DEPLOYMENT_NAME> -l <LOCATION> --template-file main.bicep
```

Note: Currently all files are referencing canadacentral location, this can be overwritten using the parameters option like this "--parameters location='eastus2'".
