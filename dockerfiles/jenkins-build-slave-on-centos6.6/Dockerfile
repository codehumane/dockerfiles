FROM centos:centos6.6
MAINTAINER codehumane@gmail.com



# jenkins user add
RUN echo "root:root" | chpasswd
RUN useradd -u 1000 -m -s /bin/bash jenkins
RUN echo "jenkins:jenkins" | chpasswd



# base library
RUN yum -y install wget tar



# java install
RUN yum update -y && \
       yum install -y wget && \
       wget --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/7u80-b15/jdk-7u80-linux-x64.rpm" && \
       yum localinstall -y jdk-7u80-linux-x64.rpm && \
       rm -f jdk-7u80-linux-x64.rpm && \
       yum clean all

ENV JAVA_HOME /usr/java/default
ENV PATH $JAVA_HOME/bin:$PATH

USER jenkins
RUN echo "export JAVA_HOME=/usr/java/default" >> ~/.bash_profile && \
       source ~/.bash_profile
USER root



# maven install
WORKDIR /usr/src
RUN wget http://apache.tt.co.kr/maven/maven-3/3.3.9/binaries/apache-maven-3.3.9-bin.tar.gz && \
       tar xvzf apache-maven-3.3.9-bin.tar.gz

ENV MAVEN_HOME /usr/src/apache-maven-3.3.9
ENV PATH $MAVEN_HOME/bin:$PATH

USER jenkins
RUN echo "export MAVEN_HOME=/usr/src/apache-maven-3.3.9" >> ~/.bash_profile && \
       source ~/.bash_profile
USER root



# ant install
WORKDIR /usr/src
RUN wget http://apache.tt.co.kr//ant/binaries/apache-ant-1.9.6-bin.tar.gz && \
       tar xvzf apache-ant-1.9.6-bin.tar.gz

ENV ANT_HOME /usr/src/apache-ant-1.9.6
ENV PATH $ANT_HOME/bin:$PATH

USER jenkins
RUN echo "export ANT_HOME=/usr/src/apache-ant-1.9.6" >> ~/.bash_profile && \
       source ~/.bash_profile
USER root



# ssh install
RUN yum install -y openssh-server openssh-clients && \
       sed -ri 's/session    required     pam_loginuid.so/session    optional     pam_loginuid.so/g' /etc/pam.d/sshd && \
       mkdir -p /var/run/sshd && \
       ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N '' && \
       ssh-keygen -t dsa -f /etc/ssh/ssh_host_dsa_key -N ''



# git install
WORKDIR /usr/src
RUN yum -y install curl-devel expat-devel gettext-devel openssl-devel zlib-devel gcc perl-ExtUtils-MakeMaker wget tar && \
       wget https://www.kernel.org/pub/software/scm/git/git-2.7.1.tar.gz && \
       tar xvzf git-2.7.1.tar.gz

WORKDIR git-2.7.1
RUN make prefix=/usr/local/git all && \
       make prefix=/usr/local/git install

ENV GIT_HOME /usr/local/git
ENV PATH $GIT_HOME/bin:$PATH

SER jenkins
RUN echo "export GIT_HOME=/usr/local/git" >> ~/.bash_profile && \
       source ~/.bash_profile
USER root



# git repository access setting
ARG GIT_REPOSITORY_URL
ENV SSH_HOME /home/jenkins/.ssh
RUN mkdir -p $SSH_HOME
WORKDIR $SSH_HOME
RUN chown -R jenkins:jenkins /home/jenkins

USER jenkins
WORKDIR /home/jenkins/.ssh
RUN ssh-keygen -f id_rsa -t rsa -N '' && \
       touch known_hosts && \
       ssh-keyscan $GIT_REPOSITORY_URL >> known_hosts
USER root



# node install
WORKDIR /usr/src
RUN curl --silent --location https://rpm.nodesource.com/setup_4.x | bash - && \
       yum -y install nodejs gcc-c++ make



# postgresql-server install and setting (ref. https://wiki.postgresql.org/wiki/YUM_Installation)
RUN sed -ri 's#\[base\]#[base]\nexclude=postgresql*#g' /etc/yum.repos.d/CentOS-Base.repo && \
       sed -ri 's#\[updates\]#[updates]\nexclude=postgresql*#g' /etc/yum.repos.d/CentOS-Base.repo && \
       yum -y localinstall http://yum.postgresql.org/9.4/redhat/rhel-6-x86_64/pgdg-centos94-9.4-1.noarch.rpm && \
       yum -y install postgresql94-server && \
       echo "postgres:postgres" | chpasswd

RUN service postgresql-9.4 initdb

RUN sed -ri 's/shared_buffers = 32MB/shared_buffers = 1024MB/g' /var/lib/pgsql/9.4/data/postgresql.conf && \
       sed -ri "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" /var/lib/pgsql/9.4/data/postgresql.conf && \
       sed -ri "s#local   all             all                                     peer#local   all             all                                     trust#g" /var/lib/pgsql/9.4/data/pg_hba.conf && \
       sed -ri "s#host    all             all             127.0.0.1/32            ident#host    all             all             127.0.0.1/32            trust#g" /var/lib/pgsql/9.4/data/pg_hba.conf && \
       sed -ri "s#host    all             all             ::1/128                 ident#host    all             all             ::1/128                 trust#g" /var/lib/pgsql/9.4/data/pg_hba.conf && \
       echo "host    all     all     172.16.0.0/12   trust" >> /var/lib/pgsql/9.4/data/pg_hba.conf

ENV PGDATA /var/lib/pgsql/9.4/data
ENV PGSQL_HOME /usr/pgsql-9.4
ENV PATH $PGSQL_HOME/bin:$PATH

USER postgres
RUN echo "export PGSQL_HOME=/usr/pgsql-9.4" >> ~/.bash_profile && \
       echo "export PGDATA=/var/lib/pgsql/9.4/data" >>  ~/.bash_profile && \
       source ~/.bash_profile
USER root



# postgresql user and database create for daouoffice unit test run
ARG POSTGRESQL_USER=jenkins
ARG POSTGRESQL_PASSWORD=jenkins
ARG POSTGRESQL_DATABASE=jenkins
USER postgres
RUN pg_ctl start && \
       sleep 10 && \
       psql --command "CREATE USER $POSTGRESQL_USER WITH SUPERUSER PASSWORD '$POSTGRESQL_PASSWORD';" && \
       createdb -O $POSTGRESQL_USER $POSTGRESQL_DATABASE
USER root



# PATH set to jenkins user profile
RUN echo "export PATH=$PATH" >> ~/.bash_profile && \
       source ~/.bash_profile
USER jenkins
RUN echo "export PATH=$PATH" >> ~/.bash_profile && \
       source ~/.bash_profile
USER postgres
RUN echo "export PATH=$PATH" >> ~/.bash_profile && \
       source ~/.bash_profile
USER root



# supervisord
RUN yum -y install python-setuptools && \
       easy_install supervisor && \
       echo_supervisord_conf > /etc/supervisord.conf

RUN sed -ri 's/nodaemon=false/nodaemon=true/g' /etc/supervisord.conf && \
       echo "[program:sshd]" >> /etc/supervisord.conf && \
       echo "command=/usr/sbin/sshd -D" >> /etc/supervisord.conf && \
       echo "user=root" >> /etc/supervisord.conf && \
       echo "[program:postgresql]" >> /etc/supervisord.conf && \
       echo "command=postgres" >> /etc/supervisord.conf && \
       echo "user=postgres" >> /etc/supervisord.conf



# port and cmd
WORKDIR /
EXPOSE 22
EXPOSE 5432
CMD ["supervisord", "-c", "/etc/supervisord.conf"]
