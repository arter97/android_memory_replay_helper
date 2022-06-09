#!/bin/bash

ls results/ | while read t; do
  echo
  echo $t
  rm -f /tmp/mem-*
  ls traces/ | grep '\.zip$' | sed 's/.zip//g' | sort | while read f; do
    (
      echo $f
      for i in results/$t/$f.*; do
        tail -n3 $i | head -n1 | awk '{print $4}'
      done
    ) > /tmp/mem-$f
  done
  paste -d, /tmp/mem-*
  rm -f /tmp/mem-*
done
