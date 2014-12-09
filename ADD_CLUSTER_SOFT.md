Here we install add-on software

I always keep the same folder structure

```bash
/opt/software        here i install all 3d party software to
/opt/software-packages/src    here i download the source code
/opt/software-packages/build  here i put compiled code in (can be wiped or recompiled later)
```

TODO: adjust scripts to dont download everything on all nodes but only download on headnode and move to all other nodes to save bandwith
TODO2: the echo PATH
software to install on all clusters (log into headnode)

* java on headnode

http://tecadmin.net/steps-to-install-java-on-centos-5-6-or-rhel-5-6/
create dirs (if not done before in BASIC_CLUSTER.md)
```bash
mkdir -p /opt/software
mkdir -p /opt/software-packages/src
mkdir -p /opt/software-packages/build
cd $_ 
wget --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" \
"http://download.oracle.com/otn-pub/java/jdk/7u71-b14/jdk-7u71-linux-x64.tar.gz"
```
unpack and install
```bash
tar xvf jdk-7u71-linux-x64.tar.gz -C /opt/software/
alternatives --install /usr/bin/java java /opt/software/jdk1.7.0_71/bin/java 2
alternatives --install /usr/bin/jar jar /opt/software/jdk1.7.0_71/bin/jar 2
alternatives --install /usr/bin/javac javac /opt/software/jdk1.7.0_71/bin/javac 2
alternatives --set jar /opt/software/jdk1.7.0_71/bin/jar
alternatives --set javac /opt/software/jdk1.7.0_71/bin/javac 
```

set java env globally
```bash
echo "export JAVA_HOME=/opt/software/jdk1.7.0_71
export JRE_HOME=/opt/software/jdk1.7.0_71/jre
export PATH=\$PATH:\$JAVA_HOME/bin
" >>/etc/profile.d/java.sh

chmod +x /etc/profile.d/java.sh

source /etc/profile.d/java.sh
```
test java
```bash
java -version
```

* java on computenodes (we are still on headnode)
```bash
source /opt/beowolf-scripts/beo_env.sh
```

```bash
$BEO_SCRIPTS/node_executor.sh "cn1,cn2" "mkdir -p /opt/software /opt/software-packages/src /opt/software-packages/build" 
```
install wget on nodes
```bash
$BEO_SCRIPTS/node_executor.sh "cn1,cn2" "yum -y install wget" 
```

copy java to the nodes
```bash
$BEO_SCRIPTS/node_copier.sh "cn1,cn2" "/opt/software/jdk1.7.0_71"
```
set up java
```bash
$BEO_SCRIPTS/node_executor.sh "cn1,cn2" "alternatives --install /usr/bin/java java /opt/software/jdk1.7.0_71/bin/java 2;\
alternatives --install /usr/bin/jar jar /opt/software/jdk1.7.0_71/bin/jar 2;\
alternatives --install /usr/bin/javac javac /opt/software/jdk1.7.0_71/bin/javac 2;\
alternatives --set jar /opt/software/jdk1.7.0_71/bin/jar;\
alternatives --set javac /opt/software/jdk1.7.0_71/bin/javac;
echo 'export JAVA_HOME=/opt/software/jdk1.7.0_71\
export JRE_HOME=/opt/software/jdk1.7.0_71/jre\
export PATH=\$PATH:\$JAVA_HOME/bin
' >>/etc/profile.d/java.sh;
chmod +x /etc/profile.d/java.sh;
source /etc/profile.d/java.sh"
```


install build-essentials on the nodes
```bash
$BEO_SCRIPTS/node_executor.sh "hdn,cn1,cn2" "yum -y install gcc gcc-c++ kernel-devel make"
$BEO_SCRIPTS/node_executor.sh "hdn,cn1,cn2" "yum -y groupinstall 'Development tools'"
```

install R on all the nodes (please note: for a even better production cluster it would be even better to compile R from scratch and put in /opt/software)
we will install R through the EPEL repository
http://www.leonardoborda.com/blog/install-epel-repository-on-centos-5-5/

first install the epel repos and deactivate it (we will only install packages from epel by explicitely stating it)
```bash
$BEO_SCRIPTS/node_executor.sh "hdn,cn1,cn2" "yum -y install epel-release"
$BEO_SCRIPTS/node_executor.sh "hdn,cn1,cn2" "sed -i 's/^enabled=1$/enabled=0/' /etc/yum.repos.d/epel.repo"
```

install R by temporarily enabling the epel repos
```bash
$BEO_SCRIPTS/node_executor.sh "hdn,cn1,cn2" "yum -y --enablerepo='epel' install R"
```

install additional libraries for important R / bioconductor packages
```bash
$BEO_SCRIPTS/node_executor.sh "hdn,cn1,cn2" "yum -y install giflib-devel libjpeg-devel libtiff-devel libpng-devel freetype-devel ImageMagick ImageMagick-devel"
```

now install e.g. EBIImage

how to install R packages with auto yes


* bowtie 1
```bash
$BEO_SCRIPTS/node_executor.sh "hdn,cn1,cn2" "wget http://downloads.sourceforge.net/project/bowtie-bio/bowtie/1.1.1/bowtie-1.1.1-linux-x86_64.zip -P  /opt/software/src;\
unzip /opt/software/src/bowtie-1.1.1-linux-x86_64.zip -d /opt/software;\
echo 'export PATH=\$PATH:/opt/software/bowtie-1.1.1/' >>/etc/profile.d/bowtie.sh;\
chmod +x /etc/profile.d/bowtie.sh;
source /etc/profile.d/bowtie.sh"
```
test bowtie installation

```bash
$BEO_SCRIPTS/node_executor.sh "hdn,cn1,cn2" "/opt/software/bowtie-1.1.1/bowtie -h" | grep options
```

bowtie 2

```bash
$BEO_SCRIPTS/node_executor.sh "hdn,cn1,cn2" "wget http://downloads.sourceforge.net/project/bowtie-bio/bowtie2/2.2.4/bowtie2-2.2.4-linux-x86_64.zip -P /opt/software/src;\
unzip /opt/software/src/bowtie2-2.2.4-linux-x86_64.zip -d /opt/software;\
echo 'export PATH=\$PATH:/opt/software/bowtie2-2.2.4/' >>/etc/profile.d/bowtie2.sh;\
chmod +x /etc/profile.d/bowtie2.sh;
source /etc/profile.d/bowtie2.sh"
```

test bowtie 2
```bash
$BEO_SCRIPTS/node_executor.sh "hdn,cn1,cn2" "/opt/software/bowtie2-2.2.4/bowtie2 -h" | grep options
```


blast suite
```bash
wget ftp://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/LATEST/ncbi-blast-2.2.30+-x64-linux.tar.gz -P /opt/software/src
#my copier is not working properly with '+' etc.
mv /opt/software/src/ncbi-blast-2.2.30+-x64-linux.tar.gz /opt/software/src/ncbi-blast-2.2.30.tar.gz
$BEO_SCRIPTS/node_copier.sh "cn1,cn2" "/opt/software/src/ncbi-blast-2.2.30.tar.gz"


$BEO_SCRIPTS/node_executor.sh "cn1,cn2" "tar -xvf /opt/software/src/ncbi-blast-2.2.30.tar.gz -C /opt/software;\
echo 'export PATH=\$PATH:/opt/software/ncbi-blast-2.2.30+/bin/' >>/etc/profile.d/ncbi-blast.sh;\
chmod +x /etc/profile.d/ncbi-blast.sh;
source /etc/profile.d/ncbi-blast.sh"
```

test blast
```bash
$BEO_SCRIPTS/node_executor.sh "hdn,cn1,cn2" "/opt/software/ncbi-blast-2.2.30+/bin/blastn -h" | grep options
```

samtools

needs libcurses
```bash
$BEO_SCRIPTS/node_executor.sh "hdn,cn1,cn2" "yum -y install ncurses-devel ncurses"
```

```bash
$BEO_SCRIPTS/node_executor.sh "hdn,cn1,cn2" "wget http://downloads.sourceforge.net/project/samtools/samtools/1.1/samtools-1.1.tar.bz2 -P /opt/software/src;\
tar xvf  /opt/software/src/samtools-1.1.tar.bz2 -C /opt/software/build;\
cd /opt/software/build/samtools-1.1;
make prefix=/opt/software/samtools-1.1 install
echo 'export PATH=\$PATH:/opt/software/samtools-1.1/bin' >>/etc/profile.d/samtools.sh;\
chmod +x /etc/profile.d/samtools.sh;
source /etc/profile.d/samtools.sh"
```

test samtools
```bash
$BEO_SCRIPTS/node_executor.sh "hdn,cn1,cn2" "/opt/software/samtools-1.1/bin/samtools" | grep Usage
```

bamtools

needs cmake

```bash
$BEO_SCRIPTS/node_executor.sh "hdn,cn1,cn2" "yum -y install cmake"

```

```bash
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
```

test bamtools
```bash
$BEO_SCRIPTS/node_executor.sh "hdn,cn1,cn2" "/opt/software/bamtools/bin/bamtools" | grep Usage
```


install top hat
```bash
$BEO_SCRIPTS/node_executor.sh "hdn,cn1,cn2" "wget http://ccb.jhu.edu/software/tophat/downloads/tophat-2.0.13.Linux_x86_64.tar.gz -P /opt/software/src;\
tar xvf /opt/software/src/tophat-2.0.13.Linux_x86_64.tar.gz -C /opt/software;\
echo 'export PATH=\$PATH:/opt/software/tophat-2.0.13.Linux_x86_64/' >>/etc/profile.d/tophat.sh;\
chmod +x /etc/profile.d/tophat.sh;
source /etc/profile.d/tophat.sh"
```

install cufflinks (TODO: rewrite script the file is a huge download to download only once)

```bash
$BEO_SCRIPTS/node_executor.sh "hdn,cn1,cn2" "wget http://cufflinks.cbcb.umd.edu/downloads/cufflinks-2.2.1.Linux_x86_64.tar.gz -P /opt/software/src;\
tar xvf /opt/software/src/cufflinks-2.2.1.Linux_x86_64.tar.gz -C /opt/software;\
echo 'export PATH=\$PATH:/opt/software/cufflinks-2.2.1.Linux_x86_64/' >>/etc/profile.d/cufflinks.sh;\
chmod +x /etc/profile.d/cufflinks.sh;
source /etc/profile.d/cufflinks.sh"
```
test cufflinks
```bash
$BEO_SCRIPTS/node_executor.sh "hdn,cn1,cn2" "/opt/software/cufflinks-2.2.1.Linux_x86_64/cufflinks" 
```


fastqc (needs X11 ssh login)
```bash
$BEO_SCRIPTS/node_executor.sh "hdn,cn1,cn2" "wget http://www.bioinformatics.babraham.ac.uk/projects/fastqc/fastqc_v0.11.2.zip -P /opt/software/src;\
unzip /opt/software/src/fastqc_v0.11.2.zip -d /opt/software;\
chmod +x /opt/software/FastQC/fastqc;\
echo 'export PATH=\$PATH:/opt/software/FastQC/' >>/etc/profile.d/fastqc.sh;\
chmod +x /etc/profile.d/fastqc.sh;
source /etc/profile.d/fastqc.sh"
```
test fastqc
```bash
$BEO_SCRIPTS/node_executor.sh "hdn,cn1,cn2" "/opt/software/FastQC/fastqc" 
```

htslib
```bash
$BEO_SCRIPTS/node_executor.sh "hdn,cn1,cn2" "wget http://downloads.sourceforge.net/project/samtools/samtools/1.1/htslib-1.1.tar.bz2 -P /opt/software/src;\
tar xvf /opt/software/src/htslib-1.1.tar.bz2 -C /opt/software/build;\
cd /opt/software/build/htslib-1.1;\
make prefix=/opt/software/htslib install;\
echo 'export PATH=\$PATH:/opt/software/htslib/bin' >>/etc/profile.d/htslib.sh;\
chmod +x /etc/profile.d/htslib.sh;
source /etc/profile.d/htslib.sh"
```

test
```bash
$BEO_SCRIPTS/node_executor.sh "hdn,cn1,cn2" "/opt/software/htslib/bin/tabix"
```

after everything has been installed fix possible permissions problems
```bash
$BEO_SCRIPTS/node_executor.sh "hdn,cn1,cn2" "chmod 775 /opt/software -R"
```

test if path is set correctly

logout and login again (best login as non-root user)
```bash

```