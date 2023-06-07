import pandas as pd

# Read the CSV file into a pandas DataFrame
df = pd.read_csv("report.csv")

# Filter the data for rows where the status is "FAILURE"
failed_resources = df[df["Check Status"] == "FAILURE"]

# Count the number of failed resources for each account name
account_name_counts = failed_resources["Account Name"].value_counts()

# Determine the maximum length of the account name
max_name_length = max(account_name_counts.index.str.len())

# Print the account name and corresponding failed resource counts with aligned spacing
print("AccountName" + " " * (max_name_length - 11) + "FailedResourceCount")
for account_name, count in account_name_counts.items():
    name_padding = " " * (max_name_length - len(account_name))
    print(f"{account_name}{name_padding}\t{count}")
