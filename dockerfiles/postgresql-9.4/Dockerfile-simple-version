FROM centos:centos6.6
MAINTAINER codehumane@gmail.com

ARG POSTGRESQL_USER=jenkins
ARG POSTGRESQL_PASSWORD=jenkins
ARG POSTGRESQL_DATABASE=jenkins

RUN echo "root:root" | chpasswd
RUN yum -y install wget tar


# ssh install
RUN yum install -y openssh-server openssh-clients && \
       sed -ri 's/session    required     pam_loginuid.so/session    optional     pam_loginuid.so/g' /etc/pam.d/sshd && \
       mkdir -p /var/run/sshd && \
       ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N '' && \
       ssh-keygen -t dsa -f /etc/ssh/ssh_host_dsa_key -N ''


# postgresql install & init
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
       echo "export PATH=$PATH" >> ~/.bash_profile && \
       source ~/.bash_profile
RUN pg_ctl start && \
       sleep 10 && \
       psql --command "CREATE USER $POSTGRESQL_USER WITH SUPERUSER PASSWORD '$POSTGRESQL_PASSWORD';" && \
       createdb -O $POSTGRESQL_USER $POSTGRESQL_DATABASE
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
WORKDIR $PGSQL_HOME
EXPOSE 22
EXPOSE 5432
CMD ["supervisord", "-c", "/etc/supervisord.conf"]
