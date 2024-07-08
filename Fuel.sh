#!/bin/bash

# 检查是否以root用户运行脚本
if [ "$(id -u)" != "0" ]; then
    echo "此脚本需要以root用户权限运行。"
    echo "请尝试使用 'sudo -i' 命令切换到root用户，然后再次运行此脚本。"
    exit 1
fi

# 脚本保存路径
SCRIPT_PATH="$HOME/Fuel.sh"

function install_node() {
    # 安装基本组件
    sudo apt update
    sudo apt install -y screen git jq

    # 安装Rust
    echo "正在安装Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source $HOME/.cargo/env

    # 安装Fuel服务
    echo "正在安装Fuel服务..."
    yes y | curl https://install.fuel.network | sh
    sleep 5
    source $HOME/.bashrc

    # 生成P2P密钥
    source $HOME/.bashrc
    export PATH=$HOME/.fuelup/bin:$PATH
    
    # 创建文件夹路径，确保中间路径存在
    DIR_PATH="$HOME/~/"
    mkdir -p "$DIR_PATH"

    read -p 'Enter your secret: ' SECRET
    echo "请保存好你的钱包私钥：${SECRET}"

    # 创建文件路径
    FILE_PATH="$DIR_PATH/key.txt"

    # 将 SECRET 写入文件中
    echo $SECRET > $FILE_PATH

    # 克隆chain information
    if [ -d "chain-configuration" ]; then
        echo "chain-configuration 目录已存在，跳过克隆。"
    else
        git clone https://github.com/FuelLabs/chain-configuration.git
    fi

    # 用户输入节点名称和RPC地址
    read -p "请输入您的ETH Sepolia RPC地址: " RPC

    # 开始配置并运行节点
    echo "开始配置并启动您的fuel节点..."

    screen -dmS Fuel bash -c "source /root/.bashrc; fuel-core run \
    --service-name=fuel-sepolia-testnet-node \
    --keypair ${SECRET} \
    --relayer ${RPC} \
    --ip=0.0.0.0 --port=4000 --peering-port=30333 \
    --db-path=~/.fuel-sepolia-testnet \
    --snapshot ~/chain-configuration/ignition \
    --utxo-validation --poa-instant false --enable-p2p \
    --reserved-nodes /dns4/p2p-testnet.fuel.network/tcp/30333/p2p/16Uiu2HAmDxoChB7AheKNvCVpD4PHJwuDGn8rifMBEHmEynGHvHrf \
    --sync-header-batch-size 100 \
    --enable-relayer \
    --relayer-v2-listening-contracts=0x01855B78C1f8868DE70e84507ec735983bf262dA \
    --relayer-da-deploy-height=5827607 \
    --relayer-log-page-size=500 \
    --sync-block-stream-buffer-size 30"

    echo "节点配置完成并尝试启动。请使用screen -r Fuel 以确认节点状态。"
}

function check_service_status() {
    screen -r Fuel
}

function backup() {
    mkdir -p $HOME/fuel_key
    cp $HOME/~/key.txt $HOME/fuel_key/
}

function uninstall() {
   rm -rf /root/~
   rm -rf /root/.fuelup
   rm -rf /root/.forc
   rm -rf /root/chain-configuration
}

# 主菜单
function main_menu() {
    clear
    echo "==============================自用脚本=================================="
    echo "请选择要执行的操作:"
    echo "1. 安装节点"
    echo "2. 查看节点日志"
    echo "3. 备份钱包数据"
    echo "4. 卸载节点"
    
    read -p "请输入选项（1-4）: " OPTION

    case $OPTION in
    1) install_node ;;
    2) check_service_status ;;  
    3) backup ;;
    4) uninstall ;;
    *) echo "无效选项。" ;;
    esac
}

# 显示主菜单
main_menu
