#!/bin/sh
set -e
source $stdenv/setup

mkdir -p $out

cp -vr $m2_repo/m2_repository $out/m2_repository
chmod -R ug+rw $out/m2_repository

cp -vr $src/* $out/

cd $out

mvn install --settings=${jenkins_m2_settings}

