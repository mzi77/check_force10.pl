#!/usr/bin/perl
# This  Plugin checks the hardware of DELL Networking Switches (fans, temp-sensor, power supply, cpu, memory)
# for FTOS version > 9.10
#
# Copyright (c) 2016 Martin Zidek martin.zidek@gmail.com
# Copyright (c) 2009 Gerrit Doornenbal, g(dot)doornenbal(at)hccnet(dot)nl
# Many thanks to Sascha Tentscher , who provided a very good example 
#  with his 3com plugin!
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-130

use strict;
use Net::SNMP;
use Getopt::Long;

if ($#ARGV == -1)
{
  print_help();
}

my %status       = (  'UNKNOWN'  => '-1',
                      'OK'       => '0',
                      'WARNING'  => '1',
                      'CRITICAL' => '2' );

my %unitstates   = (  '1' => 'unknown',
                      '2' => 'inactive',
                      '3' => 'OK',
                      '4' => 'loading' );

my %entitystate  = (  '1' => 'normal',
                      '2' => 'warning',
                      '3' => 'critical',
                      '4' => 'shutdown',
                      '5' => 'notPresent',
                      '6' => 'notFunctioning' );

my %cpuoidnames = (     '0' => 'Util5Sec',
		      '1' => 'Util1Min',
		      '2' => 'Util5Min',
		      '3' => 'UtilMemUsage',
		      '4' => 'FlashUsageUtil');
#
# cpu limits in percent
#
my $cpu_warning_default = 75;
my $cpu_critical_default = 85;
my $temp_warning_default = 57;
my $temp_critical_default = 62;

my $temp_warning = 0;
my $temp_critical= 0;
my $cpu_warning = 0;
my $cpu_critical = 0;


sub print_help()
{
  print "Usage: check_dell_powerconnect -H host -C community\n";
  print "Options:\n";
  print " -H STRING or IPADDRESS\n";
  print "   Check interface on the indicated host.\n";
  print " -C STRING\n";
  print "   Community-String for SNMP-Walk.\n";
  print " -tw INT\n";
  print "   Temperature warning treshold.\n";
  print " -tc INT\n";
  print "   Temperature critical treshold.\n";
  print " -cw INT\n";
  print "   CPU load  warning treshold.\n";
  print " -cc INT\n";
  print "   CPU load critical treshold.\n";
  print "This  Plugin checks the hardware of DELL Networking FTOS 9.10 and later\nswitches (fans, temp-sensor, power supply,cpu and memory), and probably\nmore models! (not tested)\n\n";
  exit($status{"UNKNOWN"});
}
sub get_snmp_session
{
  my $ip        = $_[0];
  my $community = $_[1];
  my ($session, $error) = Net::SNMP->session(
             -hostname  => $ip,
             -community => $community,
             -port      => 161,
             -timeout   => 1,
             -retries   => 3,
             -translate => [-timeticks => 0x0] #schaltet Umwandlung von Timeticks in Zeitformat aus
              );
  return ($session, $error);
}

sub get_cpustate_string
{
  my $cpu = $_[0];
  my $value_name = $_[1];
  my $load = $_[2];
  my $state='normal';
  if($load > $cpu_critical)
  {
  	$state='critical̈́';
  }
  if($load > $cpu_warning)
  {
  	$state='WARNING';
  }
  return("CPU". $cpu ."_" . $value_name."=" .$state);
 }
sub get_cpuperf_string
{
  my $cpu = $_[0];
  my $value_name = $_[1];
  my $load = $_[2];
  return("CPU". $cpu . "_" . $value_name ."=".$load."%;".$cpu_warning.";".$cpu_critical);
}
sub get_temp_string
{
  my $temp = $_[0];
  my $state = 'normal';
  if($temp > $temp_critical)
  {
  	$state='critical̈́';
  }
  if($temp > $temp_warning)
  {
  	$state='WARNING';
  }
  return("Temp=" .$state);
}
sub get_tempperf_string
{
  my $temp = $_[0];
  return("Temp=".$temp."C;".$temp_warning.";".$temp_critical);
}


sub close_snmp_session
{
  my $session = $_[0];
  
  $session->close();
}
sub get_snmp_request
{
  my $session = $_[0];
  my $oid     = $_[1];
  return $session->get_request($oid);
}
sub get_snmp_table
{
  my $session = $_[0];
  my $oid     = $_[1];
  return $session->get_table($oid);
}


my $ip='';
my $community='public';
my $man = 0;
my $help = 0;

GetOptions ('H=s' => \$ip, 
 	     'help|?' => \$help, man => \$man,
            'C:s' => \$community,
	    'tw:i' => \$temp_warning,
	    'tc:i' => \$temp_critical,
	    'cw:i' => \$cpu_warning,
	    'cc:i' => \$cpu_critical) or print_help();

if ($temp_warning == 0) 
{
	 $temp_warning = $temp_warning_default;
 }
if ($temp_critical == 0) 
{	
	$temp_critical = $temp_critical_default;
}
if ($cpu_warning == 0) 
{
	$cpu_warning = $cpu_warning_default;
}
if ($cpu_critical == 0) 
{
	$cpu_critical = $cpu_critical_default;
}
#my ($ip, $community) = pars_args();
my ($session, $error)       = get_snmp_session($ip, $community);

my $oid_unitdesc    = ".1.3.6.1.4.1.674.10895.3000.1.2.100.1.0"; 
my $oid_unitstate   = ".1.3.6.1.4.1.674.10895.3000.1.2.110.1.0"; 
#my $oid_tempstatus	= ".1.3.6.1.4.1.89.53.15.1.9.1";
my $oid_tempstatus	= ".1.3.6.1.4.1.6027.3.26.1.3.4.1.13.1";
my $oid_fanname     = ".1.3.6.1.4.1.674.10895.3000.1.2.110.7.1.1.2";
my $oid_fanstate    = ".1.3.6.1.4.1.674.10895.3000.1.2.110.7.1.1.3";
my $oid_psuname     = ".1.3.6.1.4.1.674.10895.3000.1.2.110.7.2.1.2";
my $oid_psustate    = ".1.3.6.1.4.1.674.10895.3000.1.2.110.7.2.1.3";
my $oid_dellNetCpuUtilTable	    = ".1.3.6.1.4.1.6027.3.26.1.4.4";
#DELL-NETWORKING-CHASSIS-MIB::dellNetCpuUtil5Sec.stack.1.1 = Gauge32: 25 percent
#DELL-NETWORKING-CHASSIS-MIB::dellNetCpuUtil1Min.stack.1.1 = Gauge32: 16 percent
#DELL-NETWORKING-CHASSIS-MIB::dellNetCpuUtil5Min.stack.1.1 = Gauge32: 13 percent
#DELL-NETWORKING-CHASSIS-MIB::dellNetCpuUtilMemUsage.stack.1.1 = Gauge32: 41 percent
#DELL-NETWORKING-CHASSIS-MIB::dellNetCpuFlashUsageUtil.stack.1.1 = Gauge32: 2 percent
#.1.3.6.1.4.1.6027.3.26.1.4.4.1.1    ,dellNetCpuUtil5Sec                           ,LEAF  ,Gauge32,read-only
#.1.3.6.1.4.1.6027.3.26.1.4.4.1.1.2.1.1 = Gauge32: 17 percent
#.1.3.6.1.4.1.6027.3.26.1.4.4.1.4.2.1.1 = Gauge32: 14 percent
#.1.3.6.1.4.1.6027.3.26.1.4.4.1.5.2.1.1 = Gauge32: 14 percent
#.1.3.6.1.4.1.6027.3.26.1.4.4.1.6.2.1.1 = Gauge32: 41 percent
#.1.3.6.1.4.1.6027.3.26.1.4.4.1.7.2.1.1 = Gauge32: 2 percent
my %result    = %{get_snmp_request($session, $oid_unitdesc)};
my $unitdesc  = $result{$oid_unitdesc};
   %result    = %{get_snmp_request($session, $oid_unitstate)};
my $unitstate = $result{$oid_unitstate};
#check temperature if possible (Only PC35XX ..??)
#my $temperature = "";
#    if ($unitdesc =~ /35/i) {
my $temperature = "";
   %result    = %{get_snmp_request($session, $oid_tempstatus)};
my $tempstatus = $result{$oid_tempstatus};
$temperature .=$tempstatus;	
#    }

my %result1    = %{get_snmp_table($session, $oid_fanname)};
my %result2   = %{get_snmp_table($session, $oid_fanstate)};
my %result3   = %{get_snmp_table($session, $oid_psuname)};
my %result4   = %{get_snmp_table($session, $oid_psustate)};
my %cpu_result   = %{get_snmp_table($session, $oid_dellNetCpuUtilTable)};

my $counter = 0;
my $counter1 = 0;
my @fanname;
my @fanstate;
my @psuname;
my @psustate;
my $cpu_count = 0;
my @cpustate;
my $perf;
#find fanstates
  foreach my $oid(sort keys %result1)
  {
    $fanname[$counter] = $result1{$oid};
    $counter++;
  }
    $counter = 0;
  foreach my $oid(sort keys %result2)
  {
    $fanstate[$counter] = $result2{$oid};
    $counter++;
  }
#find PSU states
  $counter1 = 0;
  foreach my $oid(sort keys %result3)
  {
    $psuname[$counter1] = $result3{$oid};
    $counter1++;
  }
  $counter1 = 0;
  foreach my $oid(sort keys %result4)
  {
    $psustate[$counter1] = $result4{$oid};
    $counter1++;
  }
  $cpu_count = 0;
  foreach my $oid(sort keys %cpu_result)
  {
    $cpustate[$cpu_count] = $cpu_result{$oid};
    $cpu_count++;
  }


  close_snmp_session($session);  

# Create output line  
my $string = $unitdesc.": ".$unitstates{$unitstate};
  for(my $i =0; $i<$counter; $i++)
  {
	  if ($fanstate[$i] !=5)
	{
  $string .= ", ";
  $string .= $fanname[$i]." ".$entitystate{$fanstate[$i]};
	}
  }
  for(my $i =0; $i<$counter1; $i++)
  {
    if ($psustate[$i] !=5)
	{
    $string .= ", ";
    $string .= $psuname[$i]." ".$entitystate{$psustate[$i]};
	}
  }


for(my $i =0; $i<$cpu_count; $i=$i+5)
  {
   $perf .= "|";
   my $cpu=0;
   foreach my $index(sort keys %cpuoidnames)
   {
   	$string .=  ", " . get_cpustate_string($cpu,$cpuoidnames{$index},$cpustate[$i+$index]);	
   	$perf .=  get_cpuperf_string($cpu,$cpuoidnames{$index},$cpustate[$i+$index]) . " ";	
   }
   $cpu++;
  }
  $string .= ', '.get_temp_string($temperature);
  $perf .=  get_tempperf_string($temperature);	

#create correct exit state  
  my $state = "OK";
  if($string =~/UNKNOWN/)
  {
    $state = "UNKNOWN";
  }
  if($string =~/inactive|notpresent|WARNING/)
  {
    $state = "WARNING";
  }
  if($string =~/critical|shutdown|Error/)
  {
    $state = "CRITICAL";
  }
print $string.$perf."\n";
exit($status{$state});

