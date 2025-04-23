$resourceGroup = "Test-RG"
$location = "eastus"
$acrName = "myacr$((Get-Random -Maximum 99999))"  # Ensure globally unique
$aksName = "myAksCluster"
$spName = "github-deploy"

Write-Host "Using ACR: $acrName"
Write-Host "============================"

# ==== Login to Azure ====
Write-Host "Logging in to Azure..."
az login

# ==== Get Subscription ID ====
$subscriptionId = az account show --query id -o tsv

# ==== Create Resource Group ====
Write-Host "Creating Resource Group..."
az group create --name $resourceGroup --location $location

# ==== Create ACR ====
Write-Host "Creating Azure Container Registry..."
az acr create --resource-group $resourceGroup --name $acrName --sku Basic

# ==== Enable ACR Admin Access ====
Write-Host "Enabling ACR admin access..."
az acr update -n $acrName --admin-enabled true

# ==== Get ACR Credentials ====
$acrUsername = az acr credential show -n $acrName --query username -o tsv
$acrPassword = az acr credential show -n $acrName --query "passwords[0].value" -o tsv

# ==== Create AKS ====
Write-Host "Creating AKS cluster..."

az aks create `
  --resource-group $resourceGroup `
  --name $aksName `
  --node-count 1 `
  --node-vm-size Standard_B8ms `
  --generate-ssh-keys
  # --enable-addons monitoring


# ==== Attach ACR to AKS ====
Write-Host "Attaching ACR to AKS..."
az aks update `
  --name $aksName `
  --resource-group $resourceGroup `
  --attach-acr $acrName

# ==== Create Service Principal ====
Write-Host "Creating GitHub Actions service principal..."
$azureCredentials = az ad sp create-for-rbac `
  --name $spName `
  --role contributor `
  --scopes "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup" `
  --sdk-auth

# ==== Output GitHub Secrets ====
Write-Host "`n============================"
Write-Host " Copy these GitHub Secrets into your repository:`n"
Write-Host " ACR_USERNAME: $acrUsername"
Write-Host " ACR_PASSWORD: $acrPassword"
Write-Host " AZURE_CREDENTIALS (JSON):"
Write-Output $azureCredentials
Write-Host "`n============================"
