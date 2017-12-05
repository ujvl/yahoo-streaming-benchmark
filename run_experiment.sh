#!/bin/bash

# Args
# 0 - num partitions
# 1 - num reducers
# 2 - throughput
# 3 - window size
# 4 - drizzle group size
# 5 - micro batch time slice (ms)
# 6 - num microbatches
# 7 - use group by (false for optimised version)
# 8 - checkpoint path

# Before running this script perform the following steps:
# 1) Get drizzle: git clone https://github.com/amplab/drizzle-spark.git drizzle
# 2) Copy Drizzle YSB job file to drizzle/examples/src/main/scala/org/apache/spark/examples/
# 3) Build Drizzle: ./dev/make-distribution.sh --name drizzle --tgz
# 4) Untar Drizzle on each machine
# 5) Copy conf/spark-env.sh to ${DRIZZLE-HOME}/conf
# 6) Configure ${DRIZZLE-HOME}/conf/slaves
# 7) Copy the jars from ${DRIZZLE-HOME}/examples/jars to ${DRIZZLE-HOME}/jars directory

for i in `seq 1 10`; do
  ./sbin/stop-all.sh
  ./sbin/start-all.sh
  cd ../
  ./stream-bench.sh STOP_REDIS
  ./stream-bench.sh START_REDIS
  cd spark-2.1.1-drizzle-bin-drizzle/
  ./bin/spark-submit --class org.apache.spark.examples.DrizzleYsbTest_final --master spark://10.0.0.34:7077 /home/srguser/streaming-benchmarks-yahoo/spark-2.1.1-drizzle-bin-drizzle/examples/jars/spark-examples_2.11-2.1.1-drizzle.jar 288 5 10000000 10000 10 200 2000 false hdfs:///tmp/spark-checkpoint/ 1> latencies-10000k-25machines-288partitions-5reduces-200msbatch-reduce-10group-notify-drizzle-$i.out 2> latencies-10000k-25machines-288partitions-5reduces-200msbatch-reduce-10group-notify-drizzle-$i.log
  rm /tmp/parsed-results.txt
  cd ../
  ./parse_drizzle_output.sh latencies-10000k-25machines-288partitions-5reduces-200msbatch-reduce-10group-notify-drizzle-$i.out
  ./stream-bench.sh STOP_LOAD
  mv data/latencies.txt latencies-10000k-25machines-288partitions-5reduces-200msbatch-reduce-10group-notify-drizzle-$i.txt
  cd spark-2.1.1-drizzle-bin-drizzle/
done
