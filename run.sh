FIO_PATH="${HOME}/fio/fio"

DURATION_PROFILER=75

numactl --cpunodebind=0 $FIO_PATH --thread fio_config.ini &
FIO_PID=$!

numactl --cpunodebind=0 sudo bpftrace -e \
    "tracepoint:kyber:kyber_adjust { printf(\"Domain: %s, queue depth: %d, device: %d\n\", args->domain, args->depth, args->dev); }" \
    > bpftrace_output.txt &
BPFTRACE_PID=$!

sudo numactl --cpunodebind=0 /usr/sbin/biolatency-bpfcc --queued --disk nvme1n1 > biolatency_output.txt $DURATION_PROFILER 1 &
BIOLATENCY_PID=$!

sudo numactl --cpunodebind=0 /usr/sbin/biosnoop-bpfcc --queue --disk nvme1n1 > biosnoop_output.txt &
BIOSNOOP_PID=$!

wait $FIO_PID

sudo kill -SIGINT $BPFTRACE_PID
wait $BPFTRACE_PID

wait $BIOLATENCY_PID

echo $FIO_PID
sudo kill -SIGINT $BIOSNOOP_PID
wait $BIOSNOOP_PID

python3 parse_biosnoop.py --pid $FIO_PID --file biosnoop_output.txt
# FlameGraph/flamegraph.pl --title="Flame Graph for fio" profile_output.txt > flamegraph.svga