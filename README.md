# Data API builder: AdventureWorks LT

The sample database Adventure Works LT exposed as a REST and GraphQL API via Data API builder

## Create database

Create an Azure SQL database using the AdventureWorksLT sample database. You can follow the instructions in the following article: [Quickstart: Create a single database - Azure SQL Database](https://learn.microsoft.com/azure/azure-sql/database/single-database-create-quickstart?view=azuresql&tabs=azure-portal). Make sure to allow Azure Service to connect to the database, by selecting **Yes** for the **Allow Azure services to access server** option.

## Create user

[Connect to the created Azure SQL database](https://learn.microsoft.com/azure-data-studio/quickstart-sql-database?view=sql-server-ver16) and run the following script to create a user:

```sql
create user dab_adw_user with password = '2_we2KWE-1S!cca';
grant select on schema::SalesLT to dab_adw_user;
```

## Deploy the Azure resources

In a Linux shell (using Linux, [WSL](https://learn.microsoft.com/windows/wsl/install) or the [Cloud Shell](https://azure.microsoft.com/get-started/azure-portal/cloud-shell/)) make sure you have [AZ CLI](https://learn.microsoft.com/cli/azure/) installed and then run the `azure-deploy.sh` script. If it is the first time you're running the script, it will create a `.env` file and then stop.

Fill the `.env` file with the required values and run the script again. The connection string for the Azure SQL database can be found in the Azure portal, in the Azure SQL database blade, under the **Connection strings** section. Make sure to use the created `dab_adw_user`. For example:

```
MSSQL='Server=<server>.database.windows.net;Database=AdventureWorksLT;User ID=dab_adw_user;Password=2_we2KWE-1S!cca;'
```

This will create the following resources: 

- Resource Group
- Storage Account
- App Service Plan ([B1](https://azure.microsoft.com/en-us/pricing/details/app-service/linux/#pricing))
- Web App

Data API builder will be executed as a Docker container in the Web App.

## Test the deployment

The deployment will pull the Docker image from `mcr.microsoft.com/azure-databases/data-api-builder:latest`. Please wait a couple of minutes before testing the API, to allow the Docker image to be pulled and the container to be started.

You can test if the everything is up and running by running thw following command:

```text
curl https:/<web-app-name>.azurewebsites.net/ 
```

and it should return the string "Healthy". If it doesn't, wait for a few seconds and try again, as the container may still be starting.

Once everything has been deployed, you can test the API by opening the following URL in a browser:

```text
http://<web-app-name>.azurewebsites.net/swagger
```

or, for GraphQL

```text
http://<web-app-name>.azurewebsites.net/graphql
```

## Additional Resources

To automatically expose all tables in the database, you can start from the `sql-to-dab-config.sql` sample scripts. Make sure to review the script and customize it to your needs. For example, you may want to rename and customize the relationships created from the `Address` entity to the `SalesOrderHeader` entity, to set a better name of the relationship based on the `ShipToAddressID` and `BillToAddressID` fields.
