# mTLS GOST Proxy for Integration with VTB (CryptoPro + cpnginx)

## Overview

A Docker container that proxies SOAP/HTTP requests to VTB Bank via GOST TLS using CryptoPro CSP and cpnginx.
This container is intended for scenarios where an internal service sends a request to a local proxy, which wraps the traffic in mTLS and forwards it to the external VTB API.

## Project Structure

- ```Dockerfile``` - automated image build
- ```distr/``` - CryptoPro CSP distribution for Linux
- ```csp/``` - license files
- ```cpnginx-keys/cpnginx/``` - key containers generated for the ```cpnginx``` user
- ```conf/nginx.conf``` - cpnginx (nginx) configuration file
- ```cert/``` - VTB's root and middle certificates

## Dockerfile Adjustments

You must modify the ```Dockerfile``` according to your own parameters and environment.
Below are key steps to integrate CryptoPro CSP and TLS licenses, and configure key containers.

### Add CryptoPro CSP and TLS Licenses
```
COPY csp/csp_license.txt /tmp/csp_license.txt
COPY csp/tls_license.txt /tmp/tls_license.txt
```

### If You Already Have ```.key``` Containers

Place the prepared key containers into the ```cpnginx-keys/cpnginx/``` folder and include:

```
COPY cpnginx-keys/cpnginx/ /var/opt/cprocsp/keys/cpnginx/
RUN chown -R cpnginx:cpnginx /var/opt/cprocsp/keys/cpnginx
RUN usermod -s /bin/bash cpnginx || true
ENV HOME=/var/opt/cprocsp/keys/cpnginx
RUN su -s /bin/bash -c "/opt/cprocsp/bin/amd64/csptest -absorb -certs -autoprov" cpnginx

```

### If You Only Have a ```.pfx``` File
If key containers are not available but you have a ```.pfx```, you can install the certificate like this:

```
RUN /opt/cprocsp/bin/amd64/certmgr -install -store uMy -pfx -file /tmp/certs/certificatename.pfx -pin XXXXXXXX -silent -provtype 80 -provname 'Crypto-Pro GOST R 34.10-2012 Cryptographic Service Provider'
```
> Replace ```certificatename.pfx``` and ```XXXXXXXX``` with your actual certificate filename and password.
