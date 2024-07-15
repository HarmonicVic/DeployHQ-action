#!/bin/sh

set -e

######## Check for required/optional inputs. ########


# Check if the User ID is set (Required).
if [ -z "$DEPLOYHQ_USER_ID" ]; then
  echo "DEPLOYHQ_USER_ID is not set. Quitting."
  exit 1
fi

# Check if the Api Token is set (Required). 
# Token must be associated to DEPLOYHQ_USER_ID.
if [ -z "$DEPLOYHQ_API_TOKEN" ]; then
  echo "DEPLOYHQ_API_TOKEN is not set. Quitting."
  exit 1
fi

# Check if DeployHQ subdomain is set (Required) (also called DeployHQ account).
# Usage: https://${DEPLOYHQ_SUBDOMAIN}.deployhq.com.
if [ -z "$DEPLOYHQ_SUBDOMAIN" ]; then
  echo "DEPLOYHQ_SUBDOMAIN is not set. Quitting."
  exit 1
fi

# Check if Project ID is set (Required).
# Usage: https://${DEPLOYHQ_SUBDOMAIN}.deployhq.com/projects/${DEPLOYHQ_PROJECT_ID}.
if [ -z "$DEPLOYHQ_PROJECT_ID" ]; then
  echo "DEPLOYHQ_PROJECT_ID is not set. Quitting."
  exit 1
fi

# Check if Server UUID is set (Required) (`parent_identifier` in the API docs). 
# This ID represents the server or server group to deploy to.
if [ -z "$DEPLOYHQ_PARENT_ID" ]; then
  echo "DEPLOYHQ_PARENT_ID is not set. Quitting."
  exit 1
fi

# Check if Start revision is set (Required). 
# Can be set to blank for a complete deployment.
if [ -z "$DEPLOYHQ_START_REVISION" ] && [ "$DEPLOYHQ_START_REVISION" != "" ]; then
  echo "DEPLOYHQ_START_REVISION is not set. Quitting."
  exit 1
fi

# Check if Start revision is set (Required). 
if [ -z "$DEPLOYHQ_END_REVISION" ]; then
  echo "DEPLOYHQ_END_REVISION is not set. Quitting."
  exit 1
fi

# # Check if Deploy From Scratch is set.
# if [ -z "$DEPLOY_FROM_SCRATCH" ]; then
#   echo "DEPLOY_FROM_SCRATCH is not set. Setting to false."
#   DEPLOY_FROM_SCRATCH='false'
# fi

# # Check if Trigger Notifications is set.
# if [ -z "$TRIGGER_NOTIFICATIONS" ]; then
#   echo "TRIGGER_NOTIFICATIONS is not set. Setting to true."
#   TRIGGER_NOTIFICATIONS='true'
# fi

set -- --data '{"deployment":{ "parent_identifier":"'"${DEPLOYHQ_PARENT_ID}"'","start_revision":"'"${DEPLOYHQ_START_REVISION}"'","end_revision":"'"${DEPLOYHQ_END_REVISION}"'"}}'

######## Call the API and store the response for later. ########
# API docs: https://www.deployhq.com/support/api/deployments/create-a-new-deployment
 
HTTP_RESPONSE=$(curl -sS "https://${DEPLOYHQ_SUBDOMAIN}.deployhq.com/projects/${DEPLOYHQ_PROJECT_ID}/deployments/" \
                    -H "Content-type: application/json" \
                    -H "Accept: application/json" \
                    --user "${DEPLOYHQ_USER_ID}:${DEPLOYHQ_API_TOKEN}" \
                    -w "HTTP_STATUS:%{http_code}" \
                    "$@")

######## Format response for a pretty command line output. ########

# Store result and HTTP status code separately to appropriately throw CI errors.
# https://gist.github.com/maxcnunes/9f77afdc32df354883df

HTTP_BODY=$(echo "${HTTP_RESPONSE}" | sed -E 's/HTTP_STATUS\:[0-9]{3}$//')
HTTP_STATUS=$(echo "${HTTP_RESPONSE}" | tr -d '\n' | sed -E 's/.*HTTP_STATUS:([0-9]{3})$/\1/')

# Fail pipeline and print errors if API doesn't return an OK status.
if [ "${HTTP_STATUS}" -eq "200" ]; then
  echo "Successfully triggered deployment on DeployBot!"
  echo "${HTTP_BODY}"
  exit 0
else
  echo "Trigger deployment failed. API response was: "
  echo "${HTTP_BODY}"
  exit 1
fi