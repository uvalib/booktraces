if [ -z "$DOCKER_HOST" ]; then
   echo "ERROR: no DOCKER_HOST defined"
   exit 1
fi

# set the definitions
INSTANCE=booktraces
NAMESPACE=uvadave

# environment attributes
DB_ENV="-e DBHOST=$DBHOST -e DBNAME=$DBNAME -e DBUSER=$DBUSER -e DBPASSWD=$DBPASSWD"
RUNTIME_ENV="-e RAILS_ENV=production -e SECRET_KEY_BASE=$SECRET_KEY_BASE -e RAILS_LOG_TO_STDOUT=y -e RAILS_SERVE_STATIC_FILES=y"

docker run -t -i -p 8224:3000 $DB_ENV $RUNTIME_ENV $NAMESPACE/$INSTANCE /bin/bash -l
