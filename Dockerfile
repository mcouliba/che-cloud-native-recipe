# Copyright (c) 2012-2018 Red Hat, Inc.
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
#
# Contributors: Madou Coulibaly mcouliba@redhat.com

FROM registry.access.redhat.com/codeready-workspaces/stacks-java-rhel8

ARG OC_VERSION=4.2
ARG ODO_VERSION=v1.0.0-beta6
ARG KUBECTL_VERSION=v1.14.6
ARG SQUASHCTL_VERSION=v0.5.12
ARG GO_VERSION=1.12.4

# ENV PATH=${JAVA_HOME}/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# # Maven 3.5.x
# ENV MVN_HOME=/opt/rh/rh-maven35/root/usr/share/maven
# ENV PATH=${MVN_HOME}/bin:${PATH}
# RUN sudo yum install -y centos-release-scl rh-maven35 && \
#     scl enable rh-maven35 bash
    
# Install Development Tools
RUN sudo yum group install -y "Development Tools"

# Install EPEL
RUN sudo yum update -y && \
    sudo yum install -y epel-release

# Install nss_wrapper and tools
RUN sudo yum install -y cmake3 gettext make gcc && \
    cd /home/user/ && \
    git clone git://git.samba.org/nss_wrapper.git && \
    cd nss_wrapper && \
    mkdir obj && cd obj && \
    cmake3 -DCMAKE_INSTALL_PREFIX=/usr/local -DLIB_SUFFIX=64 .. && \
    make && sudo make install && \
    cd /home/user && rm -rf ./nss_wrapper && \
    sudo yum remove -y cmake3 make gcc && \
    sudo yum clean all && \
    sudo rm -rf /tmp/* /var/cache/yum

# Install jq
RUN sudo yum install -y jq

# Install tools
RUN sudo yum update -y && \
    sudo yum install -y bzip2 tar curl wget

# Install oc
RUN sudo wget -qO- "https://mirror.openshift.com/pub/openshift-v4/clients/oc/${OC_VERSION}/linux/oc.tar.gz" | sudo tar xvz -C /usr/local/bin && \
    oc version

# Install nodejs for ls agents
RUN curl -sL https://rpm.nodesource.com/setup_8.x | sudo -E bash - && \
    sudo yum install -y nodejs

# Install Ansible
RUN sudo yum install -y ansible

# Install Siege
RUN sudo yum install -y epel-release && \
    sudo yum install -y siege

# Install Openshift DO (ODO)
RUN sudo curl -L https://github.com/openshift/odo/releases/download/${ODO_VERSION}/odo-linux-amd64 -o /usr/local/bin/odo && \
    sudo chmod +x /usr/local/bin/odo

# Install squashctl (kubectl)
RUN sudo wget -qO /usr/local/bin/squashctl https://github.com/solo-io/squash/releases/download/${SQUASHCTL_VERSION}/squashctl-linux && \
    sudo chmod +x /usr/local/bin/squashctl
ADD https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl /usr/local/bin/kubectl
RUN sudo chmod +x /usr/local/bin/kubectl && \
    kubectl version --client

# Install Golang
ENV GOPATH /go
ENV GOROOT /usr/local/go
ENV PATH $GOPATH/bin:$GOROOT/bin:$PATH
RUN sudo wget -qO- https://dl.google.com/go/go${GO_VERSION}.linux-amd64.tar.gz | sudo tar xvz -C /usr/local && \
    sudo mkdir -p $GOPATH/{bin,src,pkg} && sudo chmod -R 777 "$GOPATH" && \
    go version

# Cleanup 
RUN sudo yum clean all && \
    sudo rm -rf /tmp/* /var/cache/yum
    
# The following lines are needed to set the correct locale after `yum update`
# c.f. https://github.com/CentOS/sig-cloud-instance-images/issues/71
RUN sudo localedef -i en_US -f UTF-8 C.UTF-8
ENV LANG="C.UTF-8"

# Maven settings
COPY ./settings.xml $HOME/.m2/settings.xml

# # Give write access to /home/user for 
# # users with an arbitrary UID 
# RUN sudo chgrp -R 0 /home/user \
#   && sudo chmod -R g+rwX /home/user \
#   && sudo chgrp -R 0 /etc/passwd \
#   && sudo chmod -R g+rwX /etc/passwd \
#   && sudo chgrp -R 0 /etc/group \
#   && sudo chmod -R g+rwX /etc/group \
#   && sudo mkdir -p /projects \
#   && sudo chgrp -R 0 /projects \
#   && sudo chmod -R g+rwX /projects
  
# # Generate passwd.template
# RUN cat /etc/passwd | \
#     sed s#user:x.*#user:x:\${USER_ID}:\${GROUP_ID}::\${HOME}:/bin/bash#g \
#     > /home/user/passwd.template

# # Generate group.template
# RUN cat /etc/group | \
#     sed s#root:x:0:#root:x:0:0,\${USER_ID}:#g \
#     > /home/user/group.template

RUN sed -i '/MAVEN_OPTS/d' /home/user/.bashrc && \
    echo "export MAVEN_OPTS=\"\$MAVEN_OPTS \$JAVA_OPTS\"" >> /home/user/.bashrc

# ENV HOME /home/user

# Overwride entrypoint
COPY ["entrypoint.sh","/home/user/entrypoint.sh"]

ENTRYPOINT ["/home/user/entrypoint.sh"]
CMD tail -f /dev/null
