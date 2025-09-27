#!/bin/sh
# Copyright (C) 2021-2022 Tianling Shen <cnsztl@immortalwrt.org>

. /lib/functions.sh

NAME="unblockneteasemusic"

command -v "curl" >"/dev/null" || { echo -e "curl is not found."; exit 1; }

echo -e "Launching luci-app-unblockneteasmusic Debugging Tool..."
echo -e "\n"

echo -e "OpenWrt info:"
ubus call system board || cat "/etc/openwrt_release"
echo -e "\n"

echo -e "uclient-fetch info:"
opkg info uclient-fetch
opkg info libustream-*
opkg info wget-ssl
wget -T10 -O- 'https://api.github.com/repos/UnblockNeteaseMusic/server/commits?sha=enhanced&path=precompiled' | jsonfilter -e '@[0].sha' || echo -e "Failed to connect to GitHub with uclient-fetch."
echo -e "\n"

echo -e "Node.js info:"
opkg info node
echo -e "Node.js is placed at $(command -v node || echo "Not Found")"
echo -e "Node.js version: $(node -v 2>"/dev/null" || echo "Not Found")"
echo -e "\n"

echo -e "luci-app-unblockneteasmusic info:"
opkg info "luci-app-unblockneteasemusic"
ls -lh "/etc/config/$NAME" "/etc/init.d/$NAME" "/usr/share/$NAME"
cat "/etc/config/$NAME" | sed -e "s,joox_cookie .*,joox_cookie 'set',g" \
	-e "s,migu_cookie .*,migu_cookie 'set',g" \
	-e "s,qq_cookie .*,qq_cookie 'set',g" \
	-e "s,youtube_key .*,youtube_key 'set',g" \
	-e "s,proxy_server_ip .*,proxy_server_ip 'set',g"
echo -e "\n"

echo -e "UnblockNeteaseMusic Node.js info:"
echo -e "Git HEAD version: $(cat "/usr/share/$NAME/core_local_ver" 2>"/dev/null" || echo "Not Found")"
echo -e "Core version: $(node "/usr/share/$NAME/core/app.js" -v 2>"/dev/null" || echo "Not Found")"
ls -lh "/usr/share/$NAME/core" 2>"/dev/null"
echo -e "\n"

echo -e "Netease networking info:"
curl -fsv "http://music.163.com/song/media/outer/url?id=641644.mp3" 2>&1 | grep "Location" || echo -e "Cannot connect to NeteaseMusic."
curl -sSL "http://httpdns.n.netease.com/httpdns/v2/d?domain=music.163.com" || echo -e "Cannot connect to Netease HTTPDNS."
config_load "$NAME"
config_get custom_proxy "config" "proxy_server_ip"
[ -n "$custom_proxy" ] && { curl -sL -x "$custom_proxy" "http://music.163.com/song/media/outer/url?id=641644.mp3" 2>&1 | grep "Location" || echo -e "Cannot connect to NeteaseMusic via proxy."; }
echo -e "\n"

echo -e "Port status:"
config_get unm_port "config" "http_port" "5200"
config_get unm_ports "config" "https_port" "5201"
[ "$(config_get "config" "hijack_ways")" = "use_hosts" ] && { unm_port="80"; unm_ports="443"; }
netstat -tlpen | grep "$unm_port" || echo -e "No instance found on port $unm_port."
netstat -tlpen | grep "$unm_ports" || echo -e "No instance found on port $unm_ports."
echo -e "\n"

echo -e "PROCD running info:"
running_stat="$(ubus call service list '{"name": "unblockneteasemusic", "verbose": true}' | \
	sed -e 's,"JOOX_COOKIE".*","JOOX_COOKIE": "set",g' \
	    -e 's,"MIGU_COOKIE".*","MIGU_COOKIE": "set",g' \
	    -e 's,"QQ_COOKIE".*","QQ_COOKIE": "set",g' \
	    -e 's,"YOUTUBE_KEY".*","YOUTUBE_KEY": "set",g')"
[ "$(echo -e "$running_stat" | jsonfilter -e "@.$NAME.instances.$NAME.running")" == "true" ] || is_stopped=1
echo -e "$running_stat"

echo -e "\n"

[ -n "$is_stopped" ] || {
	echo -e "Firewall info:"
	iptables -t "nat" -L "netease_cloud_music" 2>"/dev/null" || echo -e 'Chain "netease_cloud_music" not found.'
	echo -e ""
	ipset list "neteasemusic" 2>"/dev/null" || echo -e 'Table "neteasemusic" not found.'
	echo -e ""
	ipset list "acl_neteasemusic_http" 2>"/dev/null" || echo -e 'Table "acl_neteasemusic_http" not found.'
	echo -e ""
	ipset list "acl_neteasemusic_https" 2>"/dev/null" || echo -e 'Table "acl_neteasemusic_https" not found.'
	echo -e ""
	cat "/tmp/dnsmasq.d/dnsmasq-$NAME.conf"
	echo -e "\n"

	echo -e "Testing source replacing..."
	lan_ip="$(uci -q get "network.lan.ipaddr" || echo "127.0.0.1")"

	curl -sSL -X "POST" "https://music.163.com/weapi/song/enhance/player/url/v1?csrf_token=" --data "params=bf3kf%2BOyalbxNS%2FeHAXquH8D2nt2YrhBzww4zy5rj2H%2BeAhdOIaGh4HHHzcoREFcu9Ve35LUgc%2BGE1YJD1HxrJ87ucm5zK%2FFn1lLvHFv1A8ZAuyU1afjG28s2Xja6zpfg00T0EcCeqkK61OpTfAaqw%3D%3D&encSecKey=6bab0dfa7ee3b292f9263a7af466636731cdbbd1d8747c9178c17477e70be899b7788c4a4e315c9fdb8c6e787603db6f9dff62c356f164d35b16b7f2d9ad5ede3cc7336130605521a8f916d308ce86b15c32b81c883ae2ba9c244444d91e1683be93fa0ea3e2a85207c9d693b86b5bb31adb002dd56c0bbcce9c73ec3bf5c105"
	echo -e ""
	curl -ksSL -X "POST" -x "http://$lan_ip:$unm_port" "https://music.163.com/weapi/song/enhance/player/url/v1?csrf_token=" --data "params=bf3kf%2BOyalbxNS%2FeHAXquH8D2nt2YrhBzww4zy5rj2H%2BeAhdOIaGh4HHHzcoREFcu9Ve35LUgc%2BGE1YJD1HxrJ87ucm5zK%2FFn1lLvHFv1A8ZAuyU1afjG28s2Xja6zpfg00T0EcCeqkK61OpTfAaqw%3D%3D&encSecKey=6bab0dfa7ee3b292f9263a7af466636731cdbbd1d8747c9178c17477e70be899b7788c4a4e315c9fdb8c6e787603db6f9dff62c356f164d35b16b7f2d9ad5ede3cc7336130605521a8f916d308ce86b15c32b81c883ae2ba9c244444d91e1683be93fa0ea3e2a85207c9d693b86b5bb31adb002dd56c0bbcce9c73ec3bf5c105"
	echo -e ""
}

cat "/var/run/$NAME/run.log" 2>"/dev/null" || echo -e "Log is not avaiable."
