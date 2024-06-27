@echo off
setlocal enabledelayedexpansion

:: Define the subscription key and API region
set SUBSCRIPTION_KEY=<> # Replace with your subscription key
set API_REGION=westus2
set API_BASE_URL=https://%API_REGION%.api.cognitive.microsoft.com/speechtotext/v3.1

:: Step 0: Create a new transcription
curl -X POST "%API_BASE_URL%/transcriptions" ^
-H "Ocp-Apim-Subscription-Key: %SUBSCRIPTION_KEY%" ^
-H "Content-Type: application/json" ^
-d "{\"displayName\":\"Simple transcription\",\"description\":\"Simple transcription description\",\"locale\":\"en-US\",\"contentUrls\":[\"https://github.com/microsoft/batch-processing-kit/blob/master/tests/resources/whatstheweatherlike.wav?raw=true\"],\"properties\":{\"diarizationEnabled\":true,\"diarization\":{\"speakers\":{\"minCount\":1,\"maxCount\":5}}}}"

:: Step 1: Get all transcriptions and extract their IDs
curl -s -X GET "%API_BASE_URL%/transcriptions" -H "Ocp-Apim-Subscription-Key: %SUBSCRIPTION_KEY%" -o transcriptions.json
for /f "delims=" %%i in ('jq -r ".values[].self | split(\"/\")[-1]" transcriptions.json') do (
    set transcription_id=%%i
    echo Processing transcription ID: !transcription_id!

    :: Step 2: Get the files for the transcription ID
    curl -s -X GET "%API_BASE_URL%/transcriptions/!transcription_id!/files" -H "Ocp-Apim-Subscription-Key: %SUBSCRIPTION_KEY%" -o files.json

    :: Extract the first file ID (assuming there's only one file for simplicity)
    for /f "delims=" %%j in ('jq -r ".values[0].self | split(\"/\")[-1]" files.json') do (
        set file_id=%%j

        :: Step 3: Get the file details and extract the content URL
        curl -s -X GET "%API_BASE_URL%/transcriptions/!transcription_id!/files/!file_id!" -H "Ocp-Apim-Subscription-Key: %SUBSCRIPTION_KEY%" -o response.json

        for /f "delims=" %%k in ('jq -r ".links.contentUrl" response.json') do (
            set content_url=%%k

            :: Step 4: Download the content from the extracted URL
            curl -s -o transcription_result.json "!content_url!"

            :: Step 5: Display the recognized phrases using jq
            echo Recognized phrases for transcription ID: !transcription_id!
            jq ".recognizedPhrases[] | {recognitionStatus, speaker, display: .nBest[0].display}" transcription_result.json
            echo.
        )
    )
)

endlocal
pause
