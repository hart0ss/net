#!bin/bash

echo "_________________Имя машины______________________"
read -p "Введите имя (например isp.au-team.irpo): " name

if [[ -n $name ]]; then
	hostnamectl set-hostname $name
if

echo "_______________________Enp0s8(HQ-RTR)__________________________"
read -p "Введите ip для enp0s8 (например 172.16.4.1): " ip_enp0s8
if [[ -n $ip_enp0s8 ]]; then
	read -p "Ведите количество машин: " mask_enp0s8
	mask_enp0s8=$((echo "sqrt($mask_enp0s8)" | bc))
	ip_s8=$ip_enp0s8/$mask_enp0s8
	
	cat >> /etc/NetworkManager/system-connections/enp0s8.nmconnection << EOF
[connection]
id=enp0s8
uuid=$(uuidgen)
type=ethernet
autoconnect-priority=-999
interface-name=enp0s8
timestamp=$(date +%s)

[ethernet]

[ipv4]
address1=$ip_s8
method=manual

[ipv6]
addr-gen-mode=eu164
method=disabled

[proxy]
EOF

	chmod 600 /etc/NetworkManager/system-connections/enp0s8.nmconnection
fi

echo ""
echo "__________________________Enp0s9(BR-RTR)_____________________________"
read -p "Введите ip для enp0s9 (например 172.16.5.1): " ip_enp0s9
if [[ -n ip_enp0s9 ]]; then
	read -p "Введите количество машин: " mask_enp0s9
	mask_enp0s9=$((echo "sqrt($mask_enp0s9)" | bc))
	ip_s9=$ip_enp0s9/mask_enp0s9

	cat >> /etc/NetworkManager/system-connections/enp0s9.nmconnection << EOF
[connection]
id=enp0s9
uuid=$(uuidgen)
type=ethernet
autoconnect-priority=-999
interface-name=enp0s9
timestamp=$(date +%s)

[ethernet]

[ipv4]
address1=$ip_s9
method=manual

[ipv6]
addr-gen-mode=eu164
method=disabled

[proxy]
EOF

	chmod 600 /etc/NetworkManager/system-connections/enp0s9.nmconnection
fi

echo ""
echo "______________________________Forward______________________________"
sysctl net.ipv4.ip_forward=1 >> /etc/sysctl.conf
sysctl enable --now iptables
sysctl status iptables

echo ""
echo "_________________________MASQUERADE________________________"
iptables -F
iptables -t nat -A POSTROUTING -s ip_s8 -o enp0s3 -j MASQUERADE
iptables -t nat -A POSTROUTING -s ip_s9 -o enp0s3 -j MASQUERADE
iptables-save --file /etc/sysconfig/iptables
exec bash
