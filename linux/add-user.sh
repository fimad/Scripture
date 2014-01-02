#!/bin/bash
#Adds a user on Bilbo.

if [ "$#" -ne 1 ]; then
    echo "usage: $0 user-name"
    exit 1
fi

name=$1

sudo bash << EOF
(   zfs create shire/home/$name \
&&  zfs set mountpoint=/home/$name shire/home/$name \
&&  zfs mount -a )
EOF

sudo adduser $name

sudo bash << EOF
(   adduser $name commons \
&&  rsync -r /etc/skel/ /home/$name/ \
&&  chown -R $name:$name /home/$name )
EOF

