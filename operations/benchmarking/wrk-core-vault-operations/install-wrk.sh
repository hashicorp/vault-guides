apt update
apt install -yy wget git-core vim build-essential libssl-dev zlib1g-dev
wget https://github.com/giltene/wrk2/archive/master.zip
unzip master.zip
cd wrk-master
make
cp wrk /usr/bin

