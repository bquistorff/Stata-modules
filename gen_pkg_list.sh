#!/usr/bin/bash
# Concates all the *.toc files together to give a summary of all packages
find . -name '*.toc' -exec cat {} \; | grep "^p " | sed -e 's/p //g' | sed -e 's/^\([^ ]\+\) /\1 - /g' > pkg_list.txt
