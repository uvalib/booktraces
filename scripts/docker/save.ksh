#
#
#

if [ -z "$DOCKER_HOST" ]; then
   echo "ERROR: no DOCKER_HOST defined"
   exit 1
fi

# set the definitions
INSTANCE=booktraces
REGISTRY=git.lib.virginia.edu:4567/dpg3k/service-containers

IMAGE=$REGISTRY/$INSTANCE:latest
OUTFILE=$INSTANCE-image.$$

rm -fr $OUTFILE > /dev/null 2>&1
docker save -o $OUTFILE $IMAGE
res=$?
if [ $res -ne 0 ]; then
   echo "ERROR: saving image $IMAGE"
   exit 1
fi

echo "Image saved in $OUTFILE"

#
# end of file
#
