
######################################################################################################
# Mirror Jenkins's Dockerfile (CodeCommit:jenkins/docker-slave/Dockerfile) to install required tools #
######################################################################################################
FROM centos:latest

ENV HOME /var/jenkins

# install JDK
#RUN yum -y install java-1.8.0-openjdk java-1.8.0-openjdk-devel

RUN yum -y install git which

RUN rpm -U --replacepkgs https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
RUN yum -y install curl git which ansible libffi-devl openssl-devel gcc polkit python-pip jq wget fabric unzip
RUN pip install --upgrade setuptools
RUN pip install boto3 jinja2 click==6.7 awscli pytest requests ansi2html

RUN wget https://github.com/barnybug/cli53/releases/download/0.8.12/cli53-linux-amd64 -O /usr/local/bin/cli53

# install terraform (fixed version)
ENV TF_VERSION=0.11.10
RUN cd /tmp && wget https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_linux_amd64.zip && unzip terraform_${TF_VERSION}_linux_amd64.zip -d /usr/local/bin

# install terraform (latest version)
#RUN curl -o terraform.zip `curl https://releases.hashicorp.com/index.json | jq '{terraform}' | grep -v "alpha" | grep -v "beta"|  egrep "linux.*amd64" | sort --version-sort -r | head -1 | awk -F[\"] '{print $4}'`
#RUN unzip terraform.zip -d /usr/local/bin
RUN chmod +x /usr/local/bin/terraform

# install packer, latest packer doesn't work properly, use 1.2.5
RUN cd /tmp && wget https://releases.hashicorp.com/packer/1.2.5/packer_1.2.5_linux_amd64.zip && unzip packer_1.2.5_linux_amd64.zip -d /usr/local/bin

#RUN curl -o packer.zip `curl https://releases.hashicorp.com/index.json | jq '{packer}' | grep -v "alpha" | grep -v "beta"| egrep "linux.*amd64" | sort --version-sort -r | head -1 | awk -F[\"] '{print $4}'`
#RUN unzip packer.zip -d /usr/local/bin
#RUN chmod +x /usr/local/bin/packer

RUN useradd -d ${HOME} -ms /bin/bash -u 1001 jenkins

#######################################################################################
# From this point onwards, we use different commands compared to Jenkins's Dockerfile #
#######################################################################################
RUN chmod 755 ${HOME}
RUN chown jenkins: ${HOME}

USER jenkins

ENV AGENT_WORKDIR=${HOME}/agent
RUN mkdir ${HOME}/.jenkins && mkdir -p ${AGENT_WORKDIR}

VOLUME ${HOME}/.jenkins
VOLUME ${AGENT_WORKDIR}
WORKDIR ${AGENT_WORKDIR}

