#!/usr/bin/python

import sys
import work_queue as wq
import time
workers = wq.Factory("condor", sys.argv[1])
workers.min_workers = 1
max_work = int(sys.argv[2])
if max_work <= 0:
	workers.max_workers = 5
workers.cores = int(sys.argv[3])
workers.memory = int(sys.argv[4])
workers.disk = int(sys.argv[5])
with workers:
	while True:
		time.sleep(1)
