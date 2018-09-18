### Flink benchmark

This benchmark runs flink.benchmark.AdvertisingTopologyFlinkWindows. Make sure to pull the up-to-date branch first.

1) Write the list of slave IPs to `conf/slaves`.
2) In `conf/benchmarkConf_custom.yaml`:
    - set the following parameters    
    ```yaml
      process.hosts # to a value less than or equal to the number of slaves
      redis.host # to the head node IP
      load.target.hz # to the system load target in events/s
    ```
    - the Kafka and Zookeeper parameters don't really matter.
2) Set up HDFS and start a cluster.
    - On the AMI it's already installed at `~/yahoo-streaming-benchmark/hadoop-2.6.5/`.
    - In theory you can just:
      ```bash
      # (a) set up ssh keys
      # (b) modify hadoop-2.6.5/etc/core-site.xml to use your master IP
      # (c):
      cp conf/slaves hadoop-2.6.5/etc/
      ./format-and-start-hdfs.sh
      ```
3) In `conf/flink_conf.yaml`:
    - set the following parameters
    ```yaml
      jobmanager.rpc.address # as the master IP
      state.backend.fs.checkpointdir # as the checkpoint directory
      fs.hdfs.hadoopconf # to where the conf files live.
      ```
    - Note: `conf/flink_conf.yaml` is copied and rsynced automatically by `run_flink_experiments.sh` every run
4) Build and run the experiment
    ```bash
    mvn package
    ./run_flink_experiments.sh`
    ```

