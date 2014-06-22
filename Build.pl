#!/usr/bin/env perl
use strict;
use warnings FATAL => 'all';
use Module::Build;

# TODO: Add version specifications for requirements
# TODO: Add perl + version to requirements

my $module_file = "lib/Log/History.pm";

eval "use Pod::Markdown";
if ( ! $@ ) {
    require Pod::Markdown;
    my $readme_file = "README.md";
    pod2markdown( $module_file, $readme_file );
}

my $builder = Module::Build->new(
    module_name        => 'Log::History',
    dist_version_from  => $module_file,
    license            => 'perl',
    create_makefile_pl => 0,
    requires           => {
        "Carp"           => 0,
        "Cwd"            => 0,
        "File::Copy"     => 0,
        "File::Temp"     => 0,
        "POSIX"          => 0,
        "Scalar::Util"      => 0,
    },
    # build_requires => {
    #     'Test::More' => 0,
    # },
    configure_requires => {
        'Module::Build' => 0,
    },
    recommends => {
        # 'Devel::Cover'   => 0,    # To generate testing coverage report
        'Pod::Markdown'  => 0,    # To auto-generate README from POD markup
    },
);

$builder->create_build_script;

exit;

sub pod2markdown {
    my ( $pod_file, $markdown_file ) = @_;
    open my $markdown_fh, ">", $markdown_file
        or die "Cannot open $markdown_file for writing: $!";
    my $parser = Pod::Markdown->new();
    $parser->output_fh($markdown_fh);
    $parser->parse_file($pod_file);
    close $markdown_fh;
}
