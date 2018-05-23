#
#
#

if [ $# -le 0 ]; then
   echo "use: $0 <input name>"
   exit 1
fi

INFILE=$1

if [ ! -f "$INFILE" ]; then
   echo "ERROR: $INFILE is missing or not readable"
   exit 1
fi

if [ -z "$DOCKER_HOST" ]; then
   echo "ERROR: no DOCKER_HOST defined"
   exit 1
fi

docker load -i $INFILE
res=$?
if [ $res -ne 0 ]; then
   echo "ERROR: loading image file $INFILE"
   exit 1
fi

echo "Image loaded from $INFILE"

#
# end of file
#
