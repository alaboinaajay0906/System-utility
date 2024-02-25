import pandas as pd
from sqlalchemy import create_engine, text
from datetime import datetime, timedelta
from tabulate import tabulate
import sys

# Data base connection credentials
db_params = {
    "host": "192.168.60.172", # replace with your database host ip
    "database": "rmeyedemo",  # replace with your database name
    "user": "rmtest",         # replace with your database user
    "password": "hotandcold", # replace with your database password
    "port": 5432,             # replace with your database server port
}
# Create the database connection
dbConn = create_engine(
    f'postgresql://{db_params["user"]}:{db_params["password"]}@{db_params["host"]}:{db_params["port"]}/{db_params["database"]}')
try:
    dbConn.connect()
    print("Connection successful")
except Exception as e:
    print(f"Connection error! Please check the data base connection credentials {e}")

# operation types
# action=int(input("Please select the operation you want to perform.\n1.SELECT\n2.UPDATE\n3.DELETE\n4.INSERT"))

# Fetch the data of particular table    
query = "select *from public.assets" # replace with your actual query
dataFrame = pd.read_sql(query, dbConn)
print(dataFrame)
# convert the dataFrame data into table form data for clear view and replace with your actual column names in below list
column_names = ["ID", "Asset Name", " create time", "update Time", "author", "status id", "Asset type name", "Display Name", "Parent Asset ID"]
table = tabulate(dataFrame, headers=column_names, tablefmt="pretty")
print(table)

# save the table data into a text file (replaces the old data with new data)
file_path = 'C://Users//hp//Documents//Json//query.txt'
with open(file_path,'w',encoding='utf-8') as file:
    file.write(table)
    sys.exit()

    
