#!/bin/bash
set -x

logger() {
  DT=$(date '+%Y/%m/%d %H:%M:%S')
  echo "$DT $0: $1"
}

download_jdk() {
  local JDK_VERSION="$1"
  local EXT="$2"
  readonly URL="http://www.oracle.com"
  readonly JDK_DOWNLOAD_URL1="${URL}/technetwork/java/javase/downloads/index.html"
  readonly JDK_DOWNLOAD_URL2=$(curl -s ${JDK_DOWNLOAD_URL1} | egrep -o "\/technetwork\/java/\javase\/downloads\/jdk${JDK_VERSION}-downloads-.+?\.html" | head -1 | cut -d '"' -f 1)
  [[ -z "${JDK_DOWNLOAD_URL2}" ]] && logger "Could not get jdk download url - ${JDK_DOWNLOAD_URL1}" && exit 1
  readonly JDK_DOWNLOAD_URL3="${URL}${JDK_DOWNLOAD_URL2}"
  readonly JDK_DOWNLOAD_URL4=$(curl -s ${JDK_DOWNLOAD_URL3} | egrep -o "http\:\/\/download.oracle\.com\/otn-pub\/java\/jdk\/[7-8]u[0-9]+\-(.*)+\/jdk-[7-8]u[0-9]+(.*)linux-x64.${EXT}")
  for DL_URL in "${JDK_DOWNLOAD_URL4[@]}"; do
    wget --no-cookies --no-check-certificate --header "Cookie: oraclelicense=accept-securebackup-cookie" -N ${DL_URL}
  done
}

logger "Running"

logger "Installing Oracle JDK"

# Detect package management system.
YUM=$(which yum 2>/dev/null)
APT_GET=$(which apt-get 2>/dev/null)

if [[ ! -z ${YUM} ]]; then
  logger "RHEL/CentOS system detected"
  download_jdk 8 rpm
  sudo rpm -Uvh jdk-*-linux-x64.rpm
elif [[ ! -z ${APT_GET} ]]; then
  logger "Debian/Ubuntu system detected"
  download_jdk 8 tar.gz
  sudo mkdir -p /opt/jdk
  sudo tar xf jdk-*-linux-x64.tar.gz -C /opt/jdk
  JDK_VERSION="$(ls /opt/jdk/)"
  sudo update-alternatives --install /usr/bin/java java /opt/jdk/${JDK_VERSION}/bin/java 2000
  sudo update-alternatives --install /usr/bin/javac javac /opt/jdk/${JDK_VERSION}/bin/javac 2000
  sudo update-alternatives --install /usr/bin/jar jar /opt/jdk/${JDK_VERSION}/bin/jar 2000
  update-alternatives --display java
  update-alternatives --display javac
  update-alternatives --display jar
else
  logger "Oracle JDK not installed due to OS detection failure"
  exit 1;
fi

logger "Complete"
