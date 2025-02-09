#!/bin/sh

curl -L https://github.com/zajo/TASM/archive/refs/heads/master.zip -o tasm.zip \
  && unzip tasm.zip \
  && mv TASM-master TASM \
  && rm tasm.zip
