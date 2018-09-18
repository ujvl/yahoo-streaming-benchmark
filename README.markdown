
# Extending the Yahoo Streaming Benchmarks 


### Background
This code is a fork of the original [Yahoo! Streaming benchmark code](https://github.com/yahoo/streaming-benchmarks).

We have added to this the following additional benchmarking programs. They are all variations of the original Yahoo! benchmarks.

For additional background please read ["Extending the Yahoo! Streaming Benchmark"](http://data-artisans.com/extending-the-yahoo-streaming-benchmark/) and ["Benchmarking Streaming Computation Engines at Yahoo!"](http://yahooeng.tumblr.com/post/135321837876/benchmarking-streaming-computation-engines-at)


#### flink.benchmark.AdvertisingTopologyFlinkWindows
This Flink program does the same operation in Flink as in the original benchmarks but uses Flink's native windowing and trigger support to accomplish the same things.  It computes 10 seconds windows, emitting them to Redis when they're complete and also emits early updates every second.

#### flink.benchmark.AdvertisingTopologyRedisDirect
This Flink program builds 60 minute windows directly in Redis.  It's purpose is to illustrate the key-value store as the bottleneck when you don't have fault-tolerant state in the streaming system.  Flink provides alternatives to this approach.  The window time is configurable.

#### flink.benchmark.state.AdvertisingTopologyFlinkState
This Flink program is an example of using the Flink nodes themselves as the key-value store to eliminate a remote store as the limit to throughput.  By default it computes 60 minute windows but this is configurable.

#### flink.benchmark.state.AdvertisingTopologyFlinkStateHighKeyCard
This is the same as above but in addition it is designed for a very high key cardinality.

#### flink.benchmark.state.AkkaStateQuery
This program is used to query the key-value state directly in the Flink nodes.  This in comb ination with either of the two -FlinkState programs above is what allows you to eliminate the key-value store altogether.

#### storm.benchmark.AdvertisingTopologyHighKeyCard
This Storm program is derivative of Yahoo's original AdvertisingTopology code.  The difference is that it is designed for very high #'s of campaigns and builds the output windows by directly updating them in Redis.  This benchmark represents any computation where it's neccessary to build state outside of the streaming system such that it's fault tolerant.  Many applications in production work exactly this way and typically their throughput is limited by the remote key-value store.  The windows in this case are set to 60 minutes by default but this is configurable.

#### flink.benchmark.genertor.AdImpressionGenerator
A data generator for Flink compatible with the original Yahoo data generator.  This generator runs via Flink and writes data to Kafka.  It can also be embedded directly in your Flink program as a source if Kafka becomes a bottleneck.  This is the generator we used in the benchmarks as it was difficult to get the Clojure based generator to run at a high enough throughput for our experiments.

#### flink.benchmark.generator.AdImpressionsGeneratorHighKeyCardinality
Same as the generator described above but updated to generate a much higher number of ad campaigns.  The number of ad campaigns is configurable.


### Configuration
We've continued to use the benchmarkConf.yaml for all configuration.  You'll need to edit this file for your environment and also to control various parameters both for the load generators and the benchmarking programs.

### Results
For most of these benchmarks the results are collected using Yahoo's original scripts.  See that benchmark for more details.  In the case of the -FlinkState programs use the AkkaStateQuery program to retrieve the results.

### Other notes
This code was built and tested against Flink 1.0-SNAPSHOT (master on Jan 27, 2016) and Storm 2.0.0-SNAPSHOT (SHA a8d253). 

### [Ujval] Flink benchmark, running flink.benchmark.AdvertisingTopologyFlinkWindows
1) Write the list of slave IPs to `conf/slaves`, separated by newlines.
2) In `conf/benchmarkConf_custom.yaml`:
    - make sure `process.hosts` is set to a values less than or equal to the number of slaves in `conf/slaves`.
    - set `redis.host` to the head node IP
    - set the cluster-wide load target in events/s: `load.target.hz` 
    - the Kafka and Zookeeper parameters don't really matter.
2) Set up HDFS and start a cluster. 
    - On the AMI it's already installed at `~/yahoo-streaming-benchmark/hadoop-2.6.5/`. 
    - In theory you can just copy your slaves file into `hadoop-2.6.5/etc/` and then run `./format-and-start-hdfs.sh` if your ssh keys are set up properly.
    - There are copies of `core-site.xml` and `hdfs-site.xml` that I used in `conf/`. 
3) In `conf/flink_conf.yaml`:
    - Set `jobmanager.rpc.address` as the master IP
    - Set `state.backend.fs.checkpointdir`.
    - Set `fs.hdfs.hadoopconf` to where the conf files live.
    - Note: `conf/flink_conf.yaml` is copied and rsynced automatically by `run_flink_experiments.sh` every run
3) `mvn package` from the root dir of the project
3) Run `./run_flink_experiments.sh`.

