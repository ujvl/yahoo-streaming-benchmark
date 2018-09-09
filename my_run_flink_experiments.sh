#!/bin/bash
cp conf/benchmarkConf_custom.yaml conf/benchmarkConf.yaml

./stream-bench.sh STOP_ALL
rm -rf ./flink-1.0.1/log/*
./hosts.sh rm -rf ~/yahoo-streaming-benchmark/flink-1.0.1/log/*

#----------------------------
#for i in `seq 1 10` ; do
  ./stream-bench.sh FLINK_TEST
  #mv data/latencies.txt results/latencies-custom-flink-$i.txt
  mv data/latencies.txt results/latencies-custom-flink.txt
  sleep 10
#done

#----------------------------
#for i in `seq 1 10` ; do
#  ./stream-bench.sh FLINK_TEST_FAILURE
#  mv data/latencies.txt results/latencies-custom-failure-flink-$i.txt
#  sleep 10
#done

