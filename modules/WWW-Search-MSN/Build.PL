use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'WWW::Search::MSN',
    license             => 'bsd',
    dist_author         => 'Shlomi Fish <shlomif@iglu.org.il>',
    dist_version_from   => 'lib/WWW/Search/MSN.pm',
    requires => {
        'Encode' => 0,
        'HTML::TreeBuilder' => 0,
        'Scalar::Util' => 0,
        'Test::More' => 0,
        'WWW::Search' => 2.523,
        'WWW::Search::Test' => 2.265,
    },
    add_to_cleanup      => [ 'WWW-Search-MSN-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
