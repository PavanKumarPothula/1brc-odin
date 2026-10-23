# 1 Billion Row Challenge

My attempt at the [1 Billion Row Challenge](https://github.com/gunnarmorling/1brc/tree/main) using the Odin programming language.

The data was synthesized using the `create_measurements.py` script from the challenge's repo (I had to replace hard-coded filepaths of `weather_stations.csv` and `measurements.txt`). I used the `create_measurements_test.sh` bash script to create test subsets of 1,000, 1,000,000 and 100,000,000 rows each.

## Attempt 1

With my first attempt, I was able to process the 1 billion rows in 186 seconds on my laptop (approximately 3 minutes, run with `odin run . -o:speed`).