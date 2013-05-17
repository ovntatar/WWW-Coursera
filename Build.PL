use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'WWW::Coursera',
    license             => 'perl',
    dist_author         => q{Ovidiu Nita Tatar <ovn.tatar@gmail.com>},
    dist_version_from   => 'lib/WWW/Coursera.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'perl' 			=> 5.006,
	'WWW::Mechanize'	=> 1.72,
	'HTTP::Cookies'		=> 6.01,
	'Carp'			=> 1.26 
    },
    add_to_cleanup      => [ 'WWW-Coursera-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
