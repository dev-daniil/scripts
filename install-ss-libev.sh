sudo apt-get install -y shadowsocks-libev
rm /etc/shadowsocks-libev/config.json
echo '{
    "server":"185.170.212.166",
    "server_port":SS_PORT,
    "local_port":1080,
    "password":"SS_PASS",
    "timeout":60,
    "method":"aes-256-gcm"
}' > /etc/shadowsocks-libev/config.json

systemctl restart shadowsocks-libev
