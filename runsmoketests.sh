#!/bin/bash

while [[ "$#" -gt 0 ]]; do
  case $1 in
    --apikey) APIKEY="$2"; shift ;;
    --testplanid) TESTPLANID="$2"; shift ;;
    --environmentid) ENVIRONMENTID="$2"; shift ;;
    --maxtimeinmins) MAXTIME="$2"; shift ;;
    --reportfilepath) REPORTFILE="$2"; shift ;;
  esac
  shift
done

echo "Triggering Testsigma test plan..."

# Build JSON payload
if [ -z "$ENVIRONMENTID" ]; then
  PAYLOAD="{\"test_plan_id\": $TESTPLANID}"
else
  PAYLOAD="{\"test_plan_id\": $TESTPLANID, \"environment_id\": $ENVIRONMENTID}"
fi

# Trigger the test
RESPONSE=$(curl -s -X POST "https://api.testsigma.com/api/v1/test-plan-results" \
  -H "accept: application/json" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $APIKEY" \
  -d "$PAYLOAD")

RESULT_ID=$(echo "$RESPONSE" | grep -o '"id":[0-9]*' | cut -d ':' -f2)

echo "Test triggered. Result ID: $RESULT_ID"
echo "Waiting for test completion..."

for ((i=1; i<=MAXTIME; i++)); do
  STATUS=$(curl -s -X GET "https://api.testsigma.com/api/v1/test-plan-results/$RESULT_ID" \
    -H "accept: application/json" \
    -H "Authorization: Bearer $APIKEY" | grep -o '"status":"[^"]*' | cut -d '"' -f4)

  if [[ "$STATUS" == "STATUS_COMPLETED" ]]; then
    echo "Test completed successfully."
    break
  fi

  echo "Waiting... ($i minute)"
  sleep 60
done

# Optional: Download JUnit report
curl -s -X GET "https://api.testsigma.com/api/v1/test-plan-results/$RESULT_ID/junit" \
  -H "Authorization: Bearer $APIKEY" > "$REPORTFILE"

echo "Report saved to $REPORTFILE"
