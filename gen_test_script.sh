#!/usr/bin/bash
find | grep .pkg | sed -e 's|^\./\(.\)/\([^\.]\+\).pkg|net describe \2, from (https://raw.github.com/bquistorff/Stata-modules/master/\1/)|g' > test.do
