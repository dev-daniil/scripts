sudo apt update
sudo apt install -y openvpn
sudo apt-get -y install openvpn-auth-radius
mkdir ~/easy-rsa
wget https://github.com/OpenVPN/easy-rsa/releases/download/v3.1.2/EasyRSA-3.1.2.tgz
tar zxvf EasyRSA-3.1.2.tgz
echo "set_var EASYRSA_REQ_COUNTRY    "US"
      set_var EASYRSA_REQ_PROVINCE   "California"
      set_var EASYRSA_REQ_CITY       "San Francisco"
      set_var EASYRSA_REQ_ORG        "Copyleft Certificate Co"
      set_var EASYRSA_REQ_EMAIL      "me@example.net"
      set_var EASYRSA_REQ_OU         "My Organizational Unit"" > ~/EasyRSA-3.1.2/vars
cd ~/EasyRSA-3.1.2 && rm -rf ./pki && ./easyrsa --batch init-pki && ./easyrsa --batch build-ca nopass && ./easyrsa --batch --days=3650 build-server-full server nopass && ./easyrsa --batch --days=3650 build-client-full client nopass && ./easyrsa --days=3650 --batch gen-crl
rm -rf /etc/openvpn/server
mkdir /etc/openvpn/server
cp ~/EasyRSA-3.1.2/pki/ca.crt /etc/openvpn/server/ca.crt
cp ~/EasyRSA-3.1.2/pki/crl.pem /etc/openvpn/server/crl.pem
cp ~/EasyRSA-3.1.2/pki/issued/server.crt /etc/openvpn/server/server.crt
cp ~/EasyRSA-3.1.2/pki/issued/client.crt /etc/openvpn/server/client.crt
cp ~/EasyRSA-3.1.2/pki/private/ca.key /etc/openvpn/server/ca.key
cp ~/EasyRSA-3.1.2/pki/private/server.key /etc/openvpn/server/server.key
cp ~/EasyRSA-3.1.2/pki/private/client.key /etc/openvpn/server/client.key
rm ~/EasyRSA-3.1.2.tgz
echo "
            NAS-Identifier=OpenVpn

            Service-Type=5

            Framed-Protocol=10

            NAS-Port-Type=5

            NAS-IP-Address=SERVER_ADDRESS

            OpenVPNConfig=/etc/openvpn/server/server.conf

            subnet=255.255.255.0

            overwriteccfiles=true
    server
    {
            acctport=1813
            authport=1812
            name=SERVER_RADIUS_ADDRESS
            retry=1
            wait=1
            sharedsecret=SERVER_RADIUS_PASSWORD
    }
    " > /etc/openvpn/radiusplugin.cnf
openvpn --genkey --secret /etc/openvpn/server/tc.key
echo "-----BEGIN DH PARAMETERS-----
MIIBCAKCAQEA//////////+t+FRYortKmq/cViAnPTzx2LnFg84tNpWp4TZBFGQz
+8yTnc4kmz75fS/jY2MMddj2gbICrsRhetPfHtXV/WVhJDP1H18GbtCFY2VVPe0a
87VXE15/V8k1mE8McODmi3fipona8+/och3xWKE2rec1MKzKT0g6eXq8CrGCsyT7
YdEIqUuyyOP7uWrat2DX9GgdT0Kj3jlN9K5W7edjcrsZCwenyO4KbXCeAvzhzffi
7MA0BM0oNC9hkXL+nOmFg/+OTxIy7vKBg8P+OxtMb61zO7X8vC7CIAXFjvGDfRaD
ssbzSibBsu/6iGtCOGEoXJf//////////wIBAg==
-----END DH PARAMETERS-----" > /etc/openvpn/server/dh.pem
echo "local SERVER_ADDRESS
port 1194
proto udp
dev tun
ca ca.crt
log-append /var/log/openvpn.log
cert server.crt
key server.key
dh dh.pem
auth SHA512
tls-crypt tc.key
topology subnet
server 10.8.0.0 255.255.255.0
push "redirect-gateway def1 bypass-dhcp"
ifconfig-pool-persist ipp.txt
plugin /usr/lib/openvpn/radiusplugin.so /etc/openvpn/radiusplugin.cnf
push "dhcp-option DNS 8.8.8.8"
push "dhcp-option DNS 8.8.4.4"
push "block-outside-dns"
keepalive 10 120
cipher AES-256-CBC
user nobody
group nogroup
persist-key
persist-tun
verb 3
crl-verify crl.pem
explicit-exit-notify
topology subnet" > /etc/openvpn/server/server.conf
{
echo "client
dev tun
proto udp
remote SERVER_ADDRESS 1194
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
auth SHA512
cipher AES-256-CBC
ignore-unknown-option block-outside-dns
verb 3"
echo "auth-user-pass"
echo "<ca>"
cat /etc/openvpn/server/ca.crt
echo "</ca>"
echo "<cert>"
sed -ne '/BEGIN CERTIFICATE/,$ p' /etc/openvpn/server/client.crt
echo "</cert>"
echo "<key>"
cat /etc/openvpn/server/client.key
echo "</key>"
echo "<tls-crypt>"
sed -ne '/BEGIN OpenVPN Static key/,$ p' /etc/openvpn/server/tc.key
echo "</tls-crypt>"
} > ~/client.ovpn
systemctl stop openvpn-server@server
systemctl disable openvpn-server@server
systemctl enable openvpn-server@server
systemctl start openvpn-server@server

