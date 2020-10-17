#!/bin/bash

function IPSET_MAKE { # Makes a new IPSET list.
    $IPSET_BIN -q create "$1" hash:net family inet hashsize 65536 maxelem 1048576 && \
    echo -ne "\t * Created $1 IPSet...\n" || $IPSET_BIN -q flush "$1"
}

# Get IP Blocklist IPV4 List
function GET_BLOCK_LIST { # Downloads iblocklist.com nonwhitelist (you need an account)
    wget -qO- "$2" | grep -v ":" |  sed  -e '/^#/ d' -e '/^\s*$/d' | sed -e "s/^/add $1 /" > "$TMP_DIR/$1.txt" && ipset restore < "$TMP_DIR/$1.txt" && rm "$TMP_DIR/$1.txt"
}

function GET_IP_BLOCKLIST {
    wget -qO- "http://list.iblocklist.com/?list=$2&fileformat=cidr&archiveformat=gz&username=$IPBLUSER&pin=$IPBLPIN" | gunzip | tail -n +2 | sed  -e '/^#/ d' -e '/^\s*$/d' |  awk '!x[$0]++' - | sed -e "s/^/add $1 /" > "$TMP_DIR/$1.txt" && ipset restore < "$TMP_DIR/$1.txt" && rm "$TMP_DIR/$1.txt"
}

function IPSET_SAVE_FILE {
    $IPSET_BIN save > "$IPLISTALL"
}

function IPSET_RESTORE_FILE {
    $IPSET_BIN restore < "$IPLISTALL"
}

BL_NAMES=()

function DL_ALL_LISTS { # Download all free and paid lists (will split this later)
    echo -en "\n * Downloading lists...\n"
    
    while read fdesc ffname fauthor furl
    do #	     4     1      3      2
        
        if [[ "$fdesc" == *"#"* ]] # If the first char is #, we will skip that list. Can comment out down or undesired lists
        then
            echo "" > /dev/null
        else
            echo -ne " * Saving $ffname...\n"
            
            # Make ipset name array here
            BL_NAMES+=("$ffname")
            
            if [[ "$fauthor" == "free" ]]
            then
                IPSET_MAKE $ffname                
                GET_BLOCK_LIST $ffname $furl $fauthor $fdesc
                
            else
                IPSET_MAKE $ffname
                
                if [ "$USE_IPV6" == "1" ]; then
                    IPSET_MAKE_V6 $ffname
                fi
                
                GET_IP_BLOCKLIST $ffname $furl $fauthor $fdesc
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

function LOAD_BL { # Restores nonwhitelist into the firewall
    echo " * Loading nonwhitelist..."
    for i in "${BL_NAMES[@]}"
    do
        echo -ne "\t * Restoring nonwhitelist $i..."
        $IPTABLES_BIN -A INPUT -m set --match-set "$i" src -j LOG --log-prefix "$i-bl-in: " --log-level 7
        $IPTABLES_BIN -A INPUT -m set --match-set "$i" src -j DROP
        
        $IPTABLES_BIN -A OUTPUT -m set --match-set "$i" dst -j LOG --log-prefix "$i-bl-out: " --log-level 7
        $IPTABLES_BIN -A OUTPUT -m set --match-set "$i" dst -j DROP
        
        $IPTABLES_BIN -A FORWARD -m set --match-set "$i" dst -j LOG --log-prefix "$i-bl-fwd-out: " --log-level 7
        $IPTABLES_BIN -A FORWARD -m set --match-set "$i" dst -j DROP
        
        $IPTABLES_BIN -A FORWARD -m set --match-set "$i" src -j LOG --log-prefix "$i-bl-fwd-in: " --log-level 7
        $IPTABLES_BIN -A FORWARD -m set --match-set "$i" src -j DROP
        
        echo -ne " restored.\n"
    done
}
