![Build Status](https://travis-ci.com/secureCodeBox/scanner-webapplication-arachni.svg?token=2Rsf2E9Bq3FduSxRf6tz&branch=develop)
![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

# About

This is a self contained µService utilizing the Arachni Web Scanner for the secureBox Application.

## Configuration Options
To configure this service specify the following environment variables:

| Environment Variable       | Value Example         |
| -------------------------- | --------------------- |
| ENGINE_ADDRESS             | http://engine         |
| ENGINE_BASIC_AUTH_USER     | username              |
| ENGINE_BASIC_AUTH_PASSWORD | 123456                |

## Build with docker

To build the docker container run: `docker build -t CONTAINER_NAME:LABEL .`
