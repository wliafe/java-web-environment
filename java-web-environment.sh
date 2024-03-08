#!/bin/bash

# 检查当前用户是否为root
if [[ $EUID -ne 0 ]]; then
    echo "当前用户不是root用户，正在尝试获取sudo权限"
    if ! command -v sudo >/dev/null 2>&1; then
        echo "sudo命令未找到，请确保安装了sudo工具。"
        exit 1
    fi
    sudo_cmd="sudo"
else
    echo "当前用户是root用户"
    sudo_cmd=""
fi

echo "请选择你要安装的软件。"
read -p "是否安装MySQL?(y/n)" MySQL
if [[ $MySQL == "y" ]]; then
  read -p"请输入你的Mysql密码" MySQL_password
fi

read -p "是否安装Redis?(y/n)" Redis
if [[ $Redis == "y" ]]; then
  read -p "请输入你的Redis密码" Redis_password
fi

$sudo_cmd apt update

# 安装Docker
if [[ $MySQL == "y" ]]; then
    if command -v docker &>/dev/null; then
        echo "Docker已安装"
    else
        echo "安装Docker"
        curl -fsSL https://test.docker.com -o test-docker.sh
        $sudo_cmd sh test-docker.sh
        rm test-docker.sh
    fi

    if command -v docker &>/dev/null; then
        echo "Docker安装成功"
    else
        echo "Docker安装失败"
    fi
fi

# 安装MySQL
if [[ $MySQL == "y" ]]; then
    if command -v docker &>/dev/null; then
        if $sudo_cmd docker container inspect env-mysql &>/dev/null; then
            echo "容器 env-mysql 已存在"
        else
            echo "配置并启动MySQL"
            $sudo_cmd docker pull mysql
            $sudo_cmd docker run -p 3306:3306 --name env-mysql -e MYSQL_ROOT_PASSWORD=${MySQL_password} -d mysql
        fi

        if $sudo_cmd docker container inspect env-mysql &>/dev/null; then
            echo "容器 env-mysql 创建成功"
        else
            echo "容器 env-mysql 创建失败"
        fi
    else
        echo "MySQL安装失败"
    fi
fi

# 安装Redis
if [[ $Redis == "y" ]]; then
    if command -v redis-server &>/dev/null; then
        echo "Redis已安装"
    else
        echo "安装Redis"
        $sudo_cmd apt install -y redis
        echo "requirepass ${Redis_password}" >> redis.conf
        $sudo_cmd mv redis.conf /etc/redis/
        service redis-server restart
    fi

    if command -v redis-server &>/dev/null; then
        echo "Redis安装成功"
    else
        echo "Redis安装失败"
    fi
fi

if [[ $MySQL == "y" ]]; then
    echo "MySQL root用户密码为：${MySQL_password}"
fi

if [[ $Redis == "y" ]]; then
    echo "Redis 密码为：${Redis_password}"
fi