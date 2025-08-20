FROM debian:stable-slim

# 设置时区和基础依赖
RUN apt-get update && apt-get install -y \
    curl wget unzip tzdata && \
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    rm -rf /var/lib/apt/lists/*

# 下载 Hysteria2 最新版本
RUN HY_VERSION=$(curl -s https://api.github.com/repos/apernet/hysteria/releases/latest | grep tag_name | cut -d '"' -f 4) && \
    wget -O /tmp/hysteria.tar.gz https://github.com/apernet/hysteria/releases/download/${HY_VERSION}/hysteria-linux-amd64.tar.gz && \
    tar -xzf /tmp/hysteria.tar.gz -C /usr/local/bin && \
    chmod +x /usr/local/bin/hysteria

# 拷贝配置文件和启动脚本
COPY config.yaml /etc/hysteria/config.yaml
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# 暴露 UDP 端口（Choreo 需支持 UDP）
EXPOSE 443/udp

ENTRYPOINT ["/entrypoint.sh"]
