# Maxx Script Firewall Refurbish

https://twitch.tv/hughbord

https://github.com/trimstray/iptables-essentials#block-an-ip-address

## Next Stream

* Check the `all.ipset` file, if it's more than 12/24 hours old we
 * Get new lists
 * Restore from `all.ipset`

## To Do

* After all the ips are in ipset we can do `ipset save > all.ipset`
* Persisting iptables rules and ipset lists on reboot
* Rate limiting / ddos protection amulets
* IPV6 Support
* Whitelists and nonwhitelists (our own custom lists)
* Better method to check our variables and stuff, exit gracefully
* Clean up file `blocklist.de.txt` afterwards
* IP / Port white and nonwhite listing
* Clean up the functions/scripts into their own files
* Filter out # comments and ipv6 from the ipv4 lists
* HINT: Cannot destroy lists when firewall is running or using them

## Prizes available to solve these things 

Avoid using temporary file

```
*https://stackoverflow.com/questions/14205868/file-descriptor-permission-denied-with-bash-process-substitution
ipset restore <( wget -qO- "http://lists.blocklist.de/lists/all.txt"  | sed -e 's/^/add blocklist /'  )
wget -qO- "http://lists.blocklist.de/lists/all.txt"  | sed -e 's/^/add blocklist /' | bash
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