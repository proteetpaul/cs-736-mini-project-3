FIO_PATH="${HOME}/fio/fio"

DURATION=40
DURATION_PROFILER=$DURATION+5

numactl --cpunodebind=0 $FIO_PATH --thread fio_config.ini --runtime $DURATION &
FIO_PID=$!

numactl --cpunodebind=0 sudo bpftrace -e \
    "tracepoint:kyber:kyber_adjust { printf(\"Domain: %s, queue depth: %d, device: %d\n\", args->domain, args->depth, args->dev); }" \
    > bpftrace_output.txt &
BPFTRACE_PID=$!

sudo numactl --cpunodebind=0 /usr/sbin/biolatency-bpfcc --queued --disk nvme1n1 > biolatency_output.txt $DURATION_PROFILER 1 &
BIOLATENCY_PID=$!

wait $FIO_PID

sudo kill -SIGINT $BPFTRACE_PID
wait $BPFTRACE_PID

wait $BIOLATENCY_PID

# FlameGraph/flamegraph.pl --title="Flame Graph for fio" profile_output.txt > flamegraph.svg