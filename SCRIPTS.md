Starting with plain cents 6.5 installations on all nodes with network access possible through ssh to each of the machines
we have one headnode, a couple of computenodes and a storagenode in our example system

In this script we will setup the basic installation scripts for automated and convenient deployment of software on all nodes. 

TODO: test the new install scripts: install_binary.sh install_source.sh

* log into headnode, update, install some important packages
```bash
$ yum update
$ yum install bind-utils
```
fix locale problems (for modern perl) in centos 6.5
```bash
$ vi /etc/sysconfig/i18n
```
add line
```bash
LC_CTYPE="en_US.UTF-8"
```

define a place where to store our scripts and beowolf cluster config files (you can change this)
```bash
$ export BEO_SCRIPTS=/opt/beowolf-scripts
$ export BEO_CFG_DIR=/opt/beowolf-cfg
```

now setup some important things regarding new folders
```bash
$ mkdir -p $BEO_SCRIPTS
$ mkdir -p $BEO_CFG_DIR

$ echo "
export BEO_SCRIPTS=$BEO_SCRIPTS
export BEO_NODE_CFG=$BEO_CFG_DIR/nodelist.txt
" >> $BEO_SCRIPTS/beo_env.sh
$ chmod +x $BEO_SCRIPTS/beo_env.sh
$ source $BEO_SCRIPTS/beo_env.sh
$ echo PATH=$BEO_SCRIPTS:$PATH >> /etc/environment
```

this creates some setup for our beowolf cluster.
After terminating ssh session type
```bash
$ /opt/beowolf-scripts/beo_env.sh
```
for reintalization of the beowolf settings

* make list of available node domains and synonyms (extend this list if you add nodes later), please change this list for your needs!
* syntax is \<alias for hostname\> \<short alias/shortname\> \<true hostname in the network\> \<type of\>
	
```bash
echo "headnode        hdn    sc-headnode 
computenode1    cn1    sc-computenode1
computenode2    cn2    sc-computenode2
storagenode     sn     sc-storagenode
" > $BEO_NODE_CFG
```

* update our nodelist file with IPs and update /etc/hosts
create file $BEO_SCRIPTS/ext_nodelist_ip.sh 

```bash
vi $BEO_SCRIPTS/ext_nodelist_ip.sh
```

and put in content
```bash

#!/bin/bash

if [ -z "$1" ] && [ -f "$1"]
  then
    echo "Please provide nodelist text file"
    exit 1;
fi

NODE_CFG=$1
NEW_FILE=$NODE_CFG'.TMP'

echo "Reading in file "$NODE_CFG;
while read host alias domain
do
    echo $domain
    #skip empty lines
    [ -z $host ] && [ -z $alias] && [ -z $domain] &&  continue
     IP=$(nslookup $domain | xargs | sed 's/.*Address: \([0-9.]*\).*/\1/g')
     FQDN=$(nslookup $IP | xargs | sed 's/.*name = \(.*\)\./\1/g')
     # this is very important to put the FQDN first in the hosts file!!!
     # otherwise you will run into trouble when using hostbased authentication
     echo $IP' '$FQDN  >> /etc/hosts
     echo $IP' '$host  >> /etc/hosts
     #make the same for the alias..we will later query this often
     echo $IP' '$alias  >> /etc/hosts
     echo $host' '$alias' '$domain' '$FQDN' '$IP >> $NEW_FILE
done < "$NODE_CFG"
mv $NEW_FILE $NODE_CFG
```
exec it now (needs write access to /etc/hosts , use root account)
```bash
chmod +x $BEO_SCRIPTS/ext_nodelist_ip.sh
sudo $BEO_SCRIPTS/ext_nodelist_ip.sh $BEO_NODE_CFG
```
afterwards please make sure that the fully qualified name of a server is on top of all other aliases in /etc/hosts, look into manually!
this is crucial to make host based authentication work, otherwise there can be permission problems when trying passwordless hostbased auth.
correct would be for example:
```bash
123.123.123.123   hoschi.bock.inet.telnet.de
123.123.123.123   hoschi.bock
123.123.123.123   hoschi
```
vs wrong:
```bash
123.123.123.123   hoschi
123.123.123.123   hoschi.bock.inet.telnet.de
123.123.123.123   hoschi.bock
```



* write a script which returns true domain name for given alias
create file $BEO_SCRIPTS/get_domain_for_alias.sh
```bash 
#!/bin/bash

while read host alias domain fqdn ip 
do
    #skip empty lines
    [ -z $host ] && [ -z $alias] && [ -z $domain] [ -z $fqdn] &&  continue
    [ "$alias" == "$1" ] && echo $fqdn
done < $BEO_NODE_CFG
```
chmod +x  $BEO_SCRIPTS/get_domain_for_alias.sh

* write another one which gets the full qualified name


* write following scripts to automate server installation (execute commands on several machines)
 create following file 
 
```bash
 vi $BEO_SCRIPTS/node_executor.sh
```
and put in content
```bash
#!/bin/bash
# first parameter: a comma seperated list of host names (i use aliases for this)
# to execute this script
# second parameter: the command one wants to execute on all nodes put into quotes
# e.g. ./node_executor.sh hdn,cn1,sn wget http://download.me/test.tar.gz -C /tmp
hosts="$1"
cmdline="$2"

if [ -z "$hosts" ]
  then
    echo "Please enter comma separated list of hostnames 'storagenode1,storagenode2'"
    exit 1
fi
if [ -z "$cmdline" ]
  then
    echo "Please enter the command you want to execute remotely"
    exit 1
fi


array=(${hosts//,/ })
for i in "${!array[@]}"
do
   cmdline="$cmdline"
   ssh ${array[i]} $cmdline
done
```
make executable
```bash
$ chmod +x $BEO_SCRIPTS/node_executor.sh
```


* write following scripts to automate server installation (copy files on several machines)
create following file 
```bash
$ vi $BEO_SCRIPTS/node_copier.sh
```
and put in content
```bash
#!/bin/bash
# first parameter: a comma seperated list of host names (i use aliases for this)
# to execute this script
# second parameter: the file/dir one wants to copy on all nodes from local one
# will be put in the same directory as on the local machine
# put them in quotes and then spaces if you want to copy more than one
# e.g. ./node_copier.sh hdn,cn1,sn /tmp/test.txt /etc/environment

hosts="$1"
files_to_copy="$2"

if [ -z "$hosts" ]
  then
    echo "Please enter comma separated list of hostnames 'storagenode1,storagenode2'"
    exit 1
fi
if [ -z "$files_to_copy" ]
  then
    echo "Please enter the files you want to copy to remote servers (separated by blank)"
    exit 1
fi

host_array=(${hosts//,/ })
file_array=(${files_to_copy// / })
for i in "${!host_array[@]}"
do
    for j in "${!file_array[@]}"
    do 
     #echo "scp ${file_array[j]} ${host_array[i]}:"
     scp -r ${file_array[j]} ${host_array[i]}:
    done
done
```

make executabe
```bash
chmod +x $BEO_SCRIPTS/node_copier.sh
```


* write following scripts to automate server installation (append text to single file on several machines)
create following file
```bash
$ vi $BEO_SCRIPTS/node_append.sh
```
put in content
```bash
#!/bin/bash

# first parameter: a comma seperated list of host names (i use aliases for this)
# to execute this script
# second parameter: the file one wants to append data to it from a local stdin
# e.g. cat ~/.ssh/id_rsa.pub | /node_append.sh hdn,cn1,sn "~/.ssh/id_rsa.pub"
# please note: if the file you want to append does not exist, it will be created

hosts="$1"
file="$2"

if [ -z "$hosts" ]
  then
    echo "Please enter comma separated list of hostnames 'storagenode1,storagenode2'"
    exit 1
fi
if [ -z "$file" ]
  then
    echo "Please enter the file you want to append TO remotely, use quotes surrounding it"
    exit 2
fi

TEMPFILE="/tmp/$(basename $0).$$.tmp"
(cat  < /dev/stdin) > $TEMPFILE
array=(${hosts//,/ })
for i in "${!array[@]}"
do
    cmdline="if [ ! -f \"$file\" ]; then touch $file; else cp $file $file.ORG; fi; cat - >> $file"
    cat $TEMPFILE | ssh ${array[i]} $cmdline
done
rm $TEMPFILE
```

make executable
```bash
chmod +x $BEO_SCRIPTS/node_append.sh
```

Now that we have set up all our scripts we can start installing the cluster software
for this refer to the next document BASIC_CLUSTER.md

