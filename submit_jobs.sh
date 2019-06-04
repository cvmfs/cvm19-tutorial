#!/bin/sh

staging_server=http://cvm-perf03.cern.ch:9000/cvmfs-publisher-test

# Submit a set of independent jobs
ids=""
for i in $(seq 1 10) ; do
    id=$(conveyor submit \
         --repo cvm19.cern.ch \
         --lease-path /ripgrep-0.$i.0 \
         --payload "script|${staging_server}/test_transaction.sh?checksum=sha1:6a5f9462608383fb65e6c0f7211148974bdbdc3d|${staging_server}/ripgrep/ripgrep-0.$i.0-x86_64-unknown-linux-musl.tar.gz" | tail -1 | jq -r '.job_id')
    ids="$ids $id"
done
ids=$(echo $ids | tr ' ' ,)

# Submit a final job depending on all the previous ones
conveyor submit --repo cvm19.cern.ch --deps "$ids" --wait