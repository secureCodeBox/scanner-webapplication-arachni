---
title: "Arachni"
path: "scanner/Arachni"
category: "scanner"
usecase: "Webapplication Vulnerabilty Scanner"
release: "https://img.shields.io/github/release/secureCodeBox/scanner-webapplication-arachni.svg"

---

![arachni logo](https://www.arachni-scanner.com/wp-content/uploads/2013/03/arachni-web-logo.png)

Arachni is an Open Source, feature-full, modular, high-performance Ruby framework aimed towards helping penetration testers and administrators evaluate the security of web applications. It is smart, it trains itself by learning from the HTTP responses it receives during the audit process and is able to perform meta-analysis using a number of factors in order to correctly assess the trustworthiness of results and intelligently identify false-positives.

<!-- end -->

# Important License information

The code in this repository is licensed under Apache 2.0.

Arachni is licensed under the [Arachni Public Source License](ARACHNI_LICENSE.md) with using this scanner you have to agree to the license!

# About

This is a self contained µService utilizing the Arachni Web Scanner for the secureBox Application. To learn more about the Arachni scanner itself visit [arachni-scanner.com].

## Arachni parameters
To hand over supported parameters through api usage, you can set following attributes:

```json
[
  {
    "context": "some context",
    "name": "arachni",
    "target": {
      "name": "some name",
      "location": "your-target",
      "attributes": {
        "ARACHNI_DOM_DEPTH_LIMIT": "[int limit]",
        "ARACHNI_DIR_DEPTH_LIMIT": "[int limit]",
        "ARACHNI_PAGE_LIMIT": "[int limit]",
        "ARACHNI_EXCLUDE_PATTERNS": [
          "patterns e.g. :"
          ".*\\.png",
          ".*util\\.js",
          ".*style\\.css"
        ],
        "ARACHNI_SCAN_METHODS": "[method name]",
        "ARACHNI_REQUESTS_PER_SECOND": "[seconds]",
        "ARACHNI_POOL_SIZE": "[size]",
        "ARACHNI_REQUEST_CONCURRENCY": "[int concurency]"
      }
    }
  }
]
```
## Example
Example configuration:

```json
[
  {
    "name": "arachni",
    "context": "Example Test",
    "target": {
      "name": "BodgeIT on OpenShift",
      "location": "bodgeit-scb.cloudapps.iterashift.com",
      "attributes": {}
    }
  }
]
```

Example output:
Due to some technical problems we cannot provide Arachni scans at the moment. 

## Development

### Configuration Options

To configure this service specify the following environment variables:

| Environment Variable       | Value Example |
| -------------------------- | ------------- |
| ENGINE_ADDRESS             | http://engine |
| ENGINE_BASIC_AUTH_USER     | username      |
| ENGINE_BASIC_AUTH_PASSWORD | 123456        |

## Development

### Local setup

1. Clone the repository
2. You might need to install some dependencies `gem install sinatra rest-client`
3. Run locally `ruby src/main.rb`

### Test

To run the testsuite run:

`rake test`

## Build with docker

To build the docker container run:

`docker build -t IMAGE_NAME:LABEL .`


[![Build Status](https://travis-ci.com/secureCodeBox/scanner-webapplication-arachni.svg?branch=master)](https://travis-ci.com/secureCodeBox/scanner-webapplication-arachni)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![GitHub release](https://img.shields.io/github/release/secureCodeBox/scanner-webapplication-arachni.svg)](https://github.com/secureCodeBox/scanner-webapplication-arachni/releases/latest)


[arachni-scanner.com]: https://www.arachni-scanner.com/
