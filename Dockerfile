FROM ubuntu:22.04

RUN apt-get update && apt-get install -y lsb-release wget tar dpkg libpam0g

# Copy the CSP distribution and license
COPY distr/linux-amd64_deb.tgz /tmp/linux-amd64_deb.tgz
COPY csp/csp_license.txt /tmp/csp_license.txt
COPY csp/tls_license.txt /tmp/tls_license.txt

# Install CryptoPro CSP
RUN tar -xvf /tmp/linux-amd64_deb.tgz -C /tmp && \
    cd /tmp/linux-amd64_deb && \
    ./install.sh cprocsp-nginx && \
    rm -rf /tmp/linux-amd64_deb* && \
    LICENSE_KEY=$(cat /tmp/csp_license.txt) && \
    TLS_LICENSE_KEY=$(cat /tmp/tls_license.txt) && \
    /opt/cprocsp/sbin/amd64/cpconfig -license -set "$LICENSE_KEY" && \
    /opt/cprocsp/sbin/amd64/cpconfig -license -set "$TLS_LICENSE_KEY" && \
    rm /tmp/csp_license.txt

# Copy the key containers for cpnginx
COPY cpnginx-keys/cpnginx/ /var/opt/cprocsp/keys/cpnginx/
RUN chown -R cpnginx:cpnginx /var/opt/cprocsp/keys/cpnginx
RUN usermod -s /bin/bash cpnginx || true
ENV HOME=/var/opt/cprocsp/keys/cpnginx
RUN su -s /bin/bash -c "/opt/cprocsp/bin/amd64/csptest -absorb -certs -autoprov" cpnginx


# Import VTB certificate
COPY cert/cprocsp-users-cpnginx-stores-root.sto /var/opt/cprocsp/users/cpnginx/stores/root.sto
RUN touch /var/opt/cprocsp/users/cpnginx/stores/trustedcerts.sto && \
    chown cpnginx:cpnginx /var/opt/cprocsp/users/cpnginx/stores/trustedcerts.sto

# Copy the CA certificate
COPY cert/rootUC-root_ca.cer         /tmp/vtb/root-old.cer
COPY cert/vtbcaD32M9EOKPBU33HPX.cer  /tmp/vtb/root.cer


# Import into the machine certificate store
RUN chown cpnginx:cpnginx /tmp/vtb/*.cer && \
    /opt/cprocsp/bin/amd64/certmgr -inst -store mRoot -file /tmp/vtb/root.cer -all -silent && \
    printf 'o\n' | su -s /bin/bash -c "\
        /opt/cprocsp/bin/amd64/certmgr -inst -store uRoot \
            -file /tmp/vtb/root.cer -all" cpnginx && \
    /opt/cprocsp/bin/amd64/certmgr -inst -store mRoot -file /tmp/vtb/root-old.cer -all -silent && \
    printf 'o\n' | su -s /bin/bash -c "\
        /opt/cprocsp/bin/amd64/certmgr -inst -store uRoot \
            -file /tmp/vtb/root-old.cer -all" cpnginx && \
    rm -rf /tmp/vtb

# Copy the cpnginx configuration file
COPY conf/nginx.conf /etc/opt/cprocsp/cpnginx/cpnginx.conf

EXPOSE 443

CMD ["/opt/cprocsp/sbin/amd64/cpnginx", "-g", "daemon off;"]