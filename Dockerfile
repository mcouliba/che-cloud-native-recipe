# Copyright (c) 2012-2018 Red Hat, Inc.
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
#
# Contributors: Madou Coulibaly mcouliba@redhat.com

FROM registry.access.redhat.com/codeready-workspaces-beta/stacks-java:latest

EXPOSE 4403 8080 8000 9876 22
LABEL che:server:8080:ref=tomcat8 che:server:8080:protocol=http che:server:8000:ref=tomcat8-debug che:server:8000:protocol=http che:server:9876:ref=codeserver che:server:9876:protocol=http

ARG OC_VERSION=3.11.43
ARG ODO_VERSION=v0.0.18

# Install nss_wrapper and tools
RUN sudo yum update -y && \
    sudo yum install -y cmake gettext make gcc
    
RUN cd && \
    git clone git://git.samba.org/nss_wrapper.git && \
    cd nss_wrapper && \
    mkdir obj && cd obj && \
    cmake -DCMAKE_INSTALL_PREFIX=/usr/local -DLIB_SUFFIX=64 .. && \
    make && sudo make install && \
    cd && rm -rf ./nss_wrapper && \
    sudo yum remove -y cmake make gcc && \
    sudo yum clean all && \
    sudo rm -rf /tmp/* /var/cache/yum

# Install jq
RUN sudo yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm && \
    sudo yum install -y jq

# Install nodejs for ls agents and OpenShift CLI
RUN sudo yum update -y && \
    curl -sL https://rpm.nodesource.com/setup_8.x | sudo -E bash - && \
    sudo yum install -y bzip2 tar curl wget nodejs && \
    sudo wget -qO- "https://mirror.openshift.com/pub/openshift-v3/clients/${OC_VERSION}/linux/oc.tar.gz" | sudo tar xvz -C /usr/local/bin && \
    sudo yum remove -y wget && \
    sudo yum clean all && \
    sudo rm -rf /tmp/* /var/cache/yum

# Install Ansible
RUN sudo yum install -y ansible

# Install Siege
RUN sudo yum -y install epel-release && \
    sudo yum -y install siege

# Install Yarn
RUN sudo yum update -y && \
    curl --silent --location https://dl.yarnpkg.com/rpm/yarn.repo | sudo tee /etc/yum.repos.d/yarn.repo
RUN sudo yum install -y yarn

# Install Openshift DO (ODO)
RUN sudo curl -L https://github.com/redhat-developer/odo/releases/download/${ODO_VERSION}/odo-linux-amd64 -o /usr/local/bin/odo && \
    sudo chmod +x /usr/local/bin/odo

# The following lines are needed to set the correct locale after `yum update`
# c.f. https://github.com/CentOS/sig-cloud-instance-images/issues/71
RUN sudo localedef -i en_US -f UTF-8 C.UTF-8
ENV LANG="C.UTF-8"

# Maven settings
COPY ./settings.xml $HOME/.m2/settings.xml

# Give write access to /projects 
RUN sudo mkdir -p /projects \
  && sudo chgrp -R 0 /projects \
  && sudo chmod -R g+rwX /projects
  
RUN sed -i '/MAVEN_OPTS/d' ~/.bashrc && \
    echo "export MAVEN_OPTS=\"\$MAVEN_OPTS \$JAVA_OPTS\"" >> ~/.bashrc

# Overwride entrypoint
COPY ["entrypoint.sh","/home/user/entrypoint.sh"]

ENTRYPOINT ["/home/user/entrypoint.sh"]
CMD tail -f /dev/null