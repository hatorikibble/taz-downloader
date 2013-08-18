use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'TazDownloader',
    AUTHOR             => q{Peter Mayr <at.peter.mayr@gmail.com>},
    VERSION_FROM       => 'lib/TazDownloader.pm',
    ABSTRACT_FROM      => 'lib/TazDownloader.pm',
    LICENSE            => 'Artistic_2_0',
    PL_FILES           => {},
    MIN_PERL_VERSION   => 5.006,
    CONFIGURE_REQUIRES => { 'ExtUtils::MakeMaker' => 0, },
    BUILD_REQUIRES     => { 'Test::More' => 0, },
    PREREQ_PM          => {
        'Date::Calc'                   => '6.3',
        'Date::Format'                 => '2.24',
        'File::Spec'                   => '3.40',
        'LWP::Simple'                  => '6.00',
        'Moose'                        => '2.0602',
        'Moose::Util::TypeConstraints' => '2.0602',
        'MooseX::Params::Validate'     => '0.18',
        'Mozilla::CA'                  => 0,
        'Switch'                       => '2.16',
        'XML::Feed'                    => '0.51',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'TazDownloader-*' },
);

# perl -MLWP::UserAgent -e 'print $LWP::UserAgent::VERSION'
