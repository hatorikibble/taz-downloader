#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 6;

use_ok('TazDownloader') || print "Bail out!\n";

use Date::Format;

my $non_date = '32.12.2013';
my $TazDownloader = TazDownloader->new( User     => 'dummy',
                                        Password => 'dummy',
                                        Date     => $non_date
);

is( $TazDownloader->Today,
    time2str( '%d.%m.%Y', time ),
    "TazDownloader's 'Today' is really today" );
ok( defined( $TazDownloader->TazDownloadUrl ), "TazDownloadUrl in Object" );
ok( defined( $TazDownloader->TazRssUrl ),      "TazRssUrl in Object" );
ok( defined( $TazDownloader->{Issues} ),       "taz issues found" );
is( $TazDownloader->isAvailable, 'false', "No taz available for $non_date");
