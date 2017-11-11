#!/usr/bin/env bash

logger() {
  DT=$(date '+%Y/%m/%d %H:%M:%S')
  echo "$DT $0: $1"
}

logger "Running"

sudo gem install bundler --no-ri --no-rdoc
sudo /usr/local/bin/bundle install --system

logger "Complete"
