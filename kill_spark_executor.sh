#!/bin/bash
export EPID=`ps aux | grep "spark\.executor" | cut -d" " -f 3`
echo $EPID
kill -9 $EPID
