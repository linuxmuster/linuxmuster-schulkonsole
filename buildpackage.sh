#!/bin/bash

rm -f debian/files
rm -rf debian/linuxmuster-schulkonsole
rm -rf debian/linuxmuster-schulkonsole-wrapper

dpkg-buildpackage \
    -I".git"
