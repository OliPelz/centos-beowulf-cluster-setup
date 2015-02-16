* howto install poretools

first install python 2.7 using my instructions here (ADD_CLUSTER_SOFT_PYTHON2.7.md)

now we need to install depenancies!


first things first, install setuptools
```bash
#install setup tools
wget https://bootstrap.pypa.io/ez_setup.py -O - | python2.7
```

now install Cython and numpy 
```bash
cd /opt/software-packages/src
wget http://cython.org/release/Cython-0.21.2.zip
git clone https://github.com/numpy/numpy.git
unzip Cython-0.21.2.zip
cd Cython-0.21.2
python2.7 setup.py install
cd ../numpy
python2.7 setup.py install
```

than install hdf5 / h5py 

```bash
cd /opt/software-packages/src
wget http://www.hdfgroup.org/ftp/HDF5/current/src/hdf5-1.8.14.tar.gz
tar xvf hdf5-1.8.14.tar.gz
cd hdf5-1.8.14
./configure --prefix=/opt/software/hdf5
make 
make install
```

put hdf5 exec and dyn libs in path
```bash
sudo vi /etc/profile.d/hdf5.sh
#put in 
export PATH=$PATH:/opt/software/hdf5/bin
```
chmod +x /etc/profile.d/hdf5.sh
source /etc/profile.d/hdf5.sh

adapt dynamic library search path
```bash
echo '/opt/software/hdf5/lib/' > /etc/ld.so.conf.d/hdf5.conf;
ldconfig;
```

now install h5py
```bash
cd /opt/software-packages/src
git clone https://github.com/h5py/h5py
cd h5py
python2.7 setup.py configure --hdf5=/opt/software/hdf5/
python2.7 setup.py install
```

now install poretools
```bash
cd /opt/software-packages/src
git clone https://github.com/arq5x/poretools
cd poretools
python2.7 setup.py install
```



#!/usr/bin/python  -> /opt/software/Python-2.7.9/bin/python2.7

if you need to install different modules than that usual routine is
```bash
wget <URL of python source package>
unpack
cd into archive
python2.7 setup.py install
```