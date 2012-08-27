#!/bin/sh
set -e
source $stdenv/setup
cd $src
mkdir -p $out/m2_repository

# expirementation leads me to believe the cli is a good first one to build.
mvn -Dmaven.artifact.threads=10 -am -pl 'cli' dependency:resolve --settings=${jenkins_m2_settings}
