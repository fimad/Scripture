#!/bin/bash
#will extract tcp streams from the parent directory into the current dir

ls ../ | grep cap.http | sed -r 's/^/..\//g' | xargs tcptrace -e
