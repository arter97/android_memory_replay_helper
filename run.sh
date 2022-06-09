#!/bin/bash

set -eo pipefail

get_mw() {
  VOLT=$(cat /sys/class/power_supply/battery/voltage_now)
  AMP=$((-$(cat /sys/class/power_supply/battery/current_now)))
  mW=$((($VOLT * $AMP) / 1000000000))
  echo $mW
}

IDLE=2200 # mW
CONSISTENT=10
SLEEP=0.2

wait_for_idle() {
  echo "Waiting to enter idle"
  start_time=$(date +%s%3N)

  val=()
  idx=0
  for i in $(seq 0 $(($CONSISTENT - 1))); do
    val[$i]=65535
  done
  while true; do
    val[$(($idx % $CONSISTENT))]=$(get_mw)
    sleep $SLEEP
    ret=0
    for i in $(seq 0 $(($CONSISTENT - 1))); do
      #echo "val[$i] = ${val[$i]}"
      if [[ ${val[$i]} -gt $IDLE ]]; then
        #echo "val[$i] is over $IDLE by $((${val[$i]} - $IDLE))"
        ret=1
      fi
    done
    #echo
    if [[ "$ret" == "0" ]]; then break; fi
    idx=$(($idx + 1))
  done

  end_time=$(date +%s%3N)
  echo "Entering idle took $((($end_time - $start_time) / 1000)).$((($end_time - $start_time) % 1000))s"
}

freeram() {
  sync
  echo 3 > /proc/sys/vm/drop_caches
  echo 1 > /proc/sys/vm/compact_memory
  echo 3 > /proc/sys/vm/drop_caches
  echo 1 > /proc/sys/vm/compact_memory
}

if [ ! -e traces/ ]; then
  echo "Please add traces/*.zip from system/extras/memory_replay/traces"
  exit 1
fi

# Close stdin
exec 0<&-

# Stop zram
swapoff /dev/block/zram0 || true
echo 1 > /sys/block/zram0/reset

mkdir -p results/
ls binary/ | while read e; do
  mkdir -p results/$e
  ls traces/ | grep '\.zip$' | sort | while read t; do
    for a in {0..9}; do
      freeram
      wait_for_idle
      echo "Testing $t for $(($a + 1))th time using $e"
      echo
      # Test on big cores to reduce test time (it takes hours)
      taskset -c 4-7 ./binary/$e traces/$t | tee results/$e/$t.$a
    done
  done
done
