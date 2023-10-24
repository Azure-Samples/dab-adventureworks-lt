# Data API builder: AdventureWorks LT

The sample database Adventure Works LT exposed as a REST and GraphQL API via Data API builder

## Create database

https://learn.microsoft.com/en-us/azure/azure-sql/database/single-database-create-quickstart?view=azuresql&tabs=azure-portal

## Create user

[Connect to the created Azure SQL database](https://learn.microsoft.com/en-us/azure-data-studio/quickstart-sql-database?view=sql-server-ver16) and run the following script to create a user:

```sql
create user dab_adw_user with password = '2_we2KWE-1S!cca';
grant select on schema::SalesLT to dab_adw_user;
```

## Deploy the Azure resources

In a Linux shell (using Linux, [WSL](https://learn.microsoft.com/en-us/windows/wsl/install) or the [Cloud Shell](https://azure.microsoft.com/en-us/get-started/azure-portal/cloud-shell/)) make sure you have [AZ CLI](https://learn.microsoft.com/en-us/cli/azure/) installed and then run the `azure-deploy.sh` script. If it is the first time you're running the script, it will create a `.env` file and then stop.

Fill the `.env` file with the required values and run the script again. This will create the following resources: 

- Resource Group
- Storage Account
- App Service Plan
- Web App

Data API builder will be executed as a Docker container in the Web App.

## Test the deployment

Once everything has been deployed, you can test the API by opening the following URL in a browser:

```http
http://<web-app-name>.azurewebsites.net/swagger
```

or, for GraphQL

```http
http://<web-app-name>.azurewebsites.net/graphql
```

## Additional Resources

To automatically expose all tables in the database, you can start from the `sql-to-dab-config.sql` sample scripts. Make sure to review the script and customize it to your needs. For example, you may want to rename and customize the relationships created from the `Address` entity to the `SalesOrderHeader` entity, to set a better name of the relationship based on the `ShipToAddressID` and `BillToAddressID` fields.
