"""
    Flask 101 is a simple flask application that can be used to demonstrate a
    few things including how to use microservices with docker.
"""
import os
import json
from datetime import timedelta, datetime
from flask import Flask

APP = Flask(__name__)

@APP.route('/')
def main():
    """Manages the application root"""
    return ('', 404)


@APP.route('/simple-api/version')
def appversion():
    """Displays the application version"""
    vfile = open("version.txt", "r")
    version = vfile.read()[:-1]
    vfile.close()
    return ("\\033[1;36m{\"version\": \"%s\"}\\033[0m" % version, 200)
    # return ("\\033[1;32m{\"version\": \"%s\"}\\033[0m" % version, 200)

@APP.route('/status')
def status():
    """Provides a status of the API"""
    return('GOOD', 200)


@APP.route('/simple-api/check')
def check():
    """Returns execution and configuration properties"""
    now = int(datetime.now().strftime('%s'))
    delta = now - APP.starttime
    output = {"uptime": timedelta(seconds=delta),
              "envs":[]}
    for key, value in os.environ:
        output["envs"].append({key: value})
    return (json.dumps(output), 200)

if __name__ == '__main__':
    APP.starttime = int(datetime.now().strftime('%s'))
    APP.run(debug=False, host='0.0.0.0', port=8080)
