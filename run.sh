FIO_PATH="${HOME}/fio/fio"

numactl --cpunodebind=0 $FIO_PATH --thread fio_config.ini &
FIO_PID=$!

sudo /usr/sbin/profile-bpfcc -F 40000 --pid $FIO_PID -K -f -d 40 --stack-storage-size=40000 > profile_output.txt &
PROFILE_PID=$!

wait $FIO_PID

echo "Stopping profiler..."
sudo kill -SIGINT $PROFILE_PID
wait $PROFILE_PID

FlameGraph/flamegraph.pl --title="Flame Graph for fio" profile_output.txt > flamegraph.svg