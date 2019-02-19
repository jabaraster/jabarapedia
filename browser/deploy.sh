#!/bin/sh
export AWS_PROFILE=jabara-admin
cd ./static
aws s3 sync ./ s3://jabarapedia-static/
cd ../
