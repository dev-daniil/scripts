sudo apt-get install -y shadowsocks-libev
rm /etc/shadowsocks-libev/config.json
echo '{
    "server":"SS_ADDRESS",
    "server_port":SS_PORT,
    "local_port":1080,
    "password":"SS_PASS",
    "timeout":60,
    "method":"aes-128-gcm"
}' > /etc/shadowsocks-libev/config.json

systemctl restart shadowsocks-libev
