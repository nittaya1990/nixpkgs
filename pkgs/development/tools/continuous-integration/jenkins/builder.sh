#!/bin/sh
set -e
source $stdenv/setup
cd $src
mkdir -p $out/m2_repository
mvn -Pnix-build install --settings=${jenkins_m2_settings}
