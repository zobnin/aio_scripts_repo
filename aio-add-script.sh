#!/bin/sh

cp $1 .
./aio-gen-index.sh > aiorepo.index
git add *
git commit "Update `basename $1` script"
git push

