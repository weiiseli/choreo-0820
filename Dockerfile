FROM debian:stable-slim

# 设置时区和基础依赖
RUN apt-get update && apt-get install -y \
    curl wget unzip tzdata openssl && \
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    rm -rf /var/lib/apt/lists/*

# 下载 Hysteria2 最新版本
RUN HY_VERSION=$(curl -s https://api.github.com/repos/apernet/hysteria/releases/latest | grep tag_name | cut -d '"' -f 4) && \
    wget -O /tmp/hysteria.tar.gz https://github.com/apernet/hysteria/releases/download/${HY_VERSION}/hysteria-linux-amd64.tar.gz && \
    tar -xzf /tmp/hysteria.tar.gz -C /usr/local/bin && \
    chmod +x /usr/local/bin/hysteria

# 创建非 root 用户和工作目录
RUN useradd -u 10014 -m hysteria && \
    mkdir -p /etc/hysteria && \
    chown -R hysteria:hysteria /etc/hysteria

# 拷贝配置文件和启动脚本
COPY --chown=hysteria:hysteria config.yaml /etc/hysteria/config.yaml
COPY --chown=hysteria:hysteria entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# 切换到非 root 用户
USER 10014

# 暴露 UDP 端口
EXPOSE 443/udp

ENTRYPOINT ["/entrypoint.sh"]
