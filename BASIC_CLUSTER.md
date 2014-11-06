* Prequesites: execute all steps in SCRIPTS.md

when logging in with a fresh ssh session execute:
```bash
```source /opt/beowolf-scripts/beo_env.sh

if you havent done in SCRIPTS.md, put the beowolf shell script path to PATH variable (only have to do once)
```bash
echo PATH=$BEO_SCRIPTS:$PATH >> /etc/environment
```

* beowolf needs password-less login 
generate and share roots ssh key for passwordless access to the nodes (still on headnode) for root user 
— this will be the last times you need to provide root password for the nodes, afterwards it works without:

generate a pair of rsa keys (press enter for all questions - dont enter passphrase)
```bash
ssh-keygen -t rsa
```
now copy the key to all the other nodes (press yes to store the RSA of the servers into the list of known hosts
than type in the password

```bash
$BEO_SCRIPTS/node_executor.sh "cn1,cn2,sn" "mkdir -p ~/.ssh"
```

now copy the rsa key to the nodes
```bash

```

* exec on all nodes

* put server names from compute nodes and storage node on nodes



* share root directory on every node using nfs
