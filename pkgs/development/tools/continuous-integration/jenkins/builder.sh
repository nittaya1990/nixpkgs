#!/bin/sh
set -e
source $stdenv/setup

mkdir -p $out

cp -r $m2_repo/m2_repository $out/m2_repository

cp -r $src/* $out/
chmod -R u+rw $out/

cd $out

export FONTCONFIG_FILE=${fontsConf}
export FC_DEBUG=5

export MAVEN_OPTS="-Xmx512M -XX:MaxPermSize=512M"

mvn install -DskipTests --settings=${jenkins_m2_settings}

