# check_force10.pl
Nagios plugin for Dell FTOS switches with FTOS version => 9.10

## usage
```
Usage: check_force10.pl -H host -C community [OPTIONS]
Options:
 -H STRING or IPADDRESS
   Check interface on the indicated host.
 -C STRING
   Community-String for SNMP-Walk.
 -tw INT
   Temperature warning treshold.
 -tc INT
   Temperature critical treshold.
 -cw INT
   CPU load  warning treshold.
 -cc INT
   CPU load critical treshold.
This  Plugin checks the hardware of DELL Networking FTOS 9.10 and later
switches (fans, temp-sensor, power supply,cpu and memory)

Tested on FTOS 9.10(0.1P3) on S4048 and S4810

This plugin works only for standalone switches, it won't work for stacks.

```
