cd `dirname $0`

echo " building monster-mesh.img from default *mini* raspbian img "


cat ~/.ssh/id_rsa.pub | sshpass -p raspbian ssh -p 5522 root@localhost " cat >> .ssh/authorized_keys "



#ssh -p 5522 root@localhost -c " ls "

