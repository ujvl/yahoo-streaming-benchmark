#!/bin/bash

sleep 250
ssh caelum-402 'cd /home/srguser/data-artisans-ycsb/; ./kill_spark_executor.sh'
#./sbin/start-slaves.sh
