#!/bin/bash

[ -d  build ] && rm -r build
mkdir build
cd build
qmake ../
make

