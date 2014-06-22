#!/usr/bin/env perl
# Mike Covington
# created: 2014-03-10
#
# Description:
#
use strict;
use warnings;
use File::Temp ();
use FindBin qw($Bin);
use lib "$Bin/../lib";
use Test::More tests => 3;

BEGIN {
    require_ok('Log::History')
        or BAIL_OUT "Can't load Log::History";
}

subtest 'Time tests' => sub {
    plan tests => 3;

    my $now = Log::History::_now();

    like(
        $$now{'timestamp'},
        qr/2\d{3}-[01][0-9]-[0-3][0-9]\s[0-2][0-9]:[0-6][0-9]:[0-6][0-9]/,
        "Test timestamp"
    );
    like( $$now{'seconds'}, qr/\d{10}/, "Test seconds" );

    my $start_seconds  = 1000000;
    my $finish_seconds = 3356330;
    my $elapsed = Log::History::_elapsed( $start_seconds, $finish_seconds );
    is( $elapsed, '654:32:10', 'Test elapsed time' );
};

subtest 'Logging tests' => sub {
    plan tests => 6;

    my $log_limit = 2;
    my $script_content = <<EOF;
#!/usr/bin/env perl
use strict;
use warnings;
use lib "$Bin/../lib";
use Log::History '$log_limit';
EOF


    my ( $script_out_fh, $script_filename ) = File::Temp::tempfile();
    print $script_out_fh $script_content;
    close $script_out_fh;

    my @params;
    unshift @params, "";
    compare_script_and_log( $script_filename, $script_content, \@params,
        "1st Log (w/o parameters)", $log_limit );

    unshift @params, "--opt 1 --param 2";
    compare_script_and_log( $script_filename, $script_content, \@params,
        "2nd Log (has parameters)", $log_limit );

    unshift @params, "over log limit of $log_limit";
    compare_script_and_log( $script_filename, $script_content, \@params,
        "3rd Log (over log limit)", $log_limit );

    unlink $script_filename;
};

exit;

sub compare_script_and_log {
    my ( $script_filename, $script_content, $params, $test_name, $log_limit )
        = @_;

    while ( scalar @$params > $log_limit ) {
        pop @$params;
    }

    system("perl $script_filename $$params[0]");
    open my $script_in_fh, "<", "$script_filename";
    my $script_in = join "", <$script_in_fh>;
    close $script_in_fh;

    my ( $pre_log, $log )
        = $script_in =~ /(^.*use Log::History '2';\n)(.*$)/s;
    is( $pre_log, $script_content, "$test_name: pre-log" );

    my $log_regex
        = '#\d{4}-\d{2}-\d{2}\s\d{2}:\d{2}:\d{2}\s\(\d{2,}:\d{2}:\d{2}\)\sin\s[^\s]+: '
        . $script_filename;
    my $expected_log = '^';
    for (@$params) {
        $expected_log .= $log_regex;
        $expected_log .= $_ eq "" ? "\n" : " $_\n";
    }
    $expected_log .= '$';
    $log_regex = qr/$expected_log/;
    like( $log, $log_regex, "$test_name: log" );
}

