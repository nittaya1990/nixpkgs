#!/bin/sh
set -e
source $stdenv/setup

mkdir -p $out

cp -vr $m2_repo/m2_repository $out/m2_repository

cp -vr $src/* $out/
chmod -R u+rw $out/

cd $out

export FONTCONFIG_FILE=${fontsConf}

mvn install -Plight-test --settings=${jenkins_m2_settings}

