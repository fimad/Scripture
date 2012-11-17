#!/usr/bin/perl
use warnings;
use strict;

# Converts a terminal palette, in the format used by terminator into a series of
# kernel arguments that will set the initial tty text colors

if( $#ARGV != 0 ){
  die "usage: term2vt.pl 'palette'\n";
}

# Lists for each of the three kernel parameters controlling terminal color.
my @vt_red = ();
my @vt_green = ();
my @vt_blue = ();

# The colors in the palette are separated by colons. Split the colors
my @colors = split(/:/,$ARGV[0]);

# Grab the components from each color and place them in the @vt_* arrays.
for my $color (@colors) {
  push @vt_red, hex(substr $color, 1, 2);
  push @vt_green, hex(substr $color, 3, 2);
  push @vt_blue, hex(substr $color, 5, 2);
}

# Output the resulting kernel parameters
print "vt.default_red=", join(",", @vt_red);
print " vt.default_grn=", join(",", @vt_green);
print " vt.default_blu=", join(",", @vt_blue);
print "\n";
