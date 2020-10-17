#!/bin/bash

function IPSET_MAKE6 { # Makes a new IPSET list IPV6.
    $IPSET_BIN -q create "$1-ip6" hash:net family inet6 hashsize 65536 maxelem 1048576 && \
    echo -ne "\t * Created $1-ip6 IPSet...\n" || $IPSET_BIN -q flush "$1-ip6"
}

# Get IP Blocklist IPV6 List
function GET_BLOCK_LIST6 { # Downloads iblocklist.com nonwhitelist (you need an account) IPv6
    wget -qO- "$2" | grep ":" |  sed  -e '/^#/ d' -e '/^\s*$/d' | sed -e "s/^/add $1-ip6 /" > "$TMP_DIR/$1.txt" && ipset restore < "$TMP_DIR/$1.txt" && rm "$TMP_DIR/$1.txt"
}

# Look into what IPv6 blocklist.com has and add it here

function IPSET_SAVE_FILE6 {
    $IPSET_BIN save > "$IPLISTALL"
}

function IPSET_RESTORE_FILE6 {
    $IPSET_BIN restore < "$IPLISTALL"
}

BL_NAMES6=()

function DL_ALL_LISTS6 { # Download all free and paid lists (will split this later)
    echo -en "\n * Downloading lists...\n"
    
    while read fdesc ffname fauthor furl
    do #	     4     1      3      2
        
        if [[ "$fdesc" == *"#"* ]] # If the first char is #, we will skip that list. Can comment out down or undesired lists
        then
            echo "" > /dev/null
        else
            echo -ne " * Saving $ffname...\n"
            
            # Make ipset name array here
            BL_NAMES6+=("$ffname")
            
            if [[ "$fauthor" == "free" ]]
            then
                IPSET_MAKE6 $ffname
                GET_BLOCK_LIST6 $ffname $furl $fauthor $fdesc
            fi
        fi
        
    done < "$IPLISTSCSV6"
    IFS=$OLDIFS
    
    # Reset script variables
    COUNTER=0
    J=0
    OLDIFS=$IFS
    IFS=,
}

function LOAD_BL6 { # Restores nonwhitelist into the firewall
    echo " * Loading IPV6 nonwhitelist..."
    for i in "${BL_NAMES6[@]}"
    do
        echo -ne "\t * Restoring nonwhitelist $i-ip6..."
        $IP6TABLES_BIN -A INPUT -m set --match-set "$i-ip6" src -j LOG --log-prefix "$i-ip6-bl-in: " --log-level 7
        $IP6TABLES_BIN -A INPUT -m set --match-set "$i-ip6" src -j DROP
        
        $IP6TABLES_BIN -A OUTPUT -m set --match-set "$i-ip6" dst -j LOG --log-prefix "$i-ip6-bl-out: " --log-level 7
        $IP6TABLES_BIN -A OUTPUT -m set --match-set "$i-ip6" dst -j DROP
        
        $IP6TABLES_BIN -A FORWARD -m set --match-set "$i-ip6" dst -j LOG --log-prefix "$i-ip6-bl-fwd-out: " --log-level 7
        $IP6TABLES_BIN -A FORWARD -m set --match-set "$i-ip6" dst -j DROP
        
        $IP6TABLES_BIN -A FORWARD -m set --match-set "$i-ip6" src -j LOG --log-prefix "$i-ip6-bl-fwd-in: " --log-level 7
        $IP6TABLES_BIN -A FORWARD -m set --match-set "$i-ip6" src -j DROP
        
        echo -ne " restored.\n"
    done
}
