#!/usr/bin/env perl
# Mike Covington
# created: 2014-06-19
#
# Description:
#
use strict;
use warnings;
use lib 'lib';
use Log::History;

my $script = $0;
open my $self_fh, "<", $script or die $!;
1 while (<$self_fh>);
my $count = $.;

open my $linecount_fh, ">>", "linecount";
print $linecount_fh "The line count for $script is now: $count\n";
close $linecount_fh;
