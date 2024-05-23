#!/usr/bin/env zsh

rm tmp.csv && ./bin/prunt_simulator | tee >(grep -v ".*,.*,.*,.*,,,," >> /dev/stdout) | grep ".*,.*,.*,.*,.*,,,,"  > tmp.csv
