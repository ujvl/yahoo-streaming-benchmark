cd hadoop*
./sbin/stop-dfs.sh
cd ..

rm -rf ~/data/*
./hosts.sh rm 'hadoop*/logs/*'
./hosts.sh rm -rf '~/data/*'

cd hadoop*
./bin/hdfs namenode -format
./sbin/start-dfs.sh
cd ..
