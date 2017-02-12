#!/bin/bash

NC='\033[0m'      # Normal Color
RED='\033[0;31m'  # Error Color
CYAN='\033[0;36m' # Info Color

CONFIG_SERVER='http://config.test.srain.in'

function run_cmd() {
    t=`date`
    echo "$t: $1"
    eval $1
}

function ensure_dir() {
    if [ ! -d $1 ]; then
        run_cmd "mkdir -p $1"
    fi
}

function stop_container() {
    container_name=$1
    cmd="docker ps -a -f name='^/$container_name$' | grep '$container_name' | awk '{print \$1}' | xargs -I {} docker rm -f --volumes {}"
    run_cmd "$cmd"
}

function render_local_config() {
    local config_key=$1
    local template_file=$2
    local config_file=$3
    local out=$4

    shift
    shift
    shift
    shift

    local config_type=yaml
    cmd="curl -s -F 'template_file=@$template_file' -F 'config_file=@$config_file' -F 'config_key=$config_key' -F 'config_type=$config_type'"
    for kv in $*
    do
        cmd="$cmd -F 'kv_list[]=$kv'"
    done
    cmd="$cmd $CONFIG_SERVER/render-config > $out"
    run_cmd "$cmd"
    head $out && echo
}

function render_server_config {
    local config_key=$1
    local template_file=$2
    local config_file_name=$3
    local out=$4

    shift
    shift
    shift
    shift

    cmd="curl -s -F 'template_file=@$template_file' -F 'config_key=$config_key' -F 'config_file_name=$config_file_name'"
    for kv in $*
    do
        cmd="$cmd -F 'kv_list[]=$kv'"
    done
    cmd="$cmd $CONFIG_SERVER/render-config > $out"
    run_cmd "$cmd"
    head $out && echo
}

function list_contains() {
    local var="$1"
    local str="$2"
    local val

    eval "val=\" \${$var} \""
    [ "${val%% $str *}" != "$val" ]
}
