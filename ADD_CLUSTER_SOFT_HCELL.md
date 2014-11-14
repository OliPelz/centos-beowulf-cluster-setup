* HCell install instructions

* first install / compile opencv for centos (based on http://superuser.com/questions/678568/install-opencv-in-centos)

```bash
source /opt/beowolf-scripts/beo_env.sh
$BEO_SCRIPTS/node_executor.sh "hdn,cn1,cn2" "yum -y groupinstall 'Development Tools';\
yum -y install gcc cmake git gtk2-devel pkgconfig numpy ffmpeg"
```

