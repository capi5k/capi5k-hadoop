capi5k-hadoop
=================

## Usage

* ```cap automatic```
* ```cap hadoop```
* ```cap hadoop:cluster:format_hdfs```
* ```cap hadoop:cluster:start```

## Running benchmarks

Use the ```BENCH```environment variable to specify the benchmark and its parameters.


```
BENCH="pi 100 100" cap hadoop:benchmark
```
The above snippet will run the pi benchmark.
