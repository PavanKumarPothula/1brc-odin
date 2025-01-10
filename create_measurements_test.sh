#!/bin/bash
head -n 1000 ./data/measurements.txt >> ./data/measurements-1_000.txt
head -n 1000000 ./data/measurements.txt >> ./data/measurements-1_000_000.txt
head -n 100000000 ./data/measurements.txt >> ./data/measurements-100_000_000.txt
