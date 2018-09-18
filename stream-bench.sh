#!/bin/bash
# Copyright 2015, Yahoo Inc.
# Licensed under the terms of the Apache License 2.0. Please see LICENSE file in the project root for terms.
set -o pipefail
set -o errtrace
set -o nounset
set -o errexit
set -x

LEIN=${LEIN:-lein}
MVN=${MVN:-mvn}
GIT=${GIT:-git}
MAKE=${MAKE:-make}

KAFKA_VERSION=${KAFKA_VERSION:-"0.8.2.1"}
REDIS_VERSION=${REDIS_VERSION:-"3.0.5"}
SCALA_BIN_VERSION=${SCALA_BIN_VERSION:-"2.10"}
SCALA_SUB_VERSION=${SCALA_SUB_VERSION:-"4"}
STORM_VERSION=${STORM_VERSION:-"1.0.0"}
FLINK_VERSION=${FLINK_VERSION:-"1.0.1"}
SPARK_VERSION=${SPARK_VERSION:-"1.5.1"}

STORM_DIR="apache-storm-$STORM_VERSION"
REDIS_DIR="redis-$REDIS_VERSION"
KAFKA_DIR="kafka_$SCALA_BIN_VERSION-$KAFKA_VERSION"
FLINK_DIR="flink-$FLINK_VERSION"
SPARK_DIR="spark-$SPARK_VERSION-bin-hadoop2.6"

ZK_HOST="localhost"
ZK_PORT="2181"
ZK_CONNECTIONS="$ZK_HOST:$ZK_PORT"
TOPIC=${TOPIC:-"ad-events"}
PARTITIONS=${PARTITIONS:-1}
LOAD=${LOAD:-1000}
CONF_FILE=./conf/benchmarkConf.yaml
TEST_TIME=${TEST_TIME:-300}
POST_FAILURE_TIME=${POST_FAILURE_TIME:-300}

pid_match() {
   local VAL=`ps -aef | grep "$1" | grep -v grep | awk '{print $2}'`
   echo $VAL
}

start_if_needed() {
  local match="$1"
  shift
  local name="$1"
  shift
  local sleep_time="$1"
  shift
  local PID=`pid_match "$match"`

  if [[ "$PID" -ne "" ]];
  then
    echo "$name is already running..."
  else
    "$@" &
    sleep $sleep_time
  fi
}

stop_if_needed() {
  local match="$1"
  local name="$2"
  local PID=`pid_match "$match"`
  if [[ "$PID" -ne "" ]];
  then
    kill "$PID"
    sleep 1
    local CHECK_AGAIN=`pid_match "$match"`
    if [[ "$CHECK_AGAIN" -ne "" ]];
    then
      kill -9 "$CHECK_AGAIN"
    fi
  else
    echo "No $name instance found to stop"
  fi
}

fetch_untar_file() {
  local FILE="download-cache/$1"
  local URL=$2
  if [[ -e "$FILE" ]];
  then
    echo "Using cached File $FILE"
  else
	mkdir -p download-cache/
    wget -O "$FILE" "$URL"
  fi
  tar -xzvf "$FILE"
}

create_kafka_topic() {
    local count=`$KAFKA_DIR/bin/kafka-topics.sh --describe --zookeeper "$ZK_CONNECTIONS" --topic $TOPIC 2>/dev/null | grep -c $TOPIC`
    if [[ "$count" = "0" ]];
    then
        $KAFKA_DIR/bin/kafka-topics.sh --create --zookeeper "$ZK_CONNECTIONS" --replication-factor 1 --partitions $PARTITIONS --topic $TOPIC
    else
        echo "Kafka topic $TOPIC already exists"
    fi
}

run() {
  OPERATION=$1
  if [ "SETUP" = "$OPERATION" ];
  then
    $GIT clean -fd
    $MVN clean install -Dspark.version="$SPARK_VERSION" -Dkafka.version="$KAFKA_VERSION" -Dflink.version="$FLINK_VERSION" -Dstorm.version="$STORM_VERSION" -Dscala.binary.version="$SCALA_BIN_VERSION" -Dscala.version="$SCALA_BIN_VERSION.$SCALA_SUB_VERSION"

    #Fetch and build Redis
    REDIS_FILE="$REDIS_DIR.tar.gz"
    fetch_untar_file "$REDIS_FILE" "http://download.redis.io/releases/$REDIS_FILE"

    cd $REDIS_DIR
    $MAKE
    cd ..

    #Fetch Flink
    FLINK_FILE="$FLINK_DIR-bin-hadoop27-scala_${SCALA_BIN_VERSION}.tgz"
    fetch_untar_file "$FLINK_FILE" "https://archive.apache.org/dist/flink/flink-$FLINK_VERSION/$FLINK_FILE"

  elif [ "START_REDIS" = "$OPERATION" ];
  then
    start_if_needed redis-server Redis 1 sudo "$REDIS_DIR/src/redis-server" /etc/redis/6379.conf
    cd data
    $LEIN run -n --configPath ../conf/benchmarkConf.yaml
    cd ..
  elif [ "STOP_REDIS" = "$OPERATION" ];
  then
    stop_if_needed redis-server Redis
    rm -f dump.rdb
  elif [ "START_LOAD" = "$OPERATION" ];
  then
    cd data
    start_if_needed leiningen.core.main "Load Generation" 1 $LEIN run -r -t $LOAD --configPath ../$CONF_FILE
    cd ..
  elif [ "STOP_LOAD" = "$OPERATION" ];
  then
    stop_if_needed leiningen.core.main "Load Generation"
    cd data
    $LEIN run -g --configPath ../$CONF_FILE || true
    paste -d' ' times.txt updated.txt | sort -n > latencies.txt
    cd ..
  elif [ "START_FLINK" = "$OPERATION" ];
  then
    cp conf/slaves $FLINK_DIR/conf/
    cp conf/flink-conf.yaml $FLINK_DIR/conf/
    start_if_needed org.apache.flink.runtime.jobmanager.JobManager Flink 1 $FLINK_DIR/bin/start-cluster.sh
    echo "sleeping 60..."
    sleep 60
  elif [ "STOP_FLINK" = "$OPERATION" ];
  then
    $FLINK_DIR/bin/stop-cluster.sh
  elif [ "START_FLINK_PROCESSING" = "$OPERATION" ];
  then
    "$FLINK_DIR/bin/flink" run -c flink.benchmark.AdvertisingTopologyFlinkWindows ./flink-benchmarks/target/flink-benchmarks-0.1.0.jar $CONF_FILE &
    sleep 3
  elif [ "STOP_FLINK_PROCESSING" = "$OPERATION" ];
  then
    FLINK_ID=`"$FLINK_DIR/bin/flink" list | grep 'Flink Streaming Job' | awk '{print $4}'; true`
    if [ "$FLINK_ID" == "" ];
	then
	  echo "Could not find streaming job to kill"
    else
      "$FLINK_DIR/bin/flink" cancel $FLINK_ID
      sleep 3
    fi
  elif [ "FLINK_TEST_FAILURE" = "$OPERATION" ];
  then
    run "START_REDIS"
    run "START_FLINK"
    run "START_FLINK_PROCESSING"
    sleep 240
    ssh caelum-302 "cd ~/data-artisans-ycsb/flink-1.0.1/bin/ ; ./taskmanager.sh stop ;" # sleep 1 ; ./taskmanager.sh start"
    sleep 159
    run "STOP_LOAD"
    run "STOP_FLINK_PROCESSING"
    run "STOP_FLINK"
    run "STOP_REDIS"
  elif [ "FLINK_TEST" = "$OPERATION" ];
  then
    run "START_REDIS"
    run "START_FLINK"
    run "START_FLINK_PROCESSING"
    WORKER=`tail -n 1 conf/slaves`
    sleep $TEST_TIME
    echo "KILLING $WORKER"
    ssh $WORKER "cd ~/yahoo-streaming-benchmark/flink-1.0.1/bin/ ; ./taskmanager.sh stop ; sleep 1 ; ./taskmanager.sh start"
    sleep $POST_FAILURE_TIME
    run "STOP_FLINK_PROCESSING"
    run "STOP_LOAD" # to compute stats
    run "STOP_FLINK"
    run "STOP_REDIS"
  elif [ "STOP_ALL" = "$OPERATION" ];
  then
#    run "STOP_LOAD"
    run "STOP_FLINK_PROCESSING"
    run "STOP_FLINK"
    run "STOP_LOAD"
    run "STOP_REDIS"
  elif [ "REBUILD" = "$OPERATION" ];
  then
    $MVN clean install -Dspark.version="$SPARK_VERSION" -Dkafka.version="$KAFKA_VERSION" -Dflink.version="$FLINK_VERSION" -Dstorm.version="$STORM_VERSION" -Dscala.binary.version="$SCALA_BIN_VERSION" -Dscala.version="$SCALA_BIN_VERSION.$SCALA_SUB_VERSION"
  else
    if [ "HELP" != "$OPERATION" ];
    then
      echo "UNKOWN OPERATION '$OPERATION'"
      echo
    fi
    echo "Supported Operations:"
    echo "SETUP: download and setup dependencies for running a single node test"
    echo "START_ZK: run a single node ZooKeeper instance on local host in the background"
    echo "STOP_ZK: kill the ZooKeeper instance"
    echo "START_REDIS: run a redis instance in the background"
    echo "STOP_REDIS: kill the redis instance"
    echo "START_KAFKA: run kafka in the background"
    echo "STOP_KAFKA: kill kafka"
    echo "START_LOAD: run kafka load generation"
    echo "STOP_LOAD: kill kafka load generation"
    echo "START_STORM: run storm daemons in the background"
    echo "STOP_STORM: kill the storm daemons"
    echo "START_FLINK: run flink processes"
    echo "STOP_FLINK: kill flink processes"
    echo "START_SPARK: run spark processes"
    echo "STOP_SPARK: kill spark processes"
    echo 
    echo "START_STORM_TOPOLOGY: run the storm test topology"
    echo "STOP_STORM_TOPOLOGY: kill the storm test topology"
    echo "START_FLINK_PROCESSING: run the flink test processing"
    echo "STOP_FLINK_PROCESSSING: kill the flink test processing"
    echo "START_SPARK_PROCESSING: run the spark test processing"
    echo "STOP_SPARK_PROCESSSING: kill the spark test processing"
    echo
    echo "STORM_TEST: run storm test (assumes SETUP is done)"
    echo "FLINK_TEST: run flink test (assumes SETUP is done)"
    echo "SPARK_TEST: run spark test (assumes SETUP is done)"
    echo "STOP_ALL: stop everything"
    echo
    echo "HELP: print out this message"
    echo
    exit 1
  fi
}

if [ $# -lt 1 ];
then
  run "HELP"
else
  while [ $# -gt 0 ];
  do
    run "$1"
    shift
  done
fi
