package Log::History;
use strict;
use warnings;
use Cwd ();
use POSIX;
use File::Copy 'move';
use File::Temp ();

our $VERSION = 'pre-0.1.0';

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
my $log_limit = 5;

BEGIN {
    $start  = _now();
    $cwd    = getcwd();
    $script = $0;

    @arguments = @ARGV;
    for (@arguments) {
        $_ = "'$_'" if /\s/;
    }
}

END {
    my $finish = _now();
    my $elapsed = _elapsed( $$start{'seconds'}, $$finish{'seconds'} );
    my $log
        = "#$$start{'timestamp'} ($elapsed) in $cwd: $script @arguments\n";

    # read script and insert item in log
    my @code;
    open my $script_in_fh, "<", $script;
    flock( $script_in_fh, 2 ) or die $!;
    while ( my $line = <$script_in_fh> ) {
        push @code, $line;
        if ( $line =~ /use\s+@{[__PACKAGE__]}/ ) {
            push @code, $log;
            my $log_count = 1;
            while ( my $post_log_line = <$script_in_fh> ) {
                if ( $post_log_line
                    =~ /^#\d{4}-\d{2}-\d{2}\s\d{2}:\d{2}:\d{2}\s\(\d{2}:\d{2}:\d{2}\)\sin/
                    )
                {
                    $log_count++;
                    next if $log_count > $log_limit;
                }
                push @code, $post_log_line;
            }
        }
    }
    close $script_in_fh;

    # write script with newly logged item
    my ( $temp_fh, $temp_filename ) = File::Temp::tempfile();
    print $temp_fh @code;
    move $temp_filename, $script;
}

1;
