# deploy

#### Table of Contents

1. [Overview](#overview)
2. [Module Description - What the module does and why it is useful](#module-description)
3. [Setup - The basics of getting started with deploy](#setup)
4. [Usage - Configuration options and additional functionality](#usage)
5. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
6. [Limitation - Limitations/to do list of the module](#limitations)
7. [Release Notes - Release Notes](#release-notes)
7. [Contributors - Contributors to this module](#contributors)

## Overview

This module can be used to trigger the bamboo deploy jobs (only DEPLOY jobs, not BUILD jobs)

## Module Description

This module does following things:
1. Reads the list of bamboo deploy jobs to be run on underlying host from hiera configs.
2. Triggers each deploy job, get result of the deploy job and log into a /tmp/deploy_JOBID.log file
3. It uses bamboo rest api calls to obtain result and simple Post request for triggering
(because bamboo doesn't support rest-api for deployment projects at the moment,
there are rest-api calls available for build-plans/projects though.)

## Setup

## Usage
class {'deploy' :
  stage => 'deploystage',
}

## Reference


## Limitations

This is where you list OS compatibility, version compatibility, etc.

## Release Notes:

### Version: 1.0.1
1. Replaced bash shell script with Type/Provider, custom facts. No functionality change. Just optimizing and making it idempotent.

### Version: 1.0.0
1. Initial working release

## Contributors

Nalini Patel nalinidpatel@yahoo.com

