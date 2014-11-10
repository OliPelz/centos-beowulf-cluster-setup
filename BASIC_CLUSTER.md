* a pbs system consists of the following parts
   server (resource manager), scheduler, mom
   resource manager - manages all available resources e.g. CPU
   scheduler - gets information about free resources from the resource manager and manages the queue
   mom - The function of mom is to place jobs into execution as directed by the server
* Prequesites: execute all steps in SCRIPTS.md

We are beginning by logging in to the headnode. This machine will be used to install and configure all nodes of the cluster.

when logging in head node with a fresh ssh session execute:
```bash
```source /opt/beowolf-scripts/beo_env.sh

if you havent done in SCRIPTS.md, put the beowolf shell script path to PATH variable (only have to do once)
```bash
echo PATH=$BEO_SCRIPTS:$PATH >> /etc/environment
```

* disable selinux on all nodes plus headnode, this has to be done in order that all clustering communication work
  escpecially the passwordless login from the headnode to all other nodes
```bash
cp /etc/selinux/config /etc/selinux/config.ORG
sed -i 's/^SELINUX=enforcing$/#SELINUX=enforcing\nSELINUX=disabled/g' /etc/selinux/config
```
reboot the machine!

now all the nodes
```bash
$BEO_SCRIPTS/node_executor.sh "cn1,cn2,sn" \
"cp /etc/selinux/config /etc/selinux/config.ORG;sed -i 's/^SELINUX=enforcing$/#SELINUX=enforcing\nSELINUX=disabled/g' /etc/selinux/config"
```
recheck if all nodes now have the active line
```bash
SELINUX=diabled
```

```bash
$BEO_SCRIPTS/node_executor.sh "cn1,cn2,sn" "cat /etc/selinux/config" | grep "^SELINUX="
```
if the above is true restart the servers now in order to selinux changes take effect

```bash
$BEO_SCRIPTS/node_executor.sh "cn1,cn2,sn" "shutdown -r now"
```


* beowolf needs password-less login 
generate and share roots ssh key for passwordless access to the nodes (still on headnode) for root user 
— this will be the last times you need to provide root password for the nodes, afterwards it works without:

generate a pair of rsa keys (press enter for all questions - dont enter passphrase)
```bash
ssh-keygen -t rsa
```

tighten up permissions on headnode
```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/*
```

now copy the key to all the other nodes (press yes to store the RSA of the servers into the list of known hosts
than type in the password

```bash
$BEO_SCRIPTS/node_executor.sh "cn1,cn2,sn" "mkdir -p /root/.ssh;touch /root/.ssh/authorized_keys;chmod 700 /root/.ssh;chmod 640 /root/.ssh/authorized_keys"
```

now append the rsa key to the authorized keys on all the nodes (also on headnode to make node_executor.sh work!)
to make them know the root user on headnode (important for passwordless import)
```bash
cat .ssh/id_rsa.pub >> /root/.ssh/authorized_keys
cat .ssh/id_rsa.pub | $BEO_SCRIPTS/node_append.sh "cn1,cn2,sn" "/root/.ssh/authorized_keys"
```

now test the passwordless login
```bash
ssh cn1
ssh cn2
ssh sn
```


* let all nodes know from all other nodes ;)
```bash
cat /etc/hosts  | grep -v localhost | $BEO_SCRIPTS/node_append.sh "cn1,cn2,sn" "/etc/hosts"
```

test if above command was successful with
```bash
$BEO_SCRIPTS/node_executor.sh "cn1,cn2,sn" "cat /etc/hosts"
```



* share data directory from storagenode to all the other nodes (nfs export)
I have created a big data partition on the storage node which functions as a shared filesystem on all the nodes
first install nfs tools on all the nodes so we can export partitions on the storage node and import/mount them on the other ones
(we are still on the headnode)
```bash
$BEO_SCRIPTS/node_executor.sh "hdn,cn1,cn2,sn" "yum install -y nfs-utils"
```
on the storage node we need to start the nfs export service on startup
```bash
$BEO_SCRIPTS/node_executor.sh "sn" "chkconfig nfs on;service nfs start"
```

then export the /data directory/partition on storagenode to all the other nodes
```bash
echo "/data  hdn(rw,sync,no_subtree_check,no_root_squash) cn1(rw,sync,no_subtree_check,no_root_squash) cn2(rw,sync,no_subtree_check,no_root_squash)" \
| $BEO_SCRIPTS/node_append.sh "sn" "/etc/exports" 
```

now use static RPC bind service 
(see http://mcdee.com.au/tutorial-configure-iptables-for-nfs-server-on-centos-6/ and
http://ostechnix.wordpress.com/2013/12/15/setup-nfs-server-in-centos-rhel-scientific-linux-6-3-step-by-step/
), by default it uses
dynamic ports on every startup of nfs-export but dynamic ports cannot be entered as rules in iptables
therfore uncomment some static port stuff in the nfs config in order to enable static ports
```bash
$BEO_SCRIPTS/node_executor.sh "sn" "cp /etc/sysconfig/nfs /etc/sysconfig/nfs.ORG"
$BEO_SCRIPTS/node_executor.sh "sn" \
"sed  -ir 's/^#RQUOTAD_PORT=([0-9]+)$/RQUOTAD_PORT=\1/g' /etc/sysconfig/nfs;\
sed  -ir 's/^#LOCKD_TCPPORT=([0-9]+)$/LOCKD_TCPPORT=\1/g' /etc/sysconfig/nfs;\
sed  -ir 's/^#LOCKD_UDPPORT=([0-9]+)$/LOCKD_UDPPORT=\1/g' /etc/sysconfig/nfs;\
sed  -ir 's/^#MOUNTD_PORT=([0-9]+)$/MOUNTD_PORT=\1/g' /etc/sysconfig/nfs;"
sed  -ir 's/^#STATD_PORT=([0-9]+)$/STATD_PORT=\1/g' /etc/sysconfig/nfs;"
sed  -ir 's/^#STATD_OUTGOING_PORT=([0-9]+)$/STATD_OUTGOING_PORT=\1/g' /etc/sysconfig/nfs;"
```
now add those static ports to iptables
```bash
$BEO_SCRIPTS/node_executor.sh "sn" "cp /etc/sysconfig/iptables /etc/sysconfig/iptables.ORG"
$ $BEO_SCRIPTS/node_executor.sh "sn" \
"sed  -ir 's/^\*filter$/\*filter\n-A INPUT -m state --state NEW -m udp -p udp --dport 2049 -j ACCEPT\
-A INPUT -m state --state NEW -m tcp -p tcp --dport 2049 -j ACCEPT\
-A INPUT -m state --state NEW -m udp -p udp --dport 111 -j ACCEPT\
-A INPUT -m state --state NEW -m tcp -p tcp --dport 111 -j ACCEPT\
-A INPUT -m state --state NEW -m udp -p udp --dport 32769 -j ACCEPT\
-A INPUT -m state --state NEW -m tcp -p tcp --dport 32803 -j ACCEPT\
-A INPUT -m state --state NEW -m udp -p udp --dport 892 -j ACCEPT\
-A INPUT -m state --state NEW -m tcp -p tcp --dport 892 -j ACCEPT\
-A INPUT -m state --state NEW -m udp -p udp --dport 875 -j ACCEPT\
-A INPUT -m state --state NEW -m tcp -p tcp --dport 875 -j ACCEPT\
-A INPUT -m state --state NEW -m udp -p udp --dport 662 -j ACCEPT\
-A INPUT -m state --state NEW -m tcp -p tcp --dport 662 -j ACCEPT\n/g' /etc/sysconfig/iptables"
```

restart iptables
```bash
$BEO_SCRIPTS/node_executor.sh "sn" "service nfs restart"
```

now update exports
```bash
$BEO_SCRIPTS/node_executor.sh "sn" "exportfs -a"
```


we need to nfs mount the exported nfs share from storagenode on all other nodes
```bash
$BEO_SCRIPTS/node_executor.sh "hdn,cn1,cn2" "mkdir /data"
echo "sn:/data     /data   nfs     rw,hard,intr    0 0" | $BEO_SCRIPTS/node_append.sh "hdn,cn1,cn2" "/etc/fstab" 
```
in order to use nfs, the rpcbind service must be enabled
```bash
$BEO_SCRIPTS/node_executor.sh "hdn,cn1,cn2" "chkconfig rpcbind on;service rpcbind start"
```

now remount fstab on all the nodes which want to have the /data partition
```bash
#$BEO_SCRIPTS/node_executor.sh "hdn,cn1,cn2" "chkconfig rpcbind on"
$BEO_SCRIPTS/node_executor.sh "hdn,cn1,cn2" "mount -a"
```

check if we can see /data on all nodes, therefore we create a file on headnode in /data and see if we can see it on the other nodes as well
```bash
$BEO_SCRIPTS/node_executor.sh "hdn" "touch /data/test.txt"

$BEO_SCRIPTS/node_executor.sh "cn1,cn2" "ls -al /data/test.txt"
```

now to see if the exporting and re mounting of the nfs work after restart, do restart all the servers now
and check if /data is accessible after rebooting on all servers

restart without filesystem check (is quite faster)
```bash
$BEO_SCRIPTS/node_executor.sh "cn1,cn2,sn,hdn" "shutdown -rf now"
```
than after rebooting look if we can still see that file
```bash
$BEO_SCRIPTS/node_executor.sh "cn1,cn2" "ls -al /data/test.txt"
```

now lets install torque and maui (we are still on the headnode) on headnode
sources: http://www.discngine.com/blog/2014/6/27/install-torque-on-a-single-node-centos-64
http://wiki.hpc.ufl.edu/doc/TorqueHowto
http://people.sissa.it/~calucci/smr1967/batch_admin/torque+maui-admin_notes.pdf
https://wiki.archlinux.org/index.php/TORQUE
http://serverfault.com/questions/425346/cant-open-display-x11-forwarding-cent-os

(the x11 files are needed for the x11 gui called xpbs)
```bash
yum install make rpm-build gawk libxml2-devel openssh-clients openssl-devel gcc gcc-c++ glibc-devel groff\
  boost-devel tcl tcl-devel tk tk-devel flex bison xorg-x11-xauth xorg-x11-fonts-* xorg-x11-utils
cd /tmp
wget http://www.adaptivecomputing.com/download/torque/torque-5.0.1-1_4fa836f5.tar.gz
cd torque-xxx
./configure --prefix=/opt/torque-5.0.1
make 
make rpm
```

install all of the above on the headnode
```bash
cd /root/rpmbuild/RPMS/x86_64
rpm -Uvh torque-5.0.1-1.adaptive.el6.x86_64.rpm \
torque-client-5.0.1-1.adaptive.el6.x86_64.rpm \
torque-devel-5.0.1-1.adaptive.el6.x86_64.rpm \
torque-scheduler-5.0.1-1.adaptive.el6.x86_64.rpm \
torque-server-5.0.1-1.adaptive.el6.x86_64.rpm  
```
install xpbs (graphical gui for torque) on the headnode
```bash
make install_gui
```

install torque client on the computenodes
```bash
mkdir /data/torque-5.0.1
cp /root/rpmbuild/RPMS/x86_64/*.rpm /data/torque-5.0.1
$BEO_SCRIPTS/node_executor.sh "cn1,cn2" "rpm -Uvh /data/torque-5.0.1/torque-5.0.1-1.adaptive.el6.x86_64.rpm \
/data/torque-5.0.1/torque-client-5.0.1-1.adaptive.el6.x86_64.rpm"
https://wiki.heprc.uvic.ca/twiki/bin/view/Main/TestClusterTorqueInstallation
```

disable headnode running jobs! - headnode is only for resource managing and scheduling not actually running
```bash
chkconfig pbs_mom off
service pbs_mom stop
```

now configure torque

```bash
pbs_server -t create
```

then create the following standard queue with minimal configuration

```bash
qmgr -c "set server scheduling=true"
qmgr -c "create queue batch queue_type=execution"
qmgr -c "set queue batch started=true"
qmgr -c "set queue batch enabled=true"
qmgr -c "set queue batch resources_default.nodes=1"
qmgr -c "set queue batch resources_default.walltime=3600"
qmgr -c "set server default_queue=batch"
```

restart torque server
```bash
/etc/init.d/pbs_server restart
```
now configure the computenodes

create mom config file - mom is the actual process starter on the computenodes
and start the mom service
```bash
$BEO_SCRIPTS/node_executor.sh "cn1,cn2"  "touch /var/spool/torque/mom_priv/config"
$BEO_SCRIPTS/node_executor.sh "cn1,cn2"  "/etc/init.d/pbs_mom start"
```

now the pbs server needs to know the names of the computenodes (where to run the queue)
we need to provide real hostnames
```bash
we need some classes in our nodelist.txt we want to query
than we can apply 
hostname or nslookup and put stuff into >>/var/spool/torque/server_priv/nodes
###################################################
#
# Die Einstellungen fuer die Knoten Anzahl CPUs
# wir haben zwar 16 CPUs pro Computenode, das System lief
# aber erst rund bei 8 
# Datei: /var/spool/torque/server_priv/nodes

cn1 np=8
cn2 np=8

```

headnode cannot talk to the computenodes yet
```bash
pbsnodes -a
```
first you have to enable torque ports on all nodes in the firewall

```bash
$ $BEO_SCRIPTS/node_executor.sh "hdn,cn1,cn2" \
"sed  -ir 's/^-A INPUT -j REJECT --reject-with icmp-host-prohibited$/-A INPUT -i eth0 -p udp --dport 1023 -j ACCEPT\n
-A INPUT -m state --state NEW -m tcp -p tcp -m multiport --dports 15001:15004 -j ACCEPT\n
-A INPUT -m state --state NEW -m udp -p udp -m multiport --dports 15001:15004 -j ACCEPT\n
-A INPUT -j REJECT --reject-with icmp-host-prohibited
/g' /etc/sysconfig/iptables"
```
restart iptables on all nodes
```bash
$BEO_SCRIPTS/node_executor.sh "hdn,cn1,cn2" "service iptables restart"
```

now since we have announced all the computenodes to the headnode we also have to make the pbs server (headnode) known to the computenodes in order that they can talk back
```bash
get the full qualified name of the headnode write a script than
"sed  -ir 's/^$pbsserver localhost$/pbsserver <name of headnode>/g' /var/spool/torque/mom_priv/config"
```

create a user for running jobs (root cannot run jobs)
```bash
$BEO_SCRIPTS/node_executor.sh "hdn,cn1,cn2" "useradd <nameofuser>"
```
set a password
```bash
$BEO_SCRIPTS/node_executor.sh "hdn,cn1,cn2" "echo '<yourpassword>' | passwd <nameofuser> --stdin"
```<>

now we have to share the ssh key for this user as well in order that pbs will work
this is similar to creating passwordless login for user root
first logout root and login as the new user
```bash
#generate a key but dont enter a passphrase (hit enter for all other questions)
ssh-keygen -t rsa
chmod 700 ~/.ssh
chmod 600 ~/.ssh/*
source /opt/beowolf-scripts/beo_env.sh
#enter the password for the new user on the nodes
$BEO_SCRIPTS/node_executor.sh "cn1,cn2" "mkdir -p ~/.ssh;touch ~/.ssh/authorized_keys;chmod 700 ~/.ssh;chmod 640 ~/.ssh/authorized_keys"
```

now append the rsa key to the authorized keys on all the nodes (also on headnode to make node_executor.sh work!)
to make them know the root user on headnode (important for passwordless import)
```bash
cat .ssh/id_rsa.pub >> ~/.ssh/authorized_keys
#enter the password for the new user for THE VERY LAST TIME
cat .ssh/id_rsa.pub | $BEO_SCRIPTS/node_append.sh "cn1,cn2" "~/.ssh/authorized_keys"
```

now test the passwordless login
```bash
ssh cn1
ssh cn2
```

test pbs gui
```
xpbs
```