####################
# 1. build : docker build -t edb:{version} .; 
# 2. run : docker run -itd -p 5432:5432 --name=edb -v /data/edb/dbdata:/data/edb/dbdata {image name} 
###################
FROM centos:centos6.6
MAINTAINER codehumane


# user
ENV USER mailadm
RUN groupadd -g 500 $USER \
        && useradd -g 500 -u 500 -d /home/$USER $USER \
        && echo "root:thwnekfrehflxkd!" | chpasswd \
        && echo "$USER:$USER" | chpasswd

# environment
ENV DB_USER mailadm
ENV DB_PASSWORD pgadmin80!@
ENV DB_NAME tims
ENV DB_PORT 5432
ENV BASE_DIR /data
ENV EDB_DIR $BASE_DIR/edb
ENV LOG_DIR $BASE_DIR/log/postgresql
ENV INSTALL_DIR $BASE_DIR/install
ENV BIN_DIR $EDB_DIR/9.4AS/bin
ENV DATA_DIR $EDB_DIR/dbdata
ENV LOCALE ko_KR.UTF-8

# console login 허용
RUN echo "session required pam_limits.so" >> /etc/pam.d/login

# locale 설정
RUN localedef -i ko_KR -f UTF-8 $LOCALE \
        && localedef -i ko_KR -f EUC-KR ko_KR.euckr \
        && echo "export LANGUAGE=$LOCALE" >> ~/.bash_profile \
        && echo "export LANG=$LOCALE" >> ~/.bash_profile \
        && echo "export LC_CTYPE=$LOCALE" >> ~/.bash_profile \
        && echo "export LC_ALL=$LOCALE" >> ~/.bash_profile \
        && touch ~/.bash_profile

# postgresql add
RUN mkdir -p $LOG_DIR \
        && mkdir -p $EDB_DIR
ADD edb/. $EDB_DIR/

# setup file add and set
RUN mkdir -p $INSTALL_DIR
ADD setup.sh $INSTALL_DIR/
RUN chmod +x $INSTALL_DIR/setup.sh

# owner
RUN chown -R $USER:$USER $BASE_DIR

# env
ENV PGDATA $DATA_DIR
ENV PATH $BIN_DIR:$PATH
USER $USER
RUN echo "export PGDATA=/data/edb/dbdata" >>  ~/.bash_profile \
        && echo "export PATH=$PATH" >> ~/.bash_profile \
        && source ~/.bash_profile
USER root

# run
USER root
EXPOSE $DB_PORT
VOLUME $DATA_DIR
WORKDIR $EDB_DIR
CMD ["/bin/sh", "-c", "$INSTALL_DIR/setup.sh; su - $USER -c \"$BIN_DIR/edb-postmaster -D $DATA_DIR\";"]
