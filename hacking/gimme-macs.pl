#!/usr/bin/perl
# Grabs mac address accociated with the supplied BSSID

die "Usage: $0 [bssid] \n" if @ARGV != 1;
my $target_bssid = $ARGV[0];

#arps seem like a good common type of packet to snarf
open(DUMP,"sudo tcpdump -i mon0 -e 'arp' 2> /dev/null |") or die("cannot capture.");

my $line;
my %seen = (); #already seen macs
while(defined( $line=<DUMP> )){
  chomp $line;
  
  if( $line =~ m/BSSID:([0-9a-f:]+) .+SA:([0-9a-f:]+)/ ){
    my ($bssid,$sa) = ($1,$2);
#print "'$bssid'\n'$target_bssid'\n\n";
    if( $bssid eq $target_bssid and not exists $seen{$sa} ){
      $seen{$sa} = 1;
      print "$sa\n";
    }
  }
}

close(DUMP);

