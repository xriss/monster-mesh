cd `dirname $0`


./box-up &

while ! ssh -p 5522 pi@localhost " echo BOX UP "
do
    sleep 1
    echo "Retrying ssh login ..."
done


./08-mesh-app.sh

./box-down
