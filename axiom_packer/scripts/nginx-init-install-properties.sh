#!/bin/bash
# Initialize install.properties with desired values.
# Usage: nginx-init-install-properties.sh <folder_containing_install_properties>
#
sed -i -e 's/nginx.dir=.*/nginx.dir=\/etc\/nginx/g' $1/install.properties
sed -i -e 's/log.dir=.*/log.dir=\/var\/log\/nginx/g' $1/install.properties
sed -i -e 's/https.port=.*/https.port=443; client_max_body_size 0\nhttps.rest.port=4443; client_max_body_size 0/g' $1/install.properties
sed -i -e 's/tomcat.server.0=.*/tomcat.server.0=tc-elb-internal:443/g' $1/install.properties
sed -i -e 's/axiom.server=.*/axiom.server=cv-elb-internal:8089/g' $1/install.properties
sed -i -e 's/rest.available=.*/rest.available=true/g' $1/install.properties