#!/bin/sh
# 如果没有证书则生成自签名证书
if [ ! -f /etc/hysteria/cert.pem ]; then
    openssl req -x509 -nodes -newkey rsa:2048 \
        -keyout /etc/hysteria/key.pem \
        -out /etc/hysteria/cert.pem \
        -days 3650 \
        -subj "/CN=example.com"
fi

# 启动 Hysteria2
exec hysteria server -c /etc/hysteria/config.yaml
