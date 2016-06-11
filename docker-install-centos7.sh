#!/bin/bash

# ex. ./docker-install.sh &&
#         -r do-docker.terracetech.co.kr:5000 &&
#         -d /home/lib/docker &&
#         -s 50 &&
#         -l /dev/mapper/lgroup-lvolume &&
#         -u dockeradmin &&
#         -p dockeradmin

# 0.
# 참고: http://stackoverflow.com/questions/16483119/example-of-how-to-use-getopts-in-bash
usage() { echo "Usage: $0 [-r <registry url>] [-d <home directory>] [-s <dm.basesize in gigabyte>] [-l <logical volume path] [-u <username>] [-p <password>]" 1>&2; exit 1; }
while getopts ":r:d:s:l:u:p:" o; do
    case "${o}" in
        r)
            REGISTRY=${OPTARG}
            ;;
        d)
            DIRECTORY=${OPTARG}
            ;;
        s)
            BASESIZE=${OPTARG}
            ;;
        l)
            LVMPATH=${OPTARG}
            ;;
        u)
            USERNAME=${OPTARG}
            ;;
        p)
            PASSWORD=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))
if [ ! -z "${USERNAME}" -a -z "${PASSWORD}" ]; then
  echo "failed: username without password...."
  usage
fi

# 1.
echo "yum update.........."
sudo yum -y update

# 2.
echo "yum repository add............."
sudo tee /etc/yum.repos.d/docker.repo <<-'EOF'
[dockerrepo]
name=Docker Repository
baseurl=https://yum.dockerproject.org/repo/main/centos/$releasever/
enabled=1
gpgcheck=1
gpgkey=https://yum.dockerproject.org/gpg
EOF

# 3.
echo "docker-engine install with yum..........."
sudo yum -y install docker-engine

# 4.
echo "docker daemon configuration............"
exec_opts="ExecStart=/usr/bin/docker daemon -H fd://"
exec_opts="$exec_opts --exec-opt native.cgroupdriver=cgroupfs"
if [ ! -z "${REGISTRY}" ]; then
  exec_opts="$exec_opts --insecure-registry ${REGISTRY}"
fi
if [ ! -z "${DIRECTORY}" ]; then
  exec_opts="$exec_opts -g ${DIRECTORY}"
fi
if [ ! -z "${BASESIZE}" ]; then
  # TODO image and container base size
  exec_opts="$exec_opts --storage-opt dm.basesize=${BASESIZE}G"
fi
if [ ! -z "${LVMPATH}" ]; then
  exec_opts="$exec_opts --storage-driver=devicemapper --storage-opt=dm.thinpooldev=${LVMPATH} --storage-opt dm.use_deferred_removal=true"
fi
echo "${exec_opts}";
sudo sed -i "s#ExecStart.*#$exec_opts#g" /usr/lib/systemd/system/docker.service

# 5.
echo "daemon reload.........."
sudo systemctl daemon-reload

# 6.
echo "docker start.........."
sudo service docker start

# 7.
echo "chkconfig enable............"
sudo systemctl enable docker.service

# 8.
echo "user add to docker group............"
if [ ! -z "${USERNAME}" ]; then
  sudo useradd -g docker "${USERNAME}"
  sudo usermod --password $(echo "${PASSWORD}" | openssl passwd -1 -stdin) "${USERNAME}"
fi
