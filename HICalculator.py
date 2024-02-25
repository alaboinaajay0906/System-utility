import pandas as pd
import math
# Read Excel file
dataframe= pd.read_excel('DataAnalytics.xlsx')
print(f"+{'-' * 33}+\n| Data Analyitcs Calculation |\n+{'-' * 33}+")
print("Given input data in excel")
# Getting the cell value of rowxcolumn=2xC "Enter the input" by using index of row and column (index number=actual row number-1,same for column)
cell_value1 = dataframe.iat[0, 2]
if math.isnan(cell_value1):
    cell_value1=0
# Getting the cell value of rowxcolumn=2xD "Weightage(%)" by using index of row and column (index number=actual row number-1,same for column)
cell_value2= dataframe.iat[0, 3]
if math.isnan(cell_value2):
    cell_value2=0
print("1.Parameter1 =", cell_value1)
#Calculating the score of each paramter
p1 = 4 if cell_value1 > 2 else (3 if 1.5 <= cell_value1 <= 2 else (2 if 1 <= cell_value1 <= 1.5 else (1 if 0.5 <= cell_value1 <= 1 else 0)))
w1 = cell_value2
#The above code snippet Repeated for each individual parameter
cell_value1 = dataframe.iat[1, 2]
if math.isnan(cell_value1):
    cell_value1=0
cell_value2 = dataframe.iat[1, 3]
if math.isnan(cell_value2):
    cell_value2=0
print("2.Parameter1 =", cell_value1)
p2 = 4 if cell_value1 > 7 else (3 if 5.1 <= cell_value1 <= 7 else (2 if 3.1 <= cell_value1 <= 5 else (1 if 1.1 <= cell_value1 <= 3 else 0)))
w2 = cell_value2
cell_value1 = dataframe.iat[2, 2]
if math.isnan(cell_value1):
    cell_value1=0
cell_value2 = dataframe.iat[2, 3]
if math.isnan(cell_value2):
    cell_value2=0
print("3.Parameter3 =", cell_value1)
p3 = 4 if cell_value1 > 7 else (3 if 1.01 <= cell_value1 <= 1.5 else (2 if 0.51 <= cell_value1 <= 1 else (1 if 0.3 <= cell_value1 <= 0.5 else 0)))
w3 = cell_value2
cell_value1 = dataframe.iat[3, 2]
if math.isnan(cell_value1):
    cell_value1=0
cell_value2 = dataframe.iat[3, 3]
if math.isnan(cell_value2):
    cell_value2=0
print("4.Parameter4 =", cell_value1)
p4 = 4 if cell_value1 > 61 else (3 if 45.01 <= cell_value1 <= 60.9 else (2 if 30.01 <= cell_value1 <= 45 else (1 if 15 <= cell_value1 <= 30 else 0)))
w4 = cell_value2
cell_value1 = dataframe.iat[4, 2]
if math.isnan(cell_value1):
    cell_value1=0
cell_value2 = dataframe.iat[4, 3]
if math.isnan(cell_value2):
    cell_value2=0
print("5.Parameter5 = ",cell_value1)
p5 = 4 if cell_value1 > 96 else (3 if 90.01 <= cell_value1 <= 95.9 else (2 if 85.01 <= cell_value1 <= 90 else (1 if 80 <= cell_value1 <= 85 else 0)))
w5 = cell_value2
#Creating a array/list for storing the the scorese & weighatages
individual_scores = [p1, p2, p3, p4, p5]
weightages = [w1, w2, w3, w4, w5]
#Overall HI Calculation note: expression using for loop and zip function (means merging two array/lists/tuples together)
HI = sum(p * w / 100 for p, w in zip(individual_scores, weightages))#Creating a array/list for storing the the scorese & weighatages
individual_scores = [p1, p2, p3, p4, p5]
weightages = [w1, w2, w3, w4, w5]
#Overall HI Calculation note: expression using for loop and zip function (means merging two array/lists/tuples together)
HI = sum(p * w / 100 for p, w in zip(individual_scores, weightages))
hi = round(HI,2)
#Printing the Health index
if hi is not None:
    print(f"\033[1m Health index score:{hi} \033[0m")
    if 0 <= hi < 1:
        print("\033[32m Quality : Very Good")
    elif 1 <= hi < 2:
        print("\033[92m Quality : Good")
    elif 2 <= hi < 3:
        print("\033[93m Quality : Fair")
    elif 3 <= hi < 4:
        print("\033[91m Quality : Poor")
    else:
        print("\033[91m Quality : Unsafe")
else:
    print("No score found.")


