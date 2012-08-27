#!/bin/sh
set -e

source $stdenv/setup

mkdir -p $out

MOUNT_POINT=$PWD/dmg_mount
mkdir -p ${MOUNT_POINT}

/usr/bin/hdiutil attach $src -mountpoint dmg_mount

function unmount_dmg()
{
  /sbin/umount ${MOUNT_POINT}
}

trap unmount_dmg EXIT;

cp -avR dmg_mount/* $out/

