starting with plain cents 6.5 installations on all nodes with network access possible through ssh

* log into headnode, update, install some important packages
```bash
yum update
yum install bind-utils
```
fix locale problems (for modern perl)
```bash
$ vi /etc/sysconfig/i18n
LC_CTYPE="en_US.UTF-8"
```

define a place where to store our scripts and beowolf cluster config file (with env variable BEO_SCRIPTS)
```bash
export BEO_SCRIPTS=/opt/beowolf-scripts
export BEO_CFG_DIR=/opt/beowolf-cfg
```

now setup some important things regarding new folder
```bash
mkdir -p $BEO_SCRIPTS
mkdir -p $BEO_CFG_DIR

echo "
export BEO_SCRIPTS=$BEO_SCRIPTS
export BEO_NODE_CFG=$BEO_CFG_DIR/nodelist.txt
" >> $BEO_SCRIPTS/beo_env.sh
chmod +x $BEO_SCRIPTS/beo_env.sh
source $BEO_SCRIPTS/beo_env.sh
echo PATH=$BEO_SCRIPTS:$PATH >> /etc/environment
```

this creates some setup for our beowolf cluster.
After terminating ssh session type
```bash
source /opt/beowolf-scripts/beo_env.sh
```
for reintalization of the beowolf settings

* make list of available node domains and synonyms (extend this list if you add nodes later)
* syntax is "#<hostname> <alias/shortname> <domainname>"
```bash
echo "headnode        hdn    sc-headnode  
computenode1    cn1    sc-computenode1
computenode2    cn2    sc-computenode2
storagenode     sn     sc-storagenode
" > $BEO_NODE_CFG
```bash


* update our nodelist file with IPs and update /etc/hosts

```bash

echo "
#!/usr/bin/bash

while read host alias domain
do
    #skip empty lines
    [ -z "\$host" ] && [ -z "\$alias"] && [ -z "\$domain"] &&  continue
     IP=\$(nslookup \$domain | xargs | sed 's/.*Address: \([0-9.]*\).*/\1/g')
     echo \$IP' '\$host  >> /etc/hosts
     #make the same for the alias..we will later query this often
     echo \$IP' '\$alias  >> /etc/hosts
     echo \$host' '\$alias' '\$domain' '\$IP >> \$BEO_NODE_CFG'.TMP'
done < \$BEO_NODE_CFG
mv \$BEO_NODE_CFG'.TMP' \$BEO_NODE_CFG
" > $BEO_SCRIPTS/ext_nodelist_ip.sh

chmod +x $BEO_SCRIPTS/ext_nodelist_ip.sh
$BEO_SCRIPTS/ext_nodelist_ip.sh 
```

* build following scripts to automate server installation
```bash
echo "#!/bin/bash

# first parameter: a comma seperated list of host names (i use aliases for this)
# to execute this script
# second parameter: the command one wants to execute on all nodes put into quotes
# e.g. ./exec_on_nodes.sh hdn,cn1,sn "wget http://download.me/test.tar.gz -C /tmp"

if [ -z "$1" ]
  then
    echo "Please enter comma separated list of hostnames 'storagenode1,storagenode2'"
    exit 1
fi
if [ -z "$2" ]
  then
    echo "Please enter the command you want to execute remotely"
    exit 2
fi

hosts=$1

array=(${hosts//:/ })
for i in "${!array[@]}"
do
    echo "ssh ${array[i]} $2"
done
" > $SCRIPTS/node_executor.sh
```


```bash
echo "
#!/bin/bash
# first parameter: a comma seperated ;ist of node aliases to execute this script
# second parameter: the command one wants to execute on all nodes put into quotes
# e.g. ./exec_on_nodes.sh hdn,cn1,sn "wget http://download.me/test.tar.gz -C /tmp"
SCRIPTS=$SCRIPTS
NODE_CFG=$NODE_CFG
NODES_ALIAS=array=(${$1//:/ }) 

CMD=ssh $domain "${@:2}" 

" > $SCRIPTS/exec_on_nodes.sh

```



copy_to_nodes.sh
```bash
#!/bin/bash

source ./copy_all_computenodes.sh $1 $2
rsync -rav $1 storagenode:$2 
```

append_file_on_nodes.sh
```bash
#!/bin/bash

source ./copy_all_computenodes.sh $1 $2
rsync -rav $1 storagenode:$2 
```



make all executable 
```bash
chmod +x ~/scripts/copy_all*.sh ~/scripts/exec_all*.sh
```
export script dir
vi ~/.bash_rc
```bash

```

* generate and share roots ssh key for passwordless access to the nodes (still on headnode) —these are the last times you need to provide root password, afterwards it works without:
```bash
ssh-keygen -t rsa
exec_all_nodes.sh "mkdir -p /root/ssh"
```


* exec on all nodes

* put server names from compute nodes and storage node on nodes



* share root directory on every node using nfs
