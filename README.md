# k8s

<h1> The logic of the above statefulset is, </h1>

Create 2 Init containers.
The Mysql container executes the given shell commands only, instead of its default script/command provided with the image.
i) The commands derives ordinal# from the hostname of the container.
ii) If the ordinal# = 0, it copies the configmap - primary.cnf into /mnt/conf.d, else “replica.cnf” to /mnt/conf.d.
Generates SERVER_ID from the ordinal# and writes into server-id.cnf.

The xtrabackup container does the following:
if its a replica db (ordinal# > 0):

			Clone data from the previous peer ($ordinal-1) using, 

ncat --recv-only mysql-$(($ordinal-1)).mysql 3307 | xbstream -x -C /var/lib/mysql
# Prepare the backup.
xtrabackup --prepare --target-dir=/var/lib/mysql         


If, for any reason, the init containers fail, the entire pod will fail and Kubernetes will  attempt to restart.

2) About the Main containers specified …….
   
  i) mysql:

Launches the container with the mysql image whose default script will check whether the database files already there @/var/lib/mysql/mysql exist in the pod. If so, it will not create a new database, otherwise it will (for the first time when the statefuset is created)

ii) xtrabackup:

Those pod’s having replica databases will initiate replication. The master host is identified by the fixed name which looks like, MASTER_HOST='mysql-0.mysql'.

Starts a server on all the containers, regardless whether they are primary or replica pods. Every replica database should support  its peer ( the other replica databases) in replication so that the primary database won’t get overloaded.

          exec ncat --listen --keep-open --send-only --max-conns=1 3307 -c \
            "xtrabackup --backup --slave-info --stream=xbstream --host=127.0.0.1 --user=root"         



Sending Client Traffic:


Connecting to Primary (mysql-0):

kubectl run mysql-client --image=mysql:5.7 -i --rm --restart=Never --\
  mysql -h mysql-0.mysql <<EOF
CREATE DATABASE test;
CREATE TABLE test.messages (message VARCHAR(250));
INSERT INTO test.messages VALUES ('hello');
EOF



Connecting to any servers:

kubectl run mysql-client --image=mysql:5.7 -i -t --rm --restart=Never --\
  mysql -h mysql-read -e "SELECT * FROM test.messages"


Scaling the number of replicas:

kubectl scale statefulset mysql --replicas=3


