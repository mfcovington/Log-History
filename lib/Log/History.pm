package Log::History;
use strict;
use warnings;
use Carp;
use Cwd ();
use POSIX;
use File::Copy 'move';
use File::Temp ();
use Scalar::Util 'looks_like_number';

our $VERSION = 'pre-0.1.0';

=head1 NAME

Log::History - Make self-documenting scripts that track their own execution history.

=head1 SYNOPSIS

Place the import statement for Log::History wherever you want the log to start.

    use Log::History;
    #2014-02-02 12:43:08 (00:00:48) in /path/to/workingdir: /path/to/script.pl --opt 1 --param 2
    ...

To limit the number of log entries, specify how many to keep.
The oldest entries are discarded.

    use Log::History '3';
    #2014-05-27 ...
    #2007-12-18 ...
    #1987-12-18 ...

=head1 DESCRIPTION

Log::History enables scripts to keep track of their own execution history.
Each log entry reports the date, start time, elapsed run time, working directory,
and a record of exactly how the script was called.

=head1 ACKNOWLEDGEMENTS

I was inspired to write this after recently re-reading Neil Bowers' post:
L<Identifying CPAN distributions you could help out with|http://blogs.perl.org/users/neilb/2012/12/modules-that-are-candidates-for-helping-out.html>.
In it, I found Tushar Murudkar's no-longer-maintained module L<Log::SelfHistory>.
I was intrigued since I had been working on L<Log::Reproducible|https://github.com/mfcovington/Log-Reproducible>.
I wanted to go in a different direction, so decided to start from scratch instead of trying to take over L<Log::SelfHistory>.

=head1 AUTHOR

Michael F. Covington <mfcovington@gmail.com>

=head1 SEE ALSO

L<Log::SelfHistory>, L<Log::Reproducible|https://github.com/mfcovington/Log-Reproducible>

=cut

sub _now {
    my %now;
    my @localtime = localtime;
    $now{'timestamp'} = strftime "%Y-%m-%d %H:%M:%S", @localtime;
    $now{'seconds'} = time();
    return \%now;
}

sub _elapsed {
    my ( $start_seconds, $finish_seconds ) = @_;

    my $secs = difftime $finish_seconds, $start_seconds;
    my $mins = int $secs / 60;
    $secs = $secs % 60;
    my $hours = int $mins / 60;
    $mins = $mins % 60;

    return join ":", map { sprintf "%02d", $_ } $hours, $mins, $secs;
}

my $start;
my $cwd;
my $script;
my @arguments;
my $log_limit;
my $original_permissions;
my $was_imported = 0;

sub import {
    ( my $pkg, $log_limit ) = @_;
    $was_imported = 1;

    @arguments = @ARGV;
    for (@arguments) {
        $_ = "'$_'" if /\s/;
    }
}

BEGIN {
    $start  = _now();
    $cwd    = getcwd();
    $script = $0;

    my $mode = ( stat($script) )[2];
    $original_permissions = sprintf "%04o", $mode & 07777;
}

END {
    return unless $was_imported;
    my $finish = _now();
    my $elapsed = _elapsed( $$start{'seconds'}, $$finish{'seconds'} );

    my $log = "#$$start{'timestamp'} ($elapsed) in $cwd: $script";
    $log .= " @arguments" if @arguments;
    $log .= "\n";

    if ( !defined $log_limit ) {
        $log_limit = -1;
    }

    if ( !defined $log_limit || !looks_like_number $log_limit ) {
        $log_limit = -1;
my $warning = <<EOF;
Warning: A non-numeric log limit was passed to Log::History while running $script
         I hope you are a history buff, because your history is now... UNLIMITED!
EOF
        warn $warning;
    }

    # read script and insert item in log
    my @code;
    my $log_regex
        = qr/^#\d{4}-\d{2}-\d{2}\s\d{2}:\d{2}:\d{2}\s\(\d{2,}:\d{2}:\d{2}\)\sin/;
    open my $script_in_fh, "<", $script;
    flock( $script_in_fh, 2 ) or die $!;
    while ( my $line = <$script_in_fh> ) {
        push @code, $line;
        if ( $line =~ /use\s+@{[__PACKAGE__]}/ ) {
            push @code, "\n" unless $line =~ /\n$/;
            push @code, $log;
            my $log_count = 1;
            while ( my $post_log_line = <$script_in_fh> ) {
                if ( $post_log_line =~ /$log_regex/ ) {
                    $log_count++;
                    next if $log_count > $log_limit && $log_limit != -1;
                }
                push @code, $post_log_line;
            }
        }
    }
    close $script_in_fh;

    # write script with newly logged item
    my ( $temp_fh, $temp_filename )
        = File::Temp::tempfile( DIR => $ENV{'HOME'} );
    print $temp_fh @code;
    move $temp_filename, $script;
    chmod oct($original_permissions), $script;
}

1;
