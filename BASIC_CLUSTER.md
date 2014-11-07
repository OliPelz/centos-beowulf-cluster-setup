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

now append the rsa key to the authorized keys on the nodes to make them know the root user on headnode (important for passwordless import)
```bash
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



* share root directory on every node using nfs
