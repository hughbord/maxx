#!/bin/bash

function CLEAR { # Clears firewall rules
    echo " * Clearing IPTABLES rules..."
    $IPTABLES_BIN -F
    $IPTABLES_BIN -X
    $IPTABLES_BIN -Z
    $IPTABLES_BIN -t nat -F
    $IPTABLES_BIN -t nat -X
    $IPTABLES_BIN -t mangle -F
    $IPTABLES_BIN -t mangle -X
}

function ALLOW_PORTS { # Cycle through devices and allow in and out ports, with rate limiting
    echo  -ne " * Allowing TCP IN eth0: "
    for port in $TCPPORTSIN; do
        echo -ne " $port"
        $IPTABLES_BIN -A INPUT -p tcp --dport $port  -j ACCEPT
    done
    
    echo  -ne "\n * Allowing TCP OUT eth0: "
    for port in $TCPPORTSOUT; do
        echo -ne " $port"
        $IPTABLES_BIN -A OUTPUT -p tcp --sport $port  -j ACCEPT
    done
    
    echo  -ne "\n * Allowing UDP IN eth0: "
    for port in $UPDPORTSIN; do
        echo -ne " $port"
        $IPTABLES_BIN -A INPUT -p udp --dport $port -j ACCEPT
    done
    
    echo  -ne "\n * Allowing UDP OUT eth0: "
    for port in $UPDPORTSOUT; do
        echo -ne " $port"
        $IPTABLES_BIN -A OUTPUT -p udp --sport $port -j ACCEPT
    done
}

function ALLOW_IPS { # IPV4 Only
    echo  -ne "\n * Allowing IPS TCP: "
    
    for port in $TCPPIPSIN; do
        echo -ne " $port"
        $IPTABLES_BIN -A INPUT -p tcp --dport $port  -j ACCEPT
    done
    
    echo  -ne "\n * Allowing IPS UDP: "
    for port in $UPDIPSIN; do
        echo -ne " $port"
        $IPTABLES_BIN -A INPUT -p udp --dport $port -j ACCEPT
    done
}


function ALLOW_LOCALHOST { # Allow localhost for firewall
    echo " * Allowing Localhost..."
    $IPTABLES_BIN -A INPUT -i lo -j ACCEPT
    $IPTABLES_BIN -A OUTPUT -o lo -j ACCEPT
}

function ALLOW_STATES { # Allow states
    $IPTABLES_BIN -A INPUT -m conntrack --ctstate INVALID -j DROP
    $IPTABLES_BIN -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
    $IPTABLES_BIN -A OUTPUT -m conntrack --ctstate ESTABLISHED -j ACCEPT
}

function DROP_EVERYTHING { # Drop all remaining traffic that doesn't fit with the rules
    echo -ne "\n * Dropping everything else on TCP and UDP...\n"
    #$IPTABLES_BIN -A INPUT -p udp -j LOG --log-prefix "fw-bl-udp-drop: " --log-level 7
    $IPTABLES_BIN -A INPUT -p udp -j DROP
    
    #$IPTABLES_BIN -A INPUT -p tcp --syn -j LOG --log-prefix "fw-bl-tcp-drop: " --log-level 7
    $IPTABLES_BIN -A INPUT -p tcp --syn -j DROP
}

function IP_MASQ {
    $IPTABLES_BIN -t nat -A POSTROUTING -o tun0 -j MASQUERADE
    $IPTABLES_BIN -A FORWARD -i tun0 -o eth0 -m state --state RELATED,ESTABLISHED -j ACCEPT
    $IPTABLES_BIN -A FORWARD -i eth0 -o tun0 -j ACCEPT
}

function PORTSCAN_PROTECT {
    $IPTABLES_BIN -N port-scanning
    $IPTABLES_BIN -A port-scanning -p tcp --tcp-flags SYN,ACK,FIN,RST RST -m limit --limit 1/s --limit-burst 2 -j RETURN
    $IPTABLES_BIN -A port-scanning -j DROP  
}

function ICMP_BLOCK { # Specify network device to block ICMP
    $IPTABLES_BIN -A INPUT -p icmp --icmp-type echo-request -j DROP
    $IPTABLES_BIN -A INPUT -i $1 -p icmp --icmp-type echo-request -j DROP
    
}

function ICMP_ALLOW { # Specify network device to block ICMP
    $IPTABLES_BIN -A INPUT -p icmp --icmp-type echo-request -j DROP
    $IPTABLES_BIN -A INPUT -i $1 -p icmp --icmp-type echo-request -j DROP
}

function MAC_ADDRESS_BLOCK {
    $IPTABLES_BIN -A INPUT -m mac --mac-source $1 -j DROP
}

function MAC_ADDRESS_ALLOW {
    $IPTABLES_BIN -A INPUT -m mac --mac-source $1 -j ACCEPT
}

function BLOCK_IP_INTERFACE { # BLOCK_IP_INTERFACE eth0 1.1.1.1
    $IPTABLES_BIN -A INPUT -i $1 -s $2 -j DROP
}

function ALLOW_IP_INTERFACE { # ALLOW_IP_INTERFACE eth0 1.1.1.1
    $IPTABLES_BIN -A INPUT -i $1 -s $2 -j ACCEPT
}

function BLOCK_IPSET_INTERFACE { # BLOCK_IPSET_INTERFACE eth0
    $IPTABLES_BIN -A INPUT -i $1 -m set --match-set "nonwhitelist" -j DROP
}

function BLOCK_BOGONS {
    _subnets=("224.0.0.0/4" "169.254.0.0/16" "172.16.0.0/12" "192.0.2.0/24" "192.168.0.0/16" "10.0.0.0/8" "0.0.0.0/8" "240.0.0.0/5")
    
    for _sub in "${_subnets[@]}" ; do
        #$IPTABLES_BIN -A PREROUTING -t mangle  -s "$_sub" --log-prefix "$_sub-bogon-bl: " --log-level 7
        $IPTABLES_BIN -A PREROUTING -t mangle  -s "$_sub" -j DROP
    done
    
    #$IPTABLES_BIN -t mangle -A PREROUTING -s 127.0.0.0/8 ! -i lo --log-prefix "$_sub-bogon-bl: " --log-level 7
    $IPTABLES_BIN -t mangle -A PREROUTING -s 127.0.0.0/8 ! -i lo -j DROP
}

function BLOCK_BOGUS_TCP_FLAGS {
    $IPTABLES_BIN -t mangle -A PREROUTING -p tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG NONE -j DROP
    $IPTABLES_BIN -t mangle -A PREROUTING -p tcp --tcp-flags FIN,SYN FIN,SYN -j DROP
    $IPTABLES_BIN -t mangle -A PREROUTING -p tcp --tcp-flags SYN,RST SYN,RST -j DROP
    $IPTABLES_BIN -t mangle -A PREROUTING -p tcp --tcp-flags FIN,RST FIN,RST -j DROP
    $IPTABLES_BIN -t mangle -A PREROUTING -p tcp --tcp-flags FIN,ACK FIN -j DROP
    $IPTABLES_BIN -t mangle -A PREROUTING -p tcp --tcp-flags ACK,URG URG -j DROP
    $IPTABLES_BIN -t mangle -A PREROUTING -p tcp --tcp-flags ACK,FIN FIN -j DROP
    $IPTABLES_BIN -t mangle -A PREROUTING -p tcp --tcp-flags ACK,PSH PSH -j DROP
    $IPTABLES_BIN -t mangle -A PREROUTING -p tcp --tcp-flags ALL ALL -j DROP
    $IPTABLES_BIN -t mangle -A PREROUTING -p tcp --tcp-flags ALL NONE -j DROP
    $IPTABLES_BIN -t mangle -A PREROUTING -p tcp --tcp-flags ALL FIN,PSH,URG -j DROP
    $IPTABLES_BIN -t mangle -A PREROUTING -p tcp --tcp-flags ALL SYN,FIN,PSH,URG -j DROP
    $IPTABLES_BIN -t mangle -A PREROUTING -p tcp --tcp-flags ALL SYN,RST,ACK,FIN,URG -j DROP
    
    $IPTABLES_BIN -t mangle -A PREROUTING -p tcp -m conntrack --ctstate NEW -m tcpmss ! --mss 536:65535 -j DROP
    $IPTABLES_BIN -A INPUT -p tcp --tcp-flags ALL NONE -j DROP
    $IPTABLES_BIN -A INPUT -p tcp --tcp-flags ALL ALL -j DROP
    $IPTABLES_BIN -A INPUT -f -j DROP
    $IPTABLES_BIN -A INPUT -p tcp ! --syn -m state --state NEW -j DROP
}

function SYN_FLOOD_PROTECT {
    $IPTABLES_BIN -N syn_flood
    $IPTABLES_BIN -A INPUT -p tcp --syn -j syn_flood
    $IPTABLES_BIN -A syn_flood -m limit --limit 1/s --limit-burst 3 -j RETURN
    $IPTABLES_BIN -A syn_flood -j DROP
    $IPTABLES_BIN -A INPUT -p icmp -m limit --limit  1/s --limit-burst 1 -j ACCEPT
    $IPTABLES_BIN -A INPUT -p icmp -m limit --limit 1/s --limit-burst 1 -j LOG --log-prefix PING-DROP:
    $IPTABLES_BIN -A INPUT -p icmp -j DROP
    $IPTABLES_BIN -A OUTPUT -p icmp -j ACCEPT
}