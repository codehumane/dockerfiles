#!/bin/bash

function initialize() {

    printf "[pg init] ################\n";
    printf "[pg init] started\n";

    if [ -d "$DATA_DIR/pg_clog" ];
    then
        printf "[pg init] skipped - already initialized\n";
        printf "[pg init] ################\n";
        return 0;
    fi

    printf "[pg init] chown\n";
    # (volume 지정하여 도커 컨테이너 실행시 기존에 없던 디렉토리라면 root 권한으로 디렉토리가 생성되어 컨테이너에게 공유됨)
    chown $USER:$USER -R $DATA_DIR;

    printf "[pg init] initdb\n";
    su - $USER -c "$BIN_DIR/initdb -D $DATA_DIR --lc-collate=$LOCALE --lc-ctype=$LOCALE";

    printf "[pg init] setup\n";
    cp -avr $EDB_DIR/postgresql.conf $DATA_DIR/ \
            && cp -avr $EDB_DIR/pg_hba.conf $DATA_DIR/ \
            && sed -i "s|\$LOGDIR|$LOG_DIR|g" $DATA_DIR/postgresql.conf \
            && sed -i "s|\$DATABASE_PORT|$DB_PORT|g" $DATA_DIR/postgresql.conf \
            && sed -i "s|\$LOGDIR|$LOG_DIR|g" $EDB_DIR/postgresql.conf.md5 \
            && sed -i "s|\$DATABASE_PORT|$DB_PORT|g" $EDB_DIR/postgresql.conf.md5;

    printf "[pg init] completed\n";
    printf "[pg init] ################\n";
};

function run() {

    printf "[pg run] ################\n";
    printf "[pg run] started\n";

    if (ps ax | grep -v grep | grep postgres > /dev/null);
    then
        printf "[pg run] skipped - already started\n";
        return 0;
    fi

    printf "[pg run] pg_ctl start\n";
    # pg_ctl start는 백그라운드 명령 수행이므로, 이어지는 명령어들의 실행을 위해 10초의 대기 시간을 가진다.
    su - $USER -c "$BIN_DIR/pg_ctl -s -l /dev/null -D $DATA_DIR start && sleep 10";

    printf "[pg run] completed\n";
    printf "[pg run] ################\n";
};

function create() {

    printf "[pg create] ################\n";
    printf "[pg create] started\n";

    if (su - $USER -c "$BIN_DIR/psql -p $DB_PORT -lqt | cut -d \| -f 1 | grep -qw $DB_NAME");
    then
        printf "[pg create] skipped - database already exists.\n";
        printf "[pg create] ################\n";
        return 0;
    fi

    printf "[pg create] createdb\n";
    su - $USER -c "$BIN_DIR/createdb -p $DB_PORT $DB_NAME";

    printf "[pg create] completed\n";
    printf "[pg create] ################\n";
};

function stop() {

    printf "[pg stop] ################\n";
    printf "[pg stop] started\n";

    printf "[pg run] pg_ctl stop\n";
    su - $USER -c "$BIN_DIR/pg_ctl stop";

    printf "[pg stop] completed\n";
    printf "[pg stop] ################\n";
};

printf "\n\n\n";
initialize;

printf "\n\n\n";
run;

printf "\n\n\n";
create;

printf "\n\n\n";
stop;

exit 0;