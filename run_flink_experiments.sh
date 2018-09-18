#!/bin/bash

BENCH_DIR="~/yahoo-streaming-benchmark"

# Use benchmarkConf_custom as the benchmarkConf for this experiment
cp $BENCH_DIR/conf/benchmarkConf_custom.yaml $BENCH_DIR/conf/benchmarkConf.yaml

# Make sure flink's conf dir is up-to-date on both the master and slaves. 
cp $BENCH_DIR/conf/slaves $BENCH_DIR/flink-1.0.1/conf/
cp $BENCH_DIR/conf/flink-conf.yaml $BENCH_DIR/flink-1.0.1/conf/
./hosts.sh cp $BENCH_DIR/conf/flink-conf.yaml $BENCH_DIR/flink-1.0.1/conf/

.$BENCH_DIR/stream-bench.sh STOP_ALL

# Clear logs from previous runs
rm -rf $BENCH_DIR/flink-1.0.1/log/*
./hosts.sh rm -rf $BENCH_DIR/flink-1.0.1/log/*

#------------- Run the flink benchmark (includes failure currently) ---------------
$BENCH_DIR/stream-bench.sh FLINK_TEST
mv $BENCH_DIR/data/latencies.txt $BENCH_DIR/results/latencies-flink.txt
sleep 10

