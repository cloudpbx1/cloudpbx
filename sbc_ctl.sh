#!/usr/bin/env bash
set -e

create_help() {
    echo
    echo  "\t command run options:"
    echo  "\t     -p <path>: required, sbc data path"
    echo  "\t     -i <docker image>: required, sbc docker image"
    echo
}

command_help() {
    echo
    echo  "\t use command:"
    echo  "\t     run"
    echo  "\t     status"
    echo  "\t     restart"
    echo  "\t     start"
    echo  "\t     stop"
    echo  "\t     rm"
    echo 
}

if [ -z $1 ];
then 
    command_help
    exit
fi

create() {
    echo ""
    echo "==> try to create sbc service <=="
    echo ""

    # remove command firstly
    shift

    data_path=
    sbc_img=
    # parse parameters
    while getopts p:i: option
    do 
        case "${option}" in
            p)
                data_path=${OPTARG}
                ;;
            i)
                sbc_img=${OPTARG}
                ;;
        esac
    done

    # check parameters is exist
    if [ -z "$data_path" ]; then
        echo  "\t data path(-p) not specified"
        create_help
        exit
    fi
    if [ -z "$sbc_img" ]; then
        echo  "\t sbc docker image(-i) not specified"
        create_help
        exit
    fi

    echo  "\t use datapath $data_path, img $sbc_img"
    echo ""

#    docker pull $sbc_img

    # check datapath whether exist
    if [ ! -d "$data_path/sbc" ]; then
        echo  "\t datapath $data_path/sbc not exist, try to reate it"
        mkdir -p $data_path/sbc
        echo  "\t created"
        echo ""
    fi

    # change directory mode
    chmod 755 $data_path

    # write configure file
    cat << EOF > .configure_sbc
SBC_DATA_PATH=$data_path
SBC_IMG=$sbc_img
EOF

    # run sbc service
    docker run -d \
        --name cloudpbx.sbc \
        --restart=always \
        --cap-add=SYS_PTRACE \
        --network=host \
        -v $data_path/sbc:/var/lib/cloudpbx/sbc \
        -v /etc/localtime:/etc/localtime:ro  \
        $sbc_img supervisord -c /etc/supervisor/supervisord.conf

    echo ""
    echo  "\t done"
    echo ""
}


status() {
    # remove command firstly
    shift

    service_name=

    # parse parameters
    while getopts s: option
    do 
        case "${option}" in
            s)
                service_name=${OPTARG}
                ;;
        esac
    done

    # check parameters is exist
    if [ -z "$service_name" ]; then
        echo ""
        echo "status all services"
        echo ""
        docker exec cloudpbx.sbc supervisorctl status 
    else
        echo ""
        echo "status service $service_name"
        echo ""
        docker exec cloudpbx.sbc supervisorctl status $service_name
    fi
}

restart() {
    # remove command firstly
    shift

    service_name=

    # parse parameters
    while getopts s: option
    do 
        case "${option}" in
            s)
                service_name=${OPTARG}
                ;;
        esac
    done

    # check parameters is exist
    if [ -z "$service_name" ]; then
        echo ""
        echo "restart all services"
        echo ""
        docker restart -t 300 cloudpbx.sbc
        exit
    fi

    echo ""
    echo "restart service $service_name"
    echo ""
    docker exec cloudpbx.sbc supervisorctl restart $service_name
}

start() {
    # remove command firstly
    shift

    service_name=

    # parse parameters
    while getopts s: option
    do 
        case "${option}" in
            s)
                service_name=${OPTARG}
                ;;
        esac
    done

    # check parameters is exist
    if [ -z "$service_name" ]; then
        echo ""
        echo "start all services"
        echo ""
        docker start cloudpbx.sbc
    else
        echo ""
        echo "start service $service_name"
        echo ""
        docker exec cloudpbx.sbc supervisorctl start $service_name
    fi
}

stop() {
    # remove command firstly
    shift

    service_name=

    # parse parameters
    while getopts s: option
    do 
        case "${option}" in
            s)
                service_name=${OPTARG}
                ;;
        esac
    done

    # check parameters is exist
    if [ -z "$service_name" ]; then
        echo ""
        echo "stop all services"
        echo ""
        docker stop -t 300 cloudpbx.sbc
        exit
    fi
    echo ""
    echo "stop service $service_name"
    echo ""
    docker exec cloudpbx.sbc supervisorctl stop $service_name
}

rm() {
    # remove command firstly
    shift

    docker stop -t 300 cloudpbx.sbc
    docker rm -f cloudpbx.sbc
}

case $1 in
run)
    create $@
    ;;

restart)
    restart $@
    ;;

status)
    status $@
    ;;

stop)
    stop $@
    ;;

start)
    start $@
    ;;

rm)
    rm $@
    ;;

*)
    command_help
    ;;
esac

