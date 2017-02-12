#!/bin/bash

set -e

prj_path=$(cd $(dirname $0); pwd -P)
SCRIPTFILE=`basename $0`

. $prj_path/base.sh

nginx_image=nginx:1.11-alpine
configsrv_image=liaohuqiu/configsrv

app=configsrv
app_strorage_dir="/opt/data/$app"

nginx_container=configsrv-nginx
app_container=configsrv

tests_dir="$prj_path/tests"

function _run_app_container() {
    local args="$args --restart always"

    args="$args -v $tests_dir/server-config:/configsrv/config"

    run_cmd "docker run $args -d --name $app_container $configsrv_image"
}

function to_app() {
    run_cmd "docker exec -it $app_container sh"
}

function run_app() {
    _run_app_container "$cmd"
}

function stop_app() {
    stop_container $app_container
}

function stop() {
    stop_app
    stop_nginx
}

function restart() {
    stop
    run
}

function run() {
    run_app
    run_nginx
}

function stop() {
    stop_nginx
    stop_app
}

function run_nginx() {

    local nginx_log_path=$app_strorage_dir/logs/nginx
    local args="--restart=always -p 80:80 -p 443:443"

    # nginx config
    args="$args -v $prj_path/nginx-conf:/etc/nginx"

    # logs
    args="$args -v $nginx_log_path:/var/log/nginx"

    args="$args --link $app_container:configsrv"

    run_cmd "docker run -d $args --name $nginx_container $nginx_image"
}

function to_nginx() {
    run_cmd "docker exec -it $nginx_container sh"
}

function stop_nginx() {
    stop_container $nginx_container
}

function test_render_server_config() {

    local tmp_dir="$tests_dir/tmp"
    ensure_dir "$tmp_dir"

    local developer_name='huqiu'
    local config_key="8douji.vars.site_list.$developer_name"
    local template_file="$tests_dir/templates/manager.config.template"
    local config_file_name="8douji"
    local dst_file="$tmp_dir/manager.config.output"

    local extra_kv_list="name=$developer_name"

    render_server_config $config_key $template_file $config_file_name $dst_file $extra_kv_list
    run_cmd "rm -rf $tmp_dir"
}

function test_render_local_config() {

    local tmp_dir="$tests_dir/tmp"
    ensure_dir "$tmp_dir"

    local config_key='kv_config.vars'
    local template_file="$tests_dir/templates/test-config.template"
    local config_file="$tests_dir/local-config/test-config.yaml"
    local dst_file="$tmp_dir/test-config.output"
    local extra_kv_list="weather=rainy"

    render_local_config $config_key $template_file $config_file $dst_file $extra_kv_list
    run_cmd "rm -rf $tmp_dir"
}

function help() {
        cat <<-EOF
    
    Usage: manager.sh [options]

            Valid options are:

            run
            stop
            restart

            run_nginx
            stop_nginx
            restart_nginx
            to_nginx
            
            run_app                 
            stop_app                
            restart_app
            to_app

            test_render_server_config
            test_render_local_config
            
            -h                      show this help message and exit

EOF
}

action=${1:-help}
ALL_COMMANDS="run stop restart"
ALL_COMMANDS="$ALL_COMMANDS run_nginx stop_nginx restart_nginx to_nginx"
ALL_COMMANDS="$ALL_COMMANDS run_app stop_app restart_app to_app"
ALL_COMMANDS="$ALL_COMMANDS test_render_server_config test_render_local_config"

list_contains ALL_COMMANDS "$action" || action=help
$action "$@"
