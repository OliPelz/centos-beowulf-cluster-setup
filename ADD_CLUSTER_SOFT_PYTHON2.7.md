install python 2.7 from scratch on all nodes
```bash
mkdir /opt/software-packages/src/Python-2.7.9
cd $_
wget https://www.python.org/ftp/python/2.7.9/Python-2.7.9.tgz
tar xvf Python-2.7.9.tgz
cd Python-2.7.9
./configure --prefix=/opt/software/Python-2.7.9
make
make install
```

now setup python2.7 in path
```bash
sudo vi /etc/profile.d/python2.7.sh

#put in (make sure $PATH is before new 2.7.9 path to make sure python 2.6 comes first ;) 
export PATH=$PATH:/opt/software/Python-2.7.9/bin/

```
make exec and resource
```bash
chmod +x /etc/profile.d/python2.7.sh 
source /etc/profile.d/python2.7.sh 
```

