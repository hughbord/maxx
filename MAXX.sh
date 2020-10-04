#!/bin/bash

#set -euf -o pipefail

if [ ! -f ".env" ]; then
    echo "Please setup your .env file by typing cp .env.example .env && nano .env, you dumb fuck."
    exit 1
fi

. ".env"

if [ "$IPBLUSER" = "" ]; then
    echo "Please ensure you have a IPBLUSER set in .env"
    exit 1
fi

if [ "$IPBLPIN" = "" ]; then
    echo "Please ensure you have a IPBLPIN set in .env"
    exit 1
fi

function CLEAR { # Clears firewall rules
    echo " * Clearing IPTABLES rules..."
    $iptables -F
    $iptables -X
    $iptables -Z
    $iptables -t nat -F
    $iptables -t nat -X
    $iptables -t mangle -F
    $iptables -t mangle -X
}

function SHOWALLHELP { # Show all the help for all the things
    for i in "${MAXXMODULES[@]}"
    do
        if [ $i != 'HELP' ]
        then
            echo -ne " * $i \n"
            cat THEMAXX/$OS/$i | grep "{ #" | sort | sed -e 's/{ #/- /g' -e 's/function /\t/g'
        fi
    done
}


# function CHECKIPBLCREDS {
#     if [ "$IPBLUSER" = "" ]; then
#         echo "Please ensure you have a IPBLUSER set in .env"
# 		return 0
#     fi

#     if [ "$IPBLPIN" = "" ]; then
#         echo "Please ensure you have a IPBLPIN set in .env"
# 		return 0
#     fi

# 	return 1
# }

function ALLOWPORTS { # Cycle through devices and allow in and out ports, with rate limiting
    echo  -ne " * Allowing TCP IN eth0: "
    for port in $TCPPORTSIN; do
        echo -ne " $port"
        $iptables -A INPUT -p tcp --dport $port  -j ACCEPT
    done
    
    echo  -ne "\n * Allowing TCP OUT eth0: "
    for port in $TCPPORTSOUT; do
        echo -ne " $port"
        $iptables -A OUTPUT -p tcp --sport $port  -j ACCEPT
    done
    
    echo  -ne "\n * Allowing UDP IN eth0: "
    for port in $UPDPORTSIN; do
        echo -ne " $port"
        $iptables -A INPUT -p udp --dport $port -j ACCEPT
    done
    
    echo  -ne "\n * Allowing UDP OUT eth0: "
    for port in $UPDPORTSOUT; do
        echo -ne " $port"
        $iptables -A OUTPUT -p udp --sport $port -j ACCEPT
    done
}

function ALLOWIPS {
    echo  -ne "\n * Allowing IPS TCP: "
    
    for port in $TCPPIPSIN; do
        echo -ne " $port"
        $iptables -A INPUT -p tcp --dport $port  -j ACCEPT
    done
    
    echo  -ne "\n * Allowing IPS UDP: "
    for port in $UPDIPSIN; do
        echo -ne " $port"
        $iptables -A INPUT -p udp --dport $port -j ACCEPT
    done
}


function ALLOWLOCALHOST { # Allow localhost for firewall
    echo " * Allowing Localhost..."
    $iptables -A INPUT -i lo -j ACCEPT
    $iptables -A OUTPUT -o lo -j ACCEPT
}

function IPSETMAKE { # Makes a new IPSET list.
    /usr/sbin/ipset create "$1" hash:net family inet hashsize 65536 maxelem 1048576 && \
    echo -ne "\t * Created $1 IPSet...\n" || echo -ne "\t * IPSet list $1 appears to alredy exist...\n"
}

function ALLOWSTATES { # Allow states
    $iptables -A INPUT -m conntrack --ctstate INVALID -j DROP
    $iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
    $iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED -j ACCEPT
}

function DROPEVERYTHING { # Drop all remaining traffic that doesn't fit with the rules
    echo -ne "\n * Dropping everything else on TCP and UDP...\n"
    #$iptables -A INPUT -p udp -j LOG --log-prefix "fw-bl-udp-drop: " --log-level 7
    $iptables -A INPUT -p udp -j DROP
    
    #$iptables -A INPUT -p tcp --syn -j LOG --log-prefix "fw-bl-tcp-drop: " --log-level 7
    $iptables -A INPUT -p tcp --syn -j DROP
}

# Get IP Blocklist List
function GETBLOCKLIST { # Downloads iblocklist.com blacklists (you need an account)
    wget -qO- "$2"  | sed -e "s/^/add $1 /" > "$TMP_DIR/$1.txt" && ipset restore < "$TMP_DIR/$1.txt" && rm "$TMP_DIR/$1.txt"
}

function GETIPBLOCKLIST {
    wget -qO- "http://list.iblocklist.com/?list=$2&fileformat=cidr&archiveformat=gz&username=$IPBLUSER&pin=$IPBLPIN" | gunzip | tail -n +2 | sed  -e '/^#/ d' -e '/^\s*$/d' |  awk '!x[$0]++' - | sed -e "s/^/add $1 /" > "$TMP_DIR/$1.txt" && ipset restore < "$TMP_DIR/$1.txt" && rm "$TMP_DIR/$1.txt"
}

function IPSETSAVEFILE {
    /usr/sbin/ipset save > "$IPLISTALL"
}

function IPSETRESTOREFILE {
    /usr/sbin/ipset restore < "$IPLISTALL"
}

BLNAME=()

function DLALLLISTS { # Download all free and paid lists (will split this later)
    echo -en " * Downloading lists...\n"
    
    while read fdesc ffname fauthor furl
    do #	     4     1      3      2
        
        if [[ "$fdesc" == *"#"* ]] # If the first char is #, we will skip that list. Can comment out down or undesired lists
        then
            echo "" > /dev/null
        else
            echo -ne " * Saving $ffname...\n"
            
            # Make ipset name array here
            BLNAME+=("$ffname")
            
            if [[ "$fauthor" == "free" ]]
            then
                /usr/sbin/ipset destroy $ffname
                IPSETMAKE $ffname
                GETBLOCKLIST $ffname $furl $fauthor $fdesc
            else
                /usr/sbin/ipset destroy $ffname
                IPSETMAKE $ffname
                GETIPBLOCKLIST $ffname $furl $fauthor $fdesc
            fi
        fi
        
    done < "$IPLISTSCSV"
    IFS=$OLDIFS
    
    # Reset script variables
    COUNTER=0
    J=0
    OLDIFS=$IFS
    IFS=,
}

function IPMASQ {
    $iptables -t nat -A POSTROUTING -o tun0 -j MASQUERADE
    $iptables -A FORWARD -i tun0 -o eth0 -m state --state RELATED,ESTABLISHED -j ACCEPT
    $iptables -A FORWARD -i eth0 -o tun0 -j ACCEPT
}

function LOADBL { # Restores blacklists into the firewall
    echo " * Loading blacklists..."
    for i in "${BLNAME[@]}"
    do
        echo -ne "\t * Restoring blacklist $i..."
        $iptables -A INPUT -m set --match-set "$i" src -j LOG --log-prefix "$i-bl-in: " --log-level 7
        $iptables -A INPUT -m set --match-set "$i" src -j DROP
        
        $iptables -A OUTPUT -m set --match-set "$i" dst -j LOG --log-prefix "$i-bl-out: " --log-level 7
        $iptables -A OUTPUT -m set --match-set "$i" dst -j DROP
        
        $iptables -A FORWARD -m set --match-set "$i" dst -j LOG --log-prefix "$i-bl-fwd-out: " --log-level 7
        $iptables -A FORWARD -m set --match-set "$i" dst -j DROP
        
        $iptables -A FORWARD -m set --match-set "$i" src -j LOG --log-prefix "$i-bl-fwd-in: " --log-level 7
        $iptables -A FORWARD -m set --match-set "$i" src -j DROP
        
        echo -ne " restored.\n"
    done

    
}

function IRC_FIREWALL {
    CLEAR
    ALLOWSTATES
    ALLOWLOCALHOST
    ALLOWPORTS
    # BLOCK BOGONS
    # Other IRC shit
    IPSETSAVEFILE
    DLALLLISTS
    LOADBL
    IPMASQ
    DROPEVERYTHING
}

function BASIC_PI {
    CLEAR
    ALLOWSTATES
    ALLOWLOCALHOST
    ALLOWPORTS
    DLALLLISTS
    IPSETSAVEFILE
    LOADBL
    IPMASQ
    DROPEVERYTHING
}

function BASIC_FIREWALL {
    CLEAR
    ALLOWSTATES
    ALLOWLOCALHOST
    ALLOWPORTS
    DLALLLISTS
    IPSETSAVEFILE
    LOADBL
    DROPEVERYTHING
}

if [ ! -z "$1" ]
then
    $1
else
    echo "Yo bro you gotta put an argument LOL."
fi