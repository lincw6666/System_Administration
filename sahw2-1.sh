#!/bin/sh
echo "`ls -lAR | grep ^- | awk '{print $5" "$9}' | sort -n -r | head -n 5 | awk '{print NR":"$1" "$2}'``ls -lAR | grep ^d | wc -l | awk '{print "\nDir num: "$1}'``ls -lAR | grep ^- | wc -l | awk '{print "\nFile num: "$1}'``find . -type f | xargs wc -c | tail -n 1 | awk '{print "\nTotal: "$1}'`"
