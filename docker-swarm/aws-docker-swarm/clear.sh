#!/usr/bin/env bash
#
# you might need to modify your local known_hosts file if your IPs are changing
#

# if [ "$1" ]; then
#   sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder1
# fi

ENV=${1:-chaos}

cat ~/.ssh/known_hosts | grep -v ${ENV} > out && mv out ~/.ssh/known_hosts
