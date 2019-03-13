#!/bin/bash
for value in {1..10}
do
   echo "CALL"
   curl -H "BOOKTRACES_API_KEY: gek5PLK9e87dJhCe8mMm8tfF" http://docker1.lib.virginia.edu:8380/api/detail/E-03078
done
echo All done
