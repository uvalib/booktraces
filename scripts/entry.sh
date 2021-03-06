# remove stale pid files
rm -f $APP_HOME/tmp/pids/server.pid > /dev/null 2>&1

# run a migration if necessary
rake db:migrate

# run the server
rails server -b 0.0.0.0 -p 8080
