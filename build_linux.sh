#!/bin/bash

[ -d  build ] && rm -r build
mkdir build
cd build
qtchooser -qt=5 -run-tool=qmake ../
make

