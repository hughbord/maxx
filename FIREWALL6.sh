#!/bin/bash

function CLEAR6 { # Clears firewall6 rules
    echo -e "${C_INFO} Clearing IP6TABLES rules..."
    $IP6TABLES_BIN -F
    $IP6TABLES_BIN -X
    $IP6TABLES_BIN -Z
    $IP6TABLES_BIN -t nat -F
    $IP6TABLES_BIN -t nat -X
    $IP6TABLES_BIN -t mangle -F
    $IP6TABLES_BIN -t mangle -X
}

function ALLOW_PORTS6 { # Cycle through devices and allow in and out ports for any IP address
    echo  -ne "${C_INFO} Allowing TCP IN all interfaces: "
    for port in $TCPPORTSIN; do
        echo -ne " $port"
        $IPTABLES_BIN -A INPUT -p tcp --dport $port -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
    done
    
    echo  -ne "\n${C_INFO} Allowing TCP OUT all interfaces: "
    for port in $TCPPORTSOUT; do
        echo -ne " $port"
        $IPTABLES_BIN -A OUTPUT -p tcp --sport $port -m conntrack --ctstate ESTABLISHED -j ACCEPT
    done
    
    echo  -ne "\n${C_INFO} Allowing UDP IN all interfaces: "
    for port in $UPDPORTSIN; do
        echo -ne " $port"
        $IPTABLES_BIN -A INPUT -p udp --dport $port -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
    done
    
    echo  -ne "\n${C_INFO} Allowing UDP OUT all interfaces: "
    for port in $UPDPORTSOUT; do
        echo -ne " $port"
        $IPTABLES_BIN -A OUTPUT -p udp --sport $port -m conntrack --ctstate ESTABLISHED -j ACCEPT
    done
}

function ALLOW_PORTS_IP6S_TCP { # ALLOW_PORTS_IP6S_TCP 7000
    echo  -ne "\n${C_INFO} Allowing IPS TCP: "
    
    for ipaddress in $TCPPIP6SIN; do
        echo -ne " $ipaddress $1"
        $IPTABLES_BIN -A INPUT -p tcp -s "$ipaddress" --dport "$1" -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
        $IPTABLES_BIN -A OUTPUT -p tcp --sport "$1" -m conntrack --ctstate ESTABLISHED -j ACCEPT
    done
}

function ALLOW_PORTS_IP6S_UDP { 
    echo  -ne "\n${C_INFO} Allowing IPS UDP: "
    for ipaddress in $UPDIP6SIN; do
        echo -ne " $ipaddress $1"
        $IPTABLES_BIN -A INPUT -p udp -s "$ipaddress" --dport "$1" -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
        $IPTABLES_BIN -A OUTPUT -p udp --sport "$1" -m conntrack --ctstate ESTABLISHED -j ACCEPT
    done
}

function ALLOW_LOCALHOST6 { # Allow localhost for firewall
    echo -e  "${C_INFO} Allowing Localhost..."
    $IP6TABLES_BIN -A INPUT -i lo -j ACCEPT
    $IP6TABLES_BIN -A OUTPUT -o lo -j ACCEPT
}

function ALLOW_STATES6 { # Allow states
    $IP6TABLES_BIN -A INPUT -m conntrack --ctstate INVALID -j DROP
    $IP6TABLES_BIN -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
    $IP6TABLES_BIN -A OUTPUT -m conntrack --ctstate ESTABLISHED -j ACCEPT
}

function DROP_EVERYTHING6 { # Drop all remaining traffic that doesn't fit with the rules
    echo -ne "\n${C_INFO} Dropping everything else on TCP and UDP...\n"
    # $IP6TABLES_BIN -A INPUT -p udp -j LOG --log-prefix "fw-bl-udp6-drop: " --log-level 7
    # $IP6TABLES_BIN -A INPUT -p tcp --syn -j LOG --log-prefix "fw-bl-tcp6-drop: " --log-level 7
    $IP6TABLES_BIN -A INPUT -p udp -j DROP
    $IP6TABLES_BIN -A INPUT -p tcp --syn -j DROP
}

function IP_MASQ6 {
    echo -ne "${C_INFO} Not use masq for ipv6 yet bro"
    # $IPTABLES_BIN -t nat -A POSTROUTING -o "${TUN}" -j MASQUERADE
    # $IPTABLES_BIN -A FORWARD -i "${TUN}" -o "${ETH}" -m state --state RELATED,ESTABLISHED -j ACCEPT
    # $IPTABLES_BIN -A FORWARD -i "${ETH}" -o "${TUN}" -j ACCEPT
}

function PORTSCAN_PROTECT {
    $IP6TABLES_BIN -N port-scanning
    $IP6TABLES_BIN -A port-scanning -p tcp --tcp-flags SYN,ACK,FIN,RST RST -m limit --limit 1/s --limit-burst 2 -j RETURN
    $IP6TABLES_BIN -A port-scanning -j DROP
}

function ICMP_BLOCK { # Specify network device to block ICMP
    $IP6TABLES_BIN -A INPUT -p icmp --icmp-type echo-request -j DROP
    $IP6TABLES_BIN -A INPUT -i $1 -p icmp --icmp-type echo-request -j DROP
    
}

function ICMP_ALLOW { # Specify network device to block ICMP
    $IP6TABLES_BIN -A INPUT -p icmp --icmp-type echo-request -j DROP
    $IP6TABLES_BIN -A INPUT -i $1 -p icmp --icmp-type echo-request -j DROP
}

function MAC_ADDRESS_BLOCK {
    $IP6TABLES_BIN -A INPUT -m mac --mac-source $1 -j DROP
}

function MAC_ADDRESS_ALLOW {
    $IP6TABLES_BIN -A INPUT -m mac --mac-source $1 -j ACCEPT
}

function BLOCK_IP_INTERFACE { # BLOCK_IP_INTERFACE eth0 1.1.1.1
    $IP6TABLES_BIN -A INPUT -i $1 -s $2 -j DROP
}

function ALLOW_IP_INTERFACE { # ALLOW_IP_INTERFACE eth0 1.1.1.1
    $IP6TABLES_BIN -A INPUT -i $1 -s $2 -j ACCEPT
}

function BLOCK_IPSET_INTERFACE6 { # BLOCK_IPSET_INTERFACE eth0
    $IP6TABLES_BIN -A INPUT -i $1 -m set --match-set "nonwhitelist" -j DROP
    
}

function BLOCK_BOGONS6 {
    echo -ne "${C_INFO} BLOCK_BOGONS6";
    # _subnets=("224.0.0.0/4" "169.254.0.0/16" "172.16.0.0/12" "192.0.2.0/24" "192.168.0.0/16" "10.0.0.0/8" "0.0.0.0/8" "240.0.0.0/5")
    
    # for _sub in "${_subnets[@]}" ; do
    #     #$IPTABLES_BIN -A PREROUTING -t mangle  -s "$_sub" --log-prefix "$_sub-bogon-bl: " --log-level 7
    #     $IPTABLES_BIN -A PREROUTING -t mangle  -s "$_sub" -j DROP
    # done
    
    # #$IPTABLES_BIN -t mangle -A PREROUTING -s 127.0.0.0/8 ! -i lo --log-prefix "$_sub-bogon-bl: " --log-level 7
    # $IPTABLES_BIN -t mangle -A PREROUTING -s 127.0.0.0/8 ! -i lo -j DROP
}

function BLOCK_BOGUS_TCP_FLAGS6 {
    $IP6TABLES_BIN -t mangle -A PREROUTING -p tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG NONE -j DROP
    $IP6TABLES_BIN -t mangle -A PREROUTING -p tcp --tcp-flags FIN,SYN FIN,SYN -j DROP
    $IP6TABLES_BIN -t mangle -A PREROUTING -p tcp --tcp-flags SYN,RST SYN,RST -j DROP
    $IP6TABLES_BIN -t mangle -A PREROUTING -p tcp --tcp-flags FIN,RST FIN,RST -j DROP
    $IP6TABLES_BIN -t mangle -A PREROUTING -p tcp --tcp-flags FIN,ACK FIN -j DROP
    $IP6TABLES_BIN -t mangle -A PREROUTING -p tcp --tcp-flags ACK,URG URG -j DROP
    $IP6TABLES_BIN -t mangle -A PREROUTING -p tcp --tcp-flags ACK,FIN FIN -j DROP
    $IP6TABLES_BIN -t mangle -A PREROUTING -p tcp --tcp-flags ACK,PSH PSH -j DROP
    $IP6TABLES_BIN -t mangle -A PREROUTING -p tcp --tcp-flags ALL ALL -j DROP
    $IP6TABLES_BIN -t mangle -A PREROUTING -p tcp --tcp-flags ALL NONE -j DROP
    $IP6TABLES_BIN -t mangle -A PREROUTING -p tcp --tcp-flags ALL FIN,PSH,URG -j DROP
    $IP6TABLES_BIN -t mangle -A PREROUTING -p tcp --tcp-flags ALL SYN,FIN,PSH,URG -j DROP
    $IP6TABLES_BIN -t mangle -A PREROUTING -p tcp --tcp-flags ALL SYN,RST,ACK,FIN,URG -j DROP
    
    $IP6TABLES_BIN -t mangle -A PREROUTING -p tcp -m conntrack --ctstate NEW -m tcpmss ! --mss 536:65535 -j DROP
    $IP6TABLES_BIN -A INPUT -p tcp --tcp-flags ALL NONE -j DROP
    $IP6TABLES_BIN -A INPUT -p tcp --tcp-flags ALL ALL -j DROP
    $IP6TABLES_BIN -A INPUT -f -j DROP
    $IP6TABLES_BIN -A INPUT -p tcp ! --syn -m state --state NEW -j DROP
}

function SYN_FLOOD_PROTECT6 {
    $IP6TABLES_BIN -N syn_flood
    $IP6TABLES_BIN -A INPUT -p tcp --syn -j syn_flood
    $IP6TABLES_BIN -A syn_flood -m limit --limit 1/s --limit-burst 3 -j RETURN
    $IP6TABLES_BIN -A syn_flood -j DROP
    $IP6TABLES_BIN -A INPUT -p icmp -m limit --limit  1/s --limit-burst 1 -j ACCEPT
    $IP6TABLES_BIN -A INPUT -p icmp -m limit --limit 1/s --limit-burst 1 -j LOG --log-prefix PING-DROP:
    $IP6TABLES_BIN -A INPUT -p icmp -j DROP
    $IP6TABLES_BIN -A OUTPUT -p icmp -j ACCEPT
}