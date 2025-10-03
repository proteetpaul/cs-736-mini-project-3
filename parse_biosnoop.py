import argparse
import sys
import numpy as np

"""
Biosnoop output is in the following format:
TIME(s)     COMM           PID     DISK      T SECTOR     BYTES  QUE(ms) LAT(ms)
"""
def parse_biosnoop(file, pid):
    read_latencies = []
    write_latencies = []
    
    for line in file:
        line = line.strip()
        if not line or line.startswith("TIME(") or line.startswith("--"):
            continue
        parts = line.split()
        if len(parts) < 8:
            continue
        try:
            line_pid = int(parts[2])
            comm = parts[1]
            lat_ms = float(parts[-1])
            que_ms = float(parts[-2])
            type = parts[4]
        except (ValueError, IndexError):
            continue
        cond = comm.startswith("iou-wrk") or comm.startswith("iou-sqp")
        if line_pid == pid and cond:            
            if type == "R":
                read_latencies.append(lat_ms + que_ms)
            elif type == "W":
                write_latencies.append(lat_ms + que_ms)
                
    return read_latencies, write_latencies

def print_percentiles(latencies):
    if not latencies:
        print(f"No I/O events found.")
        return
    percentiles = [50, 70, 90, 99]
    values = np.percentile(latencies, percentiles)
    
    for p, v in zip(percentiles, values):
        print(f"  p{p}: {v:.3f}")
    print(f"Mean: {np.mean(latencies)}")
    print(f"  count: {len(latencies)} events")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Parse biosnoop-bpfcc output and print latency percentiles.")
    parser.add_argument("--pid", type=int, required=True, help="PID to filter")
    parser.add_argument("--file", type=str, required=True, help="Path to biosnoop output file")
    args = parser.parse_args()

    with open(args.file, "r") as f:
        read_latencies, write_latencies = parse_biosnoop(f, args.pid)
    
    print("Read latencies:")
    print_percentiles(read_latencies)
    print("Write latencies:")
    print_percentiles(write_latencies)
