"""
    Flask Gateway is a simple that relies on Consul to call the flask-101
    service. It can be easily used to demonstrate blue/green deployment.
"""
from flask import Flask
import requests

APP = Flask(__name__)

@APP.route('/')
def main():
    """Manages the application root"""
    return ('', 404)

def getservice(node, service):
    """Query consul and return the HTTP URI of a given service"""
    query = "http://" + node + ":8500/v1/catalog/service/" + service
    output = requests.get(query).json()
    return "http://"+output[0]["Address"]+":"+str(output[0]["ServicePort"])


@APP.route('/simple-api')
def simpleapi():
    """Cross-Microservice call"""
    url = getservice(APP.node, "simple-api")
    key = requests.get(url + "/simple-api/version", timeout=1)
    return (key.text, 200)


@APP.route('/simple-gateway/version')
def appversion():
    """Displays the application version"""
    vfile = open("version.txt", "r")
    version = vfile.read()[:-1]
    vfile.close()
    return ("{\"version\": \"%s\"}" % version, 200)

@APP.route('/status')
def status():
    """Provides a status of the API"""
    return('GOOD', 200)

if __name__ == '__main__':
    APP.node = requests.get("http://169.254.169.254/latest/meta-data/local-ipv4").text
    APP.run(debug=False, host='0.0.0.0', port=8080)
