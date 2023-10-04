#!/bin/bash

# Strict mode, fail on any error
set -euo pipefail

# Azure configuration
FILE=".env"
if [[ -f $FILE ]]; then
	echo "loading from .env"
    eval $(egrep "^[^#;]" $FILE | tr '\n' '\0' | xargs -0 -n1 | sed 's/^/export /')
else
	cat << EOF > .env
RESOURCE_GROUP=""
APP_NAME=""
APP_PLAN_NAME=""
STORAGE_ACCOUNT=""
LOCATION=""
CREATEDBY=""
MSSQL="Server=.database.windows.net;Database=;User ID=;Password=;"
EOF
	echo "Enviroment file (.env) not detected."
	echo "Please configure values for your environment in the created .env file and run the script again."
	echo "Read the docs/running-in-azure.md to get info on needed enviroment variables."
	exit 1
fi

IMAGE_NAME='mcr.microsoft.com/azure-databases/data-api-builder:latest'
DAB_CONFIG_FILE="dab-config.json"

echo "starting"
cat << EOF > log.txt
EOF

echo "creating resource group '$RESOURCE_GROUP'" | tee -a log.txt
az group create -g $RESOURCE_GROUP --location $LOCATION --tags CreatedBy=$CREATEDBY \
    -o json >> log.txt

echo "creating storage account: '$STORAGE_ACCOUNT'" | tee -a log.txt
az storage account create -n $STORAGE_ACCOUNT -g $RESOURCE_GROUP --allow-blob-public-access false --sku Standard_LRS --tags CreatedBy=$CREATEDBY \
	-o json >> log.txt	
	
echo "retrieving storage connection string" | tee -a log.txt
STORAGE_CONNECTION_STRING=$(az storage account show-connection-string --name $STORAGE_ACCOUNT -g $RESOURCE_GROUP -o tsv)

echo 'creating file share' | tee -a log.txt
az storage share create -n config --connection-string $STORAGE_CONNECTION_STRING \
	-o json >> log.txt

echo "uploading configuration file '$DAB_CONFIG_FILE'" | tee -a log.txt
az storage file upload --share-name config --source $DAB_CONFIG_FILE --connection-string $STORAGE_CONNECTION_STRING \
    -o json >> log.txt

echo "creating app plan '$APP_PLAN_NAME'" | tee -a log.txt
az appservice plan create -n $APP_PLAN_NAME -g $RESOURCE_GROUP --sku P1V2 --is-linux --location $LOCATION --tags CreatedBy=$CREATEDBY \
    -o json >> log.txt

echo "retrieving app plan id" | tee -a log.txt
APP_PLAN_ID=$(az appservice plan show -g $RESOURCE_GROUP -n $APP_PLAN_NAME --query "id" --out tsv) 

echo "creating webapp '$APP_NAME'" | tee -a log.txt
az webapp create -g $RESOURCE_GROUP -p "$APP_PLAN_ID" -n $APP_NAME -i "$IMAGE_NAME" --tags CreatedBy=$CREATEDBY \
    -o json >> log.txt

sleep 15s

echo "retrieving storage key" | tee -a log.txt
ASAK=$(az storage account keys list -g $RESOURCE_GROUP -n $STORAGE_ACCOUNT --query "[0].value" -o tsv)

echo "configure webapp storage-account" | tee -a log.txt
az webapp config storage-account add -g $RESOURCE_GROUP -n $APP_NAME --custom-id config --storage-type AzureFiles --share-name config --account-name $STORAGE_ACCOUNT --access-key $ASAK --mount-path /App/config \
    -o json >> log.txt

echo "configure webapp appsettings (WEBSITES_PORT)" | tee -a log.txt
az webapp config appsettings set -g $RESOURCE_GROUP -n $APP_NAME --settings WEBSITES_PORT=5000 \
    -o json >> log.txt

echo "configure webapp appsettings (MSSQL)" | tee -a log.txt
az webapp config appsettings set -g $RESOURCE_GROUP -n $APP_NAME --settings MSSQL="$MSSQL" \
    -o json >> log.txt

DAB_CONFIG_FILE_NAME=${DAB_CONFIG_FILE}
echo "updating webapp siteConfig to use $DAB_CONFIG_FILE_NAME" | tee -a log.txt
az webapp update -g $RESOURCE_GROUP -n $APP_NAME --set siteConfig.appCommandLine="dotnet Azure.DataApiBuilder.Service.dll --ConfigFileName /App/config/$DAB_CONFIG_FILE_NAME" \
    -o json >> log.txt

echo "configure cors" | tee -a log.txt
az webapp cors add -g $RESOURCE_GROUP -n $APP_NAME --allowed-origins "*" \
    -o json >> log.txt

echo "done" | tee -a log.txt
