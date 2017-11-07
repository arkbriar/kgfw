# 一切为了愉快的科学上网！El psy congroo!

## Features

+ 白名单路由规则 (route/ip 命令)
+ 白名单DNS规则 (bind9)
+ Openconnect 穿墙 (服务器 BWG-LA-CN2)
+ ShiMo (VPN Client) 配置生成

可以做到

+ 通过软路由/树莓派配置，实现全局自动翻墙 (route/dns)
+ 通过 ShiMo(Mac) 配置，实现本地自动翻墙 (route)

## Usage

#### Build route script

生成白名单路由表。

```bash
# download CN nets into nets.txt
./get_cn_nets.sh

# build process_nets
go build process_nets.go

# convert nets.txt into route creation script
./process_nets -mode route -netsfile nets.txt -output routes.sh -gateway ${YOUR_GW}
```

然后在 ppp 设备上写一个 if-up 的脚本就能自动处理路由表了。

#### Connect Remote

```bash
# connect remote
./connect.sh

# setup iptables
iptables -t nat -A POSTROUTING -o tun0 -j MASQUERADE
```

#### Generate ShiMo (VPN Client for MacOSX) Config

生成一个 ShiMo 客户端用的配置，把所有的路由规则全加进去

```bash
# see help
./process_nets -h
```

因为大概有 8020 条规则，所以规则设置时间有点长 (20s)

Check how many route rules are there on Mac

```bash
netstat -nr | wc -l
```

#### Configure /etc/network/interfaces

把这两条加到 /etc/network/interfaces 就能在网卡起来的时候都自动连接了，建议加在 ppp 连接下面。

```bash
post-up echo ${OC_PASSWD} | openconnect --pid-file=/var/run/openconnect.pid -i tun0 -b -u ${OC_USER} --passwd-on-stdin --servercert ${OC_SERVERCERT} ${OC_SERVER}
pre-down kill `cat /var/run/openconnect.pid`
```

#### Configure BIND

用 bind9 自己做个 dns，实现白名单方式的 dns proxy (国内 114.114.114.114)。

在**默认配置**的基础上，配置只要改两个文件

**named.conf.options**

这里 trusted 是 bind9 的服务对象地址列表，需要自己改下

```
acl "trusted" {
127.0.0.1;
114.212.0.0/16;
172.16.0.0/12;
};

options {
	directory "/var/cache/bind";

	// If there is a firewall between you and nameservers you want
	// to talk to, you may need to fix the firewall to allow multiple
	// ports to talk.  See http://www.kb.cert.org/vuls/id/800113

	// If your ISP provided one or more IP addresses for stable
	// nameservers, you probably want to use them as forwarders.
	// Uncomment the following block, and insert the addresses replacing
	// the all-0's placeholder.

	// forwarders {
	// 	0.0.0.0;
	// };

	//========================================================================
	// If BIND logs error messages about the root key being expired,
	// you will need to update your keys.  See https://www.isc.org/bind-keys
	//========================================================================
	dnssec-validation auto;

	auth-nxdomain no;    # conform to RFC1035
	listen-on { any; };
	# listen-on-v6 { any; };
	allow-query { trusted; };
	allow-recursion { trusted; };
};
```

**named.conf.local**

这里先在 /etc/bind 下创建 cnlist 目录，把这个工程里的 3 个 .bind.conf 加进去 (这三个文件是由开源工程 https://github.com/felixonmars/dnsmasq-china-list 生成的)，白名单列表。

```
//
// Do any local configuration here
//

// Consider adding the 1918 zones here, if they are not used in your
// organization
//include "/etc/bind/zones.rfc1918";

include "/etc/bind/cnlist/accelerated-domains.china.bind.conf";
include "/etc/bind/cnlist/apple.china.bind.conf";
include "/etc/bind/cnlist/google.china.bind.conf";
```


