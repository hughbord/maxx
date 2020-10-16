#!/bin/bash

# Exits the script on any failures
set -euf -o pipefail

if [ ! -f ".env" ]; then
    echo "Please setup your .env file by typing cp .env.example .env && nano .env, you dumb fuck."
    exit 1
fi

. ".env"
. "FIREWALL4.sh"
. "FIREWALL6.sh"
. "IPLIST4.sh"
. "IPLIST6.sh"

if [ "$IPBLUSER" = "" ]; then
    echo "Please ensure you have a IPBLUSER set in .env, you dumb fuck."
    exit 1
fi

if [ "$IPBLPIN" = "" ]; then
    echo "Please ensure you have a IPBLPIN set in .env, you dumb fuck."
    exit 1
fi

# function SHOW_ALL_HELP { # Show all the help for all the things
#     for i in "${MAXXMODULES[@]}"
#     do
#         if [ $i != 'HELP' ]
#         then
#             echo -ne " * $i \n"
#             cat THEMAXX/$OS/$i | grep "{ #" | sort | sed -e 's/{ #/- /g' -e 's/function /\t/g'
#         fi
#     done
# }

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
    echo
    read -t $SAFETY_TIMEOUT_SECONDS -p "Press any key within $SAFETY_TIMEOUT_SECONDS seconds to confirm that you still have connectivity... " || CLEAR
}


# PRECONFIGURED FIREWALLS FOR FREE


function IRC_FIREWALL {
    CLEAR
    ALLOW_STATES
    ALLOW_LOCALHOST
    ALLOW_PORTS
    BLOCK_BOGUS_TCP_FLAGS
    PORTSCAN_PROTECT
    BLOCK_BOGONS
    ICMP_BLOCK $ETH
    IPSET_SAVE_FILE
    DL_ALL_LISTS
    LOAD_BL
    DROP_EVERYTHING

    if [ "$USE_IPV6" = "1" ]; then
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
    SAFETY_TIMEOUT
}

function BASIC_FIREWALL {
    CLEAR
    ALLOW_STATES
    ALLOW_LOCALHOST
    ALLOW_PORTS
    DL_ALL_LISTS
    IPSET_SAVE_FILE
    LOAD_BL
    DROP_EVERYTHING
    SAFETY_TIMEOUT
}