Meda Performance Test Plan
--------------------------

Note that there is a bug in which ruby-jmeter does not work under jRuby.
So the environment that drives the load must run in MRI Ruby 1.9+.

So you must have the following installed

1. jRuby
2. MRI Ruby 1.9.3 or later
3. jMeter

++ What this Test Does

Each loop simulates a lightning-fast user session

1. Randomizes user data: member_id, client_id, profile attibutes
2. Posts to IDENTIFY, and extracts the profile_id
3. Posts to PROFILE, and sets profile attributes
4. 10x posts to PAGE, to create page views
5. 10x posts to TRACK, to create events

++ Local Load Test

Run a local collector with the given config.ru. This sets up a temporary dataset for each run.

```bash
$ puma perf/config.ru
```

1. Change to another shell
2. cd to the meda checkout
3. switch to MRI Ruby 2.0+
4. bundle install
5. Run the flood script with the loads you want to run. For example...

```bash
$ ruby perf/flood.rb 50 100 200
```

Assuming everything goes OK, you can now run the analyze script.

```bash
$ ruby perf/analyze.rb 50 100 200
```

++ EC2 Load Test

Set up the collector on EC2 with a throwaway perf test dataset.

Copy the local flood script, and change the HOST, PROTOCOL and TOKEN params.

Run the flood and analyze scripts as above.

++ Caveats

1. Performance will be highly dependent on the puma config (# of threads, etc.)
2. Performance will be highly dependent on JVM config, and whether the JVM is "warmed up"
3. Short runs will give highly variable and misleading results
4. If you also test streaming to GA, watch out for the quotas. ie don't send 1,000,000 events in one hour.

++ Sample Output

```
Analyzing perf/results/perf_test_10_results.jtl

IDENTIFY
---------------------
Total hits = 1000
Successful responses = 1000
Error responses = 0
Mean response time = 10 ms
Transaction rate = 92.83 trans/sec
50% response time = 3 ms
90% response time = 18 ms

PROFILE
---------------------
Total hits = 1000
Successful responses = 1000
Error responses = 0
Mean response time = 10 ms
Transaction rate = 96.15 trans/sec
50% response time = 3 ms
90% response time = 17 ms

PAGE
---------------------
Total hits = 10000
Successful responses = 10000
Error responses = 0
Mean response time = 12 ms
Transaction rate = 78.81 trans/sec
50% response time = 4 ms
90% response time = 30 ms

EVENT
---------------------
Total hits = 10000
Successful responses = 10000
Error responses = 0
Mean response time = 12 ms
Transaction rate = 77.21 trans/sec
50% response time = 4 ms
90% response time = 29 ms

Summary
---------------------

Total hits = 22000
Successful responses = 22000
Error responses = 0
Mean response time = 12 ms
Transaction rate = 79.26 trans/sec
50% response time = 3 ms
90% response time = 29 ms
```