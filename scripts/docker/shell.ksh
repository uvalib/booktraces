if [ -z "$DOCKER_HOST" ]; then
   echo "ERROR: no DOCKER_HOST defined"
   exit 1
fi

# set the definitions
INSTANCE=booktraces
NAMESPACE=uvadave

# environment attributes
#DOCKER_ENV="-e API_TOKEN=$API_TOKEN -e DEPOSITREG_URL=$DEPOSITREG_URL -e USERINFO_URL=$USERINFO_URL"

docker run -t -i -p 8224:3000 $DOCKER_ENV $NAMESPACE/$INSTANCE /bin/bash -l
