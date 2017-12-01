#!/bin/bash

for i in `seq 1 10` ; do
  cp conf/benchmarkConf-10000k-50ms-3cores-checkpoint-1000ms.yaml conf/benchmarkConf.yaml
  ./stream-bench.sh FLINK_TEST_FAILURE
  mv data/latencies.txt results/latencies-10000k-50ms-3cores-checkpoint-1000ms-failure-flink-$i.txt
  sleep 10
done

#----------------------------
for i in `seq 1 10` ; do
  cp conf/benchmarkConf-10000k-50ms-3cores-checkpoint-2000ms.yaml conf/benchmarkConf.yaml
  ./stream-bench.sh FLINK_TEST_FAILURE
  mv data/latencies.txt results/latencies-10000k-50ms-3cores-checkpoint-2000ms-failure-flink-$i.txt
  sleep 10
done

#----------------------------
for i in `seq 1 10` ; do
  cp conf/benchmarkConf-10000k-50ms-3cores-checkpoint-2000ms.yaml conf/benchmarkConf.yaml
  ./stream-bench.sh FLINK_TEST
  mv data/latencies.txt results/latencies-10000k-50ms-3cores-checkpoint-2000ms-flink-$i.txt
  sleep 10
done

#----------------------------
for i in `seq 1 10` ; do
  cp conf/benchmarkConf-10000k-50ms-3cores-checkpoint-1000ms.yaml conf/benchmarkConf.yaml
  ./stream-bench.sh FLINK_TEST
  mv data/latencies.txt results/latencies-10000k-50ms-3cores-checkpoint-1000ms-flink-$i.txt
  sleep 10
done

#----------------------------
for i in `seq 1 10` ; do
  cp conf/benchmarkConf-10000k-50ms-3cores-checkpoint-5000ms.yaml conf/benchmarkConf.yaml
  ./stream-bench.sh FLINK_TEST
  mv data/latencies.txt results/latencies-10000k-50ms-3cores-checkpoint-5000ms-flink-$i.txt
  sleep 10
done

#----------------------------
for i in `seq 1 10` ; do
  cp conf/benchmarkConf-10000k-50ms-3cores-checkpoint-5000ms.yaml conf/benchmarkConf.yaml
  ./stream-bench.sh FLINK_TEST_FAILURE
  mv data/latencies.txt results/latencies-10000k-50ms-3cores-checkpoint-5000ms-failure-flink-$i.txt
  sleep 10
done

#----------------------------
for i in `seq 1 10` ; do
  cp conf/benchmarkConf-10000k-50ms-3cores-checkpoint-2000ms.yaml conf/benchmarkConf.yaml
  ./stream-bench.sh FLINK_TEST
  mv data/latencies.txt results/latencies-10000k-50ms-3cores-checkpoint-2000ms-exactly-once-flink-$i.txt
  sleep 10
done

#----------------------------
for i in `seq 1 10` ; do
  cp conf/benchmarkConf-10000k-50ms-3cores-checkpoint-2000ms.yaml conf/benchmarkConf.yaml
  ./stream-bench.sh FLINK_TEST_FAILURE
  mv data/latencies.txt results/latencies-10000k-50ms-3cores-checkpoint-2000ms-exactly-once-failure-flink-$i.txt
  sleep 10
done

#----------------------------
for i in `seq 1 10` ; do
  cp conf/benchmarkConf-10000k-50ms-3cores-checkpoint-1000ms.yaml conf/benchmarkConf.yaml
  ./stream-bench.sh FLINK_TEST
  mv data/latencies.txt results/latencies-10000k-50ms-3cores-checkpoint-1000ms-exactly-once-flink-$i.txt
  sleep 10
done

#----------------------------
for i in `seq 1 10` ; do
  cp conf/benchmarkConf-10000k-50ms-3cores-checkpoint-1000ms.yaml conf/benchmarkConf.yaml
  ./stream-bench.sh FLINK_TEST_FAILURE
  mv data/latencies.txt results/latencies-10000k-50ms-3cores-checkpoint-1000ms-exactly-once-failure-flink-$i.txt
  sleep 10
done

#----------------------------
for i in `seq 1 10` ; do
  cp conf/benchmarkConf-10000k-50ms-3cores-checkpoint-5000ms.yaml conf/benchmarkConf.yaml
  ./stream-bench.sh FLINK_TEST
  mv data/latencies.txt results/latencies-10000k-50ms-3cores-checkpoint-5000ms-exactly-once-flink-$i.txt
  sleep 10
done

#----------------------------
for i in `seq 1 10` ; do
  cp conf/benchmarkConf-10000k-50ms-3cores-checkpoint-5000ms.yaml conf/benchmarkConf.yaml
  ./stream-bench.sh FLINK_TEST_FAILURE
  mv data/latencies.txt results/latencies-10000k-50ms-3cores-checkpoint-5000ms-exactly-once-failure-flink-$i.txt
  sleep 10
done
