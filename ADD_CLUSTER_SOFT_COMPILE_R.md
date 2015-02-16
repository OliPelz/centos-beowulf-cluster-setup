R from scratch on all nodes
```bash
yum -y install gcc gcc-c++ kernel-devel make
yum -y groupinstall 'Development tools'
yum -y install giflib-devel libjpeg-devel libtiff-devel libpng-devel \
freetype-devel readline-devel gawk libxml2-dev glibc-devel libX11-devel libXt-devel \
texlive-latex texinfo cairo-devel libicu-devel texinfo-tex-4.13a-8.el6

```bash
wget http://mirrors.softliste.de/cran/src/base/R-3/R-3.1.2.tar.gz -P /opt/software-packages/src
tar xvf /opt/software-packages/src/R-3.1.2.tar.gz -C /opt/software-packages/build/
cd /opt/software-packages/build/R-*
./configure --prefix /opt/software/R-3.1.2  --enable-R-shlib 
make
make check
make pdf;make info
make install
```

```
echo 'export PATH=$PATH:/opt/software/R-3.1.2/bin/' >>/etc/profile.d/R.sh;
chmod +x /etc/profile.d/R.sh;
source /etc/profile.d/R.sh
```

addimportant R environment variables to existing
/etc/profile.d/R.sh

```bash
export R_HOME=/opt/software/R-3.1.2/lib64/R
export R_HOME_DIR=/opt/software/R-3.1.2/lib64/R
```