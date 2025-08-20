FROM debian:stable-slim

# 基础依赖
RUN apt-get update && apt-get install -y \
    curl wget unzip tzdata openssl && \
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    rm -rf /var/lib/apt/lists/*

# 固定的安全版本（防限流时使用）
ENV FALLBACK_VERSION=v2.5.0

# 下载 Hysteria2：优先拉最新，失败则退回固定版本
RUN set -eux; \
    HY_VERSION=$(curl -s https://api.github.com/repos/apernet/hysteria/releases/latest \
        | grep '"tag_name":' | head -n 1 | cut -d '"' -f 4 || true); \
    if [ -z "$HY_VERSION" ]; then \
        echo "⚠️ 未能获取最新版本，使用备用版本 $FALLBACK_VERSION"; \
        HY_VERSION=$FALLBACK_VERSION; \
    fi; \
    echo "➡️ 使用版本: $HY_VERSION"; \
    wget -O /tmp/hysteria.tar.gz \
        "https://github.com/apernet/hysteria/releases/download/${HY_VERSION}/hysteria-linux-amd64.tar.gz"; \
    tar -xzf /tmp/hysteria.tar.gz -C /usr/local/bin; \
    chmod +x /usr/local/bin/hysteria; \
    rm /tmp/hysteria.tar.gz

# 创建非 root 用户
RUN useradd -u 10014 -m hysteria && \
    mkdir -p /etc/hysteria && \
    chown -R hysteria:hysteria /etc/hysteria

# 拷贝文件并赋权
COPY --chown=hysteria:hysteria config.yaml /etc/hysteria/config.yaml
COPY --chown=hysteria:hysteria entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER 10014

EXPOSE 443/udp
ENTRYPOINT ["/entrypoint.sh"]
