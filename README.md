# Maxx Script Firewall Refurbish

https://twitch.tv/hughbord

https://github.com/trimstray/iptables-essentials#block-an-ip-address

## Next Stream

* Check the `all.ipset` file, if it's more than 12/24 hours old we
 * Get new lists
 * Restore from `all.ipset`

## To Do

* IPV6 Support

* After all the ips are in ipset we can do `ipset save > all.ipset`
* Persisting iptables rules and ipset lists on reboot
* Rate limiting / ddos protection amulets
* Better method to check our variables and stuff, exit gracefully
* Clean up file `blocklist.de.txt` afterwards
* IP / Port white and nonwhite listing
* Clean up the functions/scripts into their own files
* Filter out # comments and ipv6 from the ipv4 lists
* HINT: Cannot destroy lists when firewall is running or using them
* DOCKER support (workaround, after running iptables restart docker)
 * Docker command or script to generate the pure docker IPTABLES rule

* Check if binaries exist

```
if ! exists curl && exists egrep && exists grep && exists ipset && exists iptables && exists sed && exists sort && exists wc ; then
  echo >&2 "Error: searching PATH fails to find executables among: curl egrep grep ipset iptables sed sort wc"
  exit 1
fi
```

* Yo check this out more later (Get ips range from a domain name)

```
whois -h v4.whois.cymru.com " -v $(host facebook.com | grep "has address" | cut -d " " -f4)" | tail -n1 | awk '{print $1}'
for i in $(whois -h whois.radb.net -- '-i origin AS32934' | grep "^route:" | cut -d ":" -f2 | sed -e 's/^[ \t]*//' | sort -n -t . -k 1,1 -k 2,2 -k 3,3 -k 4,4 | cut -d ":" -f2 | sed 's/$/;/') ; do

  iptables -A OUTPUT -s "$i" -j REJECT

done
```

## Prizes available to solve these things 

Avoid using temporary file

```
*https://stackoverflow.com/questions/14205868/file-descriptor-permission-denied-with-bash-process-substitution
ipset restore <( wget -qO- "http://lists.blocklist.de/lists/all.txt"  | sed -e 's/^/add blocklist /'  )
wget -qO- "http://lists.blocklist.de/lists/all.txt"  | sed -e 's/^/add blocklist /' | bash


ipset -q flush ipsum
ipset -q create ipsum hash:net
for ip in $(curl --compressed https://raw.githubusercontent.com/stamparm/ipsum/master/ipsum.txt 2>/dev/null | grep -v "#" | grep -v -E "\s[1-2]$" | cut -f 1); do ipset add ipsum $ip; done
iptables -I INPUT -m set --match-set ipsum src -j DROP
```

# What are we doing

Few years I've developed the MAXXSUITE scripts which have some basic firewall and iplists.

Refurbishing this into a new script package.

# Done

* CSV files for the ip lists
* external data source for the lists and names <- already done this, csvs stuff today

# For the future

* Network packet capturing
* Turn wlan0 into a wi fi hot spot (already have DHCP on ETHERNET)

# More cool streaming ideas for darkmage to copy

* Create a new ASCII creation program in javascript (vuejs)
* IRC bots to annoy people written in PHP
* ASCII / ANSI art integration into the maxx.sh

# References

* https://github.com/trimstray/iptables-essentials
* https://github.com/stamparm/ipsum