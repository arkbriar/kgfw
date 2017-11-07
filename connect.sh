#!/bin/bash

OC_PASSWD="jiba5ban"
OC_USER="test"
OC_SERVERCERT="sha256:e08921bb4f56e4a7e80220e666b9fa6a9294d4bb93146b77e58c8f5ae93a6733"
OC_SERVER="cn2.crazyark.me:11025"

echo ${OC_PASSWD} | openconnect --pid-file=/var/run/openconnect.pid -i tun0 -b -u ${OC_USER} --passwd-on-stdin --servercert ${OC_SERVERCERT} ${OC_SERVER}
