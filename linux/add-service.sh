#!/bin/bash
#Creates a service on Bilbo and adds the current user to the services group.

if [ "$#" -ne 1 ]; then
    echo "usage: $0 service-name"
    exit 1
fi

user=`whoami`
name=$1

sudo bash << EOF
(   zfs create shire/service/$name \
&&  adduser --system --home /shire/service/$name $name \
&&  addgroup --system $name \
&&  adduser $name $name \
&&  adduser $user $name \
&&  chown $name:$name /shire/service/$name \
&&  chmod -R g+w /shire/service/$name )
EOF
