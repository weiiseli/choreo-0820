FROM debian:stable-slim

# 安装依赖（包含 jq / file / unzip 等）
RUN apt-get update && apt-get install -y \
    curl wget jq tzdata openssl ca-certificates file unzip && \
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    rm -rf /var/lib/apt/lists/*

# 备用版本（拉最新失败时使用）
ENV FALLBACK_VERSION=v2.5.0

# 下载 Hysteria2：动态匹配文件名 + 双格式支持
RUN set -eux; \
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
    FILE_URL=$(curl -s "$API_URL" \
      | jq -r '.assets[] | select(.name | test("amd64") and (.name|endswith(".tar.gz") or .name|endswith(".zip"))) | .browser_download_url' \
      | head -n 1); \
    if [ -z "$FILE_URL" ] || [ "$FILE_URL" = "null" ]; then \
        echo "❌ 未找到匹配的 amd64 压缩文件"; \
        exit 1; \
    fi; \
    echo "📥 下载: $FILE_URL"; \
    wget -O /tmp/hysteria.pkg "$FILE_URL"; \
    file /tmp/hysteria.pkg; \
    if echo "$FILE_URL" | grep -q '\.zip$'; then \
        unzip /tmp/hysteria.pkg -d /usr/local/bin; \
    else \
        tar -tzf /tmp/hysteria.pkg >/dev/null; \
        tar -xzf /tmp/hysteria.pkg -C /usr/local/bin; \
    fi; \
    chmod +x /usr/local/bin/hysteria || true; \
    rm /tmp/hysteria.pkg

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
