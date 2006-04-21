use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'WWW::Search::AOL',
    license             => 'bsd',
    dist_author         => 'Shlomi Fish <shlomif@iglu.org.il>',
    dist_version_from   => 'lib/WWW/Search/AOL.pm',
    requires => {
        'Test::More' => 0,
        'WWW::Search' => 2.523,
        'WWW::Search::Test' => 2.265,
        'HTML::TreeBuilder' => 0,
        'Scalar::Util' => 0,
    },
    add_to_cleanup      => [ 'WWW-Search-AOL-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
