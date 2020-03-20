#!/bin/bash

DIR=$(dirname "$0")
cd $DIR;

scp -r public/* blog-server:~/blog;
