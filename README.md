# Maxx Script Firewall Refurbish

https://twitch.tv/hughbord

## To Do

* COLOURS / ANSI / ASCII
* IP / Port white and nonwhite listing

* DOCKER support (workaround, after running iptables restart docker)
 * Docker command or script to generate the pure docker IPTABLES rule

* Yo check this out more later (Get ips range from a domain name)

## Systemd Unit file for Startup

```
[Unit]
Description = Apply my IPv4 Iptables Rules
Before=network.target

[Service]
Type=oneshot
ExecStart=/bin/sh -c "/usr/sbin/ipset restore < /home/ubuntu/maxx/all4.ipset && /sbin/iptables-restore < /etc/iptables.ipv4"

[Install]
WantedBy=multi-user.target
```

* Save file to `/etc/systemd/system/maxx-persist.service`
* Run `sudo systemctl enable maxx-persist`

## Crontab for startup

```
@reboot root /home/ubuntu/maxx/MAXX.sh BASIC_FIREWALL
```

Note: untested. 

#### Get IPS range from domain


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

# For the future

* Network packet capturing with the RPI
* Turn wlan0 into a wi fi hot spot (already have DHCP on ETHERNET)

# More cool streaming ideas for darkmage to copy

* Create a new ASCII creation program in javascript (vuejs)
* IRC bots to annoy people written in PHP
* ASCII / ANSI art integration into the maxx.sh

# References

* https://github.com/trimstray/iptables-essentials
* https://github.com/stamparm/ipsum
* https://github.com/firehol/blocklist-ipsets/wiki
* https://github.com/WaterByWind/edgeos-bl-mgmt/blob/master/fw-BlackList-URLs.txt
* https://www.spinics.net/lists/netfilter/msg17583.html
* https://git.tcp.direct/atmos/blocklist-ipset
* https://github.com/trimstray/iptables-essentials#block-an-ip-address
* https://github.com/messutied/colors.sh
* https://www.cyberciti.biz/faq/unix-linux-bash-script-check-if-variable-is-empty/
* https://github.com/tat3r