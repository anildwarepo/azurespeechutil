#!/bin/bash

# Define the subscription key and API region
SUBSCRIPTION_KEY="<>"
API_REGION="westus2"
API_BASE_URL="https://$API_REGION.api.cognitive.microsoft.com/speechtotext/v3.1"

# Step 1: Get all transcriptions and extract their IDs
transcription_ids=$(curl -s -X GET "$API_BASE_URL/transcriptions" \
-H "Ocp-Apim-Subscription-Key: $SUBSCRIPTION_KEY" | jq -r '.values[].self | split("/")[-1]')

# Step 2: Loop through each transcription ID
for transcription_id in $transcription_ids; do
    echo "Processing transcription ID: $transcription_id"

    # Step 3: Get the files for the transcription ID
    file_response=$(curl -s -X GET "$API_BASE_URL/transcriptions/$transcription_id/files" \
    -H "Ocp-Apim-Subscription-Key: $SUBSCRIPTION_KEY")

    # Extract the first file ID (assuming there's only one file for simplicity)
    file_id=$(echo "$file_response" | jq -r '.values[0].self | split("/")[-1]')
    
    # Step 4: Get the file details and extract the content URL
    curl -s -X GET "$API_BASE_URL/transcriptions/$transcription_id/files/$file_id" \
    -H "Ocp-Apim-Subscription-Key: $SUBSCRIPTION_KEY" -o response.json

    content_url=$(jq -r '.links.contentUrl' response.json)

    # Step 5: Download the content from the extracted URL
    curl -s -o transcription_result.json "$content_url"

    # Step 6: Display the recognized phrases using jq
    echo "Recognized phrases for transcription ID: $transcription_id"
    cat transcription_result.json | jq '.recognizedPhrases[] | {recognitionStatus, speaker, display: .nBest[0].display}'
    echo ""
done