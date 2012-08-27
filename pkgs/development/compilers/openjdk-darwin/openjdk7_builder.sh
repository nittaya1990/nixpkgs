#!/bin/sh
set -e

source $stdenv/setup

# We retain the entire jdk package. We also build the out directory to be a reasonable JAVA_HOME via
# symlinks.
mkdir -p $out
cp -avR $src/1.7.0u.jdk $out/
cd $out/1.7.0u.jdk/Contents/Home

# TODO(corey): will not work for paths with spaces
for ITEM in `ls -1` ; do
  ln -s "${PWD}/${ITEM}" "${out}/${ITEM}";
done

