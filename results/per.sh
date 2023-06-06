#!/bin/bash

API_KEY=""

REPORT_ID=""
OUTPUT_FILE="report.csv"

# Cloud Conformity API endpoint to get the download URL
API_ENDPOINT="https://ap-southeast-2.cloudconformity.com/v1/reports/${REPORT_ID}/csv"

# Fetch the download URL using curl and pass the API key as a header
DOWNLOAD_URL=$(curl -H "Authorization: ApiKey ${API_KEY}" "${API_ENDPOINT}" | jq -r '.url')

# Download the CSV file using curl with the obtained download URL
curl -L --compressed "${DOWNLOAD_URL}" > "${OUTPUT_FILE}" 

# Check if the download was successful
if [ $? -eq 0 ]; then
    echo "CSV file downloaded successfully."
else
    echo "Failed to download the CSV file."
fi

