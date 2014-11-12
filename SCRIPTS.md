starting with plain cents 6.5 installations on all nodes with network access possible through ssh to each of the machines
we have one headnode, a couple of computenodes and a storagenode in our example system

TODO: -write a script which can extract the hostname for an given alias (we need this when setting up torque in BASIC_CLUSTER
      -write two script which installs software:
        one which installs binary software
        one which installs source software (compiles) 
        for binary software see something like:
        ```bash
$BEO_SCRIPTS/node_executor.sh "hdn,cn1,cn2" "wget http://downloads.sourceforge.net/project/bowtie-bio/bowtie2/2.2.4/bowtie2-2.2.4-linux-x86_64.zip -P /opt/software/src;\
unzip /opt/software/src/bowtie2-2.2.4-linux-x86_64.zip -d /opt/software;\
echo 'export PATH=\$PATH:/opt/software/bowtie2-2.2.4/' >>/etc/profile.d/bowtie2.sh;\
chmod +x /etc/profile.d/bowtie2.sh;
source /etc/profile.d/bowtie2.sh"
```  
       for source software see:
       cd /opt/software/src
git clone git://github.com/pezmaster31/bamtools.git
mkdir /opt/software/build/bamtools
cd /opt/software/build/bamtools
cmake -DCMAKE_INSTALL_PREFIX:PATH=/opt/software/bamtools /opt/software/src/bamtools
make
make install

echo 'export PATH=\$PATH:/opt/software/bamtools/bin' >>/etc/profile.d/bamtools.sh;
chmod +x /etc/profile.d/bamtools.sh;
source /etc/profile.d/bamtools.sh

$BEO_SCRIPTS/node_copier.sh "cn1,cn2" "/opt/software/src/bamtools"

$BEO_SCRIPTS/node_executor.sh "cn1,cn2" "mkdir /opt/software/build/bamtools;\
cd /opt/software/build/bamtools;\
cmake -DCMAKE_INSTALL_PREFIX:PATH=/opt/software/bamtools /opt/software/src/bamtools;\
make;\
make install;\
echo '/opt/software/bamtools/lib/bamtools' > /etc/ld.so.conf.d/bamtools.conf;\
ldconfig;\
echo 'export PATH=\$PATH:/opt/software/bamtools/bin' >>/etc/profile.d/bamtools.sh;\
chmod +x /etc/profile.d/bamtools.sh;\
source /etc/profile.d/bamtools.sh"
- the scripts will unpack tar, gz, bz2 and zip 
- the script will have a parameter which let you specify: "make,make install,cmake"


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
$ source /opt/beowolf-scripts/beo_env.sh
```
for reintalization of the beowolf settings

* make list of available node domains and synonyms (extend this list if you add nodes later)
* syntax is <hostname> <alias/shortname> <domainname
	
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
#!/usr/bin/bash

while read host alias domain
do
    #skip empty lines
    [ -z $host ] && [ -z $alias] && [ -z $domain] &&  continue
     IP=$(nslookup $domain | xargs | sed 's/.*Address: \([0-9.]*\).*/\1/g')
     echo $IP' '$host  >> /etc/hosts
     #make the same for the alias..we will later query this often
     echo $IP' '$alias  >> /etc/hosts
     echo $host' '$alias' '$domain' '$IP >> $BEO_NODE_CFG'.TMP'
done < $BEO_NODE_CFG
mv $BEO_NODE_CFG'.TMP' $BEO_NODE_CFG
```
exec it now
```bash
chmod +x $BEO_SCRIPTS/ext_nodelist_ip.sh
$BEO_SCRIPTS/ext_nodelist_ip.sh 
```

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

