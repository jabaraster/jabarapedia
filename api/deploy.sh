#!/bin/sh
./build.sh \
  && \cp -f ./serverless.yml .webpack \
  && cd .webpack \
  && sls deploy \
  && cd ..
