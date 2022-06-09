#!/bin/bash

ls results/ | while read t; do
  echo
  echo $t
  rm -f /tmp/mem-*
  ls traces/ | grep '\.zip$' | sed 's/.zip//g' | sort | while read f; do
    (
      echo $f
      for i in results/$t/$f.*; do
        tail -n1 $i | awk '{print $4}' | sed s/ns//g
      done
    ) > /tmp/mem-$f
  done
  paste -d, /tmp/mem-*
  rm -f /tmp/mem-*
done
