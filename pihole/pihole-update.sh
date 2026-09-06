#!/bin/bash

/usr/local/bin/pihole -up \
  || { echo "ERROR: pihole -up failed" >&2; exit 1; }
/usr/local/bin/pihole -g -f \
  || { echo "ERROR: pihole -g -f failed" >&2; exit 1; }