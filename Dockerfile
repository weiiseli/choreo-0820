FROM debian:stable-slim

# 基础依赖
RUN apt-get update && apt-get install -y \
    curl wget jq tzdata openssl ca-certificates file && \
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    rm -rf /var/lib/apt/lists/*

# 备用版本（获取失败时使用）
ENV FALLBACK_VERSION=v2.5.0

# 下载 Hysteria2 - 自动匹配真实文件名
RUN set -eux; \
    # 获取最新 tag
    HY_VERSION=$(curl -s https://api.github.com/repos/apernet/hysteria/releases/latest \
      | jq -r .tag_name || true); \
    if [ -z "$HY_VERSION" ] || [ "$HY_VERSION" = "null" ]; then \
        echo "⚠️ 获取最新版本失败，使用备用版本 $FALLBACK_VERSION"; \
        HY_VERSION=$FALLBACK_VERSION; \
        API_URL="https://api.github.com/repos/apernet/hysteria/releases/tags/${FALLBACK_VERSION}"; \
    else \
        API_URL="https://api.github.com/repos/apernet/hysteria/releases/latest"; \
    fi; \
    echo "➡️ 使用版本: $HY_VERSION"; \
    # 自动匹配带 amd64 的 tar.gz 资产下载链接
    FILE_URL=$(curl -s "$API_URL" \
      | jq -r '.assets[] | select(.name | test("linux-amd64.*\\.tar\\.gz$")) | .browser_download_url'); \
    if [ -z "$FILE_URL" ] || [ "$FILE_URL" = "null" ]; then \
        echo "❌ 未找到匹配的 amd64 tar.gz 文件"; \
        exit 1; \
    fi; \
    echo "📥 下载: $FILE_URL"; \
    wget -O /tmp/hysteria.tar.gz "$FILE_URL"; \
    file /tmp/hysteria.tar.gz; \
    tar -tzf /tmp/hysteria.tar.gz >/dev/null; \
    tar -xzf /tmp/hysteria.tar.gz -C /usr/local/bin; \
    chmod +x /usr/local/bin/hysteria; \
    rm /tmp/hysteria.tar.gz

# 创建非 root 用户
RUN useradd -u 10014 -m hysteria && \
    mkdir -p /etc/hysteria && \
    chown -R hysteria:hysteria /etc/hysteria

# 拷贝配置文件和启动脚本
COPY --chown=hysteria:hysteria config.yaml /etc/hysteria/config.yaml
COPY --chown=hysteria:hysteria entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER 10014

EXPOSE 443/udp
ENTRYPOINT ["/entrypoint.sh"]
