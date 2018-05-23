#
#
#

if [ -z "$DOCKER_HOST" ]; then
   echo "ERROR: no DOCKER_HOST defined"
   exit 1
fi

# set the definitions
INSTANCE=booktraces

OUTFILE=$INSTANCE-container.$$

# get the image ID if we can find it
IMAGE_ID=$(docker images | grep $INSTANCE | grep latest | awk '{print $3}')

if [ -z "$IMAGE_ID" ]; then
   echo "ERROR: cannot find latest image for $INSTANCE"
   exit 1
fi

rm -fr $OUTFILE > /dev/null 2>&1
docker save -o $OUTFILE $IMAGE_ID
res=$?
if [ $res -ne 0 ]; then
   echo "ERROR: saving image ID $IMAGE_ID"
   exit 1
fi

echo "Image saved in $OUTFILE"

#
# end of file
#
