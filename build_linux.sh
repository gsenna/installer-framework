#!/bin/bash

[ -d  build ] && rm -r build
mkdir build
cd build
qtchooser -run-tool=qmake -qt=qt5 ../
make

