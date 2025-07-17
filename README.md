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

### Exporting ```.key``` Files from a ```.pfx```
> I encountered issues when trying to import a .pfx certificate directly into the CryptoPro container — the process completed without error, but the certificate was not fully functional, likely due to internal key access restrictions.

> The issue was resolved by first importing the .pfx inside the container to generate .key containers, and then copying those .key files out for consistent reuse. This approach ensures proper key registration and reliable operation within the cpnginx environment.
If you're having trouble importing a ```.pfx``` certificate directly into your project, you can import it inside the container, then extract the generated ```.key``` files for reuse:
```
su - cpnginx
/opt/cprocsp/bin/amd64/certmgr -inst -provtype 24 -pfx -pin "YOUR_PASSWORD" -file /tmp/cert.pfx
/opt/cprocsp/bin/amd64/certmgr -list
exit
docker cp <container_id>:/var/opt/cprocsp/keys/cpnginx ./cpnginx-keys
```
> These ```.key``` files can then be reused in your project by placing them under ```cpnginx-keys/cpnginx/```.

## NGINX Configuration (cpnginx)

In the ```nginx.conf``` file, you must specify the SKI (Subject Key Identifier) of the certificate used to sign the TLS tunnel for mTLS.

```
proxy_ssl_certificate 0xYOUR_SKI_HERE;
```

Replace ```0xYOUR_SKI_HERE``` with the actual SKI of the certificate that is installed in the CryptoPro store and has access to the private key.

This SKI identifies the GOST certificate that will be used for establishing the mutual TLS connection.
