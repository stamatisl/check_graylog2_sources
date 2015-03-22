# check_graylog2_sources
A simple nagios script to check if all your hosts sources are logging well on graylog2

EXAMPLE
Usage: ./check_graylog2_sources.pl -H 192.168.1.1 -P 12900 -u admin -p password -t 24 -s 60 -w 1 -c 2 -v

-H = Hostname or IP
-P = Port number
-u = username
-p = password
-t = time in hours (24 for a day)
-s = number of hosts (sources) must logging
-w = number of host that are missing to return warning
-c = number of host that are missing to return critical
-v = verbose (use this switch to check your current amount of hosts, before you start using this check)
