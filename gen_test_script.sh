#!/usr/bin/bash
# Creates do file to test that all the packages can be -net describe-'ed.
find | grep .pkg | sed -e 's|^\./\(.\)/\([^\.]\+\).pkg|net describe \2, from (https://raw.github.com/bquistorff/Stata-modules/master/\1/)|g' > test2.do
