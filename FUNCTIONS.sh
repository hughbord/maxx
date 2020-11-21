#!/bin/bash

# Exits the script on any failures
set -euf -o pipefail

if [ ! -f ".env" ]; then
    echo -e "${C_ERROR} Please setup your .env file by typing cp .env.example .env && nano .env, ${F_BOLD}you dumb fuck.${NO_FORMAT}"
    exit 1
fi

. ".env"

if [ $USE_IPV6 = "1" ]; then
    BIN_ARRAY=("$IPTABLES_BIN" "$IPSET_BIN" "$IP6TABLES_BIN" "$IPTABLES_SAVE" )
    FILE_ARRAY=("$IPLISTSCSV" "$IPLISTSCSV6")
else
    BIN_ARRAY=("$IPTABLES_BIN" "$IPSET_BIN" "$IPTABLES_SAVE" )
    FILE_ARRAY=("$IPLISTSCSV")  
fi

for i in "${BIN_ARRAY[@]}"
do
    if [ ! -x "$i" ]; then
        echo -e "${C_ERROR} Could not find executable $i, ${F_BOLD}sort that shit out bro.${NO_FORMAT}"

        exit 1;
    fi
done

for i in "${FILE_ARRAY[@]}"
do
    if [ ! -f "$i" ]; then
        echo -e "${C_ERROR} Could not find file $i, ${F_BOLD}sort that shit out bro.${NO_FORMAT}"

        exit 1;
    fi
done

. "FIREWALL4.sh"
. "IPLIST4.sh"

SCRIPT_NAMES=("FIREWALL4.sh" "IPLIST4.sh")

if [ $USE_IPV6 = "1" ]; then
    . "FIREWALL6.sh"
    . "IPLIST6.sh"
    SCRIPT_NAMES+=("FIREWALL6.sh" "IPLIST6.sh")
fi

if [ "$IPBLUSER" = "" ]; then
    echo -e "${C_ERROR} Please ensure you have a IPBLUSER set in .env, ${F_BOLD}you dumb fuck.${NO_FORMAT}"
    exit 1
fi

if [ "$IPBLPIN" = "" ]; then
    echo -e "${C_ERROR} Please ensure you have a IPBLPIN set in .env, ${F_BOLD}you dumb fuck.${NO_FORMAT}"
    exit 1
fi

function SHOW_ALL_HELP { # Show all the help for all the things
    for i in "${SCRIPT_NAMES[@]}"
    do
            echo -ne " * $i \n"
            cat "$i" | grep "{ #" | sort | sed -e 's/{ #/- /g' -e 's/function /\t/g'
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


function SAFETY_TIMEOUT {
    echo -e "${C_INFO} ${C_YELLOW}Press any key within $SAFETY_TIMEOUT_SECONDS seconds to confirm that you still have connectivity...${NO_FORMAT}"
    read -t $SAFETY_TIMEOUT_SECONDS -p "" || CLEAR
}

function SHOW_HEADER {
    cat "${ANSI_HEADER}"
}


# PRECONFIGURED FIREWALLS FOR FREE

function IRC_FIREWALL {
    CLEAR
    ALLOW_STATES
    ALLOW_LOCALHOST
    ALLOW_PORTS
    #ALLOW_PORTS_IPS_TCP 7000
    BLOCK_BOGUS_TCP_FLAGS
    PORTSCAN_PROTECT
    BLOCK_BOGONS
    ICMP_BLOCK $ETH
    IPSET_SAVE_FILE
    DL_ALL_LISTS
    LOAD_BL
    DROP_EVERYTHING
    
    if [ $USE_IPV6 = "1" ]; then
        CLEAR6
        ALLOW_STATES6
        ALLOW_LOCALHOST6
        ALLOW_PORTS6
        BLOCK_BOGUS_TCP_FLAGS6
        PORTSCAN_PROTECT6
        
        ICMP_BLOCK6 $ETH
        IPSET_SAVE_FILE6
        DL_ALL_LISTS6
        LOAD_BL6
        DROP_EVERYTHING6
    fi
    
    SAFETY_TIMEOUT
}

function BASIC_PI {
    CLEAR
    ALLOW_STATES
    ALLOW_LOCALHOST
    ALLOW_PORTS
    DL_ALL_LISTS
    IPSET_SAVE_FILE
    LOAD_BL
    IP_MASQ
    DROP_EVERYTHING
    
    if [ $USE_IPV6 = "1" ]; then
        CLEAR6
        ALLOW_STATES6
        ALLOW_LOCALHOST6
        ALLOW_PORTS6
        #IP_MASQ6
        DROP_EVERYTHING6
    fi
    
    SAFETY_TIMEOUT
}

function BASIC_FIREWALL {
    CLEAR
    ALLOW_STATES
    ALLOW_LOCALHOST
    ALLOW_PORTS
    ALLOW_PORTS_IPS_TCP 7771
    DL_ALL_LISTS
    IPSET_SAVE_FILE
    LOAD_BL
    DROP_EVERYTHING
    
    if [ $USE_IPV6 = "1" ]; then
        CLEAR6
        ALLOW_STATES6
        ALLOW_LOCALHOST6
        ALLOW_PORTS6
        ALLOW_PORTS_IP6S_TCP 7771
        DL_ALL_LISTS6
        IPSET_SAVE_FILE6
        LOAD_BL6
        DROP_EVERYTHING6
    fi
    
    SAFETY_TIMEOUT
}