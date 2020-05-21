#!/usr/bin/python3

# Script for testing zapi cloudwatch REST API
#
# Usage:
#     test_cwpost.py -u <ZE_API_URL> -t <ZE_API_AUTH_TOKEN>
#

import requests
import json
import pprint
import logging
import sys
import urllib3
import urllib
import argparse
import time
from io import StringIO

pp = pprint.PrettyPrinter(indent=4)
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

def tzstr():
    import calendar
    import time
    tzoffset = (calendar.timegm(time.gmtime()) - calendar.timegm(time.localtime())) / 60
    if tzoffset > 0:
        (tzsign, tzhours, tzmins) = ("-", tzoffset / 60, tzoffset % 60)
    else:
        (tzsign, tzhours, tzmins) = ("+", (-tzoffset) / 60, (-tzoffset) % 60)
    return "%s%02d:%02d" % (tzsign, tzhours, tzmins)

logger_stream = StringIO()
logging.basicConfig(stream=logger_stream,
                    level=logging.INFO,
                    format='%(asctime)s.%(msecs)03d' + tzstr() + ' %(process)d %(levelname)s: %(message)s',
                    datefmt="%Y-%m-%dT%H:%M:%S")

usage = """
%(prog)s [options]
-u <url>
-t <token>
"""

def err_exit(msg):
    sys.stderr.write(msg + "\n")
    exit(1)

def post_data(url, token, insecure):
    # ids meta data identify a log source
    ids = {}
    ids['host'] = 'test_host1'
    ids['ze_deployment_name'] = 'test_deployment1'
    ids['app'] = 'test_app'
    # Add additional user specific ids if needed
    ids['log_group'] = 'my_log_group1'
    ids['log_stream'] = 'my_log_stream1'

    # These two meta data types are NOT required but can be used for adding arbitrary configuration meta data or name-value tags
    # These are not used in any special way by the UI or incident detection.
    cfgs = {}
    tags = {}

    # This is a special set of meta data elements that are required by Zebrium
    meta_data = {}
    meta_data['stream'] = 'native' # Always use 'native'
    meta_data['logbasename'] = 'app-logfile-name' # You must set this. would typically be basename of application log or syslog, etc.
    meta_data['container_log'] = False  # These logs are NOT from a container
    meta_data['ids']  = ids   # From Settings above
    meta_data['cfgs'] = cfgs  # From Settings above
    meta_data['tags'] = tags  # From Settings above

    # generate some test messages
    for i in range(1500):
        logging.info("test msg #%d" % i)
        time.sleep(0.001)
    msgs = logger_stream.getvalue().split('\n')
    # data payload is an array of the log messages with the following format:
    #    { 'timestamp': <timestamp>, 'message': <log_msg> }
    #
    # Since server reads data in memory first, please make sure total payload
    # not exceeds a few MB.
    #
    # Please note 'timestamp' key must exist even it is not used.
    log_data = []
    for line in msgs:
        if len(line) > 0:
            epoch_ms = int(time.time() * 1000)
            log_data.append({ 'timestamp': epoch_ms, 'message': line })
    data = { 'meta_data': meta_data, 'log_data': log_data }

    headers = {
                'content-type': 'application/json',
                'Authorization': 'Token %s' % token
    }

    sess = requests.Session()
    resp = sess.post(url + '/api/v2/cwpost', verify=not insecure, json=data, headers=headers)
    if resp.status_code != 200 and resp.status_code != 201:
        pp.pprint(resp.text)
        err_exit('Failed to log in: server returned error status %d' % resp.status_code)

def main():
    parser = argparse.ArgumentParser(usage=usage)
    parser.add_argument("-u", "--url", help="Zebrium cloudwatch post API URL", default="", required=True)
    parser.add_argument("-k", "--insecure", help="Disable SSL certificate check", action='store_true', required=False)
    parser.add_argument("-t", "--token", help="Zebrium API authentication token", default="", required=True)
    args = parser.parse_args()
    post_data(args.url, args.token, args.insecure)

if __name__ == '__main__':
    main()
