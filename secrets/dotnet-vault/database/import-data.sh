# wait for the SQL Server to come up
sleep 15s

# run the setup script to create the DB and the schema in the DB
/opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P Testing!123 -d master -i setup.sql

# upload projects.csv data
/opt/mssql-tools/bin/bcp Projects in /usr/src/app/projects.csv -S localhost -U sa -P Testing!123 -d HashiCorp -c -t ','