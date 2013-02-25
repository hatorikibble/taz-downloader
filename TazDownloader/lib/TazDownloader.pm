package TazDownloader;


=head1 NAME

TazDownloader - Download the taz e-paper!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

This module checks for available taz e-paper issues and can download them
in various formats

    use TazDownloader;

    my $T=TazDownloader->new(User=>'foo', Password=>'bar');

    print $T->isAvailable(Date=>'Tomorrow'); # "true|false"

    print $T->isAvailable(Date=>'Today'); # "true|false"

    print $T->isAvailable(Date=>'23.02.2013'); # "true|false"

    print $T->isAvailable(Date=>'23.02.2013', Format=>'ascii'); # "true|false"


    $T->downloadIssue(TargetDir=>"/tmp", 
                      Format=>'epub_faks', 
                      Date=>'23.02.2013' 
                     );

=cut

use strict;
use warnings;

use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Params::Validate;

use Switch;
use Date::Calc qw (Add_Delta_Days);
use Date::Format;
use LWP::Simple;
use XML::RSS::Parser;
use File::Spec;


    my %formatStrings = ( 'ASCII nur Text'               => 'ascii',
                    'ASCII nur Text, ZIP-Datei'    => 'ascii_zip',
                    'HTML ZIP-Datei'               => 'html_zip',
                    'iPaper'                       => 'ipad',
                    'Mobipocket nur Text'          => 'mobi_txt',
                    'Mobipocket mit Faksimiles'    => 'mobi_faks',
                    'E-Book mit Faksimiles'        => 'epub_faks',
                    'E-Book nur Text'              => 'epub_txt',
                    'PDF'                          => 'pdf',
                    'PDF einzelnen Seiten gezippt' => 'pdf_zip'
    );
    my %formatIds = reverse(%formatStrings);


subtype 'TazFormat',
 as 'Str',
 where { exists($formatIds{$_}) },
 message { "Format has to be one of ".join(", ",keys(%formatIds))."!" };

subtype 'TazDate',
  as 'Str',
  where { $_ =~ /^(Today|Tomorrow|\d{2}.\d{2}\.\d{4})$/ },
  message {"Date must be one of 'Today','Tomorrow' or 'DD.MM.YYYY'" };

has 'TazDownloadUrl' =>
    ( is => 'ro', isa => 'Str', default => 'dl.taz.de/taz/abo/get.php' );
has 'TazRssUrl' =>
    ( is => 'ro', isa => 'Str', default => 'http://dl.taz.de/abo.rss' );

has 'User'     => ( is => 'rw', isa => 'Str', required => 1 );
has 'Password' => ( is => 'rw', isa => 'Str', required => 1 );
has 'Format' =>
    ( is => 'rw', isa => enum( [qw( EPub Txt )] ), default => 'EPub' );

has 'Today' => ( is      => 'ro',
                 isa     => 'Str',
                 default => sub { return time2str( '%d.%m.%Y', time ); }
);

has 'Tomorrow' => (is => 'ro',
                  isa => 'Str',
                  default => sub { 
my ($y,$m,$d) = Add_Delta_Days(time2str('%Y',time),
                               time2str('%L',time),
                               time2str('%d',time),
                               1);
return sprintf('%02d',$d).".".sprintf('%02d',$m).".".$y;
});



=head2 BUILD

Constructor, also get RSS-Feed of available issues

=cut

sub BUILD {
    my $self     = shift;
    my $parser   = undef;
    my $feed     = undef;
    my $title    = undef;
    my $link     = undef;
    my $size     = undef;
    my $format   = undef;
    my $date     = undef;
    my $filename = undef;
    my $issues   = undef;


    $parser = XML::RSS::Parser->new();
    $feed   = $parser->parse_uri( $self->TazRssUrl );
     
    foreach my $item ( $feed->query('//item') ) {
        $title = $item->query('title')->text_content;
        $link  = $item->query('link')->text_content;
        if ( $title
             =~ /^taz vom (\d+)\.(\d+)\.(\d{4}) als (.*?) (\d.*? (K|M)B)$/ )
        {
            $date
                = sprintf( '%02d', $1 ) . "."
                . sprintf( '%02d', $2 ) . "."
                . $3;
            $format = $4;
            if ( $format =~ /iPaper/ ) {    # hack wegen umlaut im titel
                $format = "iPaper";
            }
            $size = $5;
            if ( exists( $formatStrings{$format} ) ) {
                $issues->{$date}->{ $formatStrings{$format} }->{size} = $size;
                $issues->{$date}->{ $formatStrings{$format} }->{url}  = $link;
                if ( $link =~ /\/([^\/]+?)$/ ) {
                    $issues->{$date}->{ $formatStrings{$format} }->{filename}
                        = $1;
                }
                else {
                    die "could not determine filename from URL: " . $link;
                }
            }
            else {
                warn "unknown Format: $format";
            }
        } ## end if ( $title =~ ...)
        else {
            die "can't parse RSS-Item '$title' from Feed " . $self->TazRssUrl;
        }

    } ## end foreach my $item ( $feed->query...)
    $self->{Issues} = $issues;

} ## end sub BUILD

=head2 isAvailable(Date=>'Today')

checks if taz issue is available for C<Date>

B<Params>

=over 2

=item Date

can be C<Today>, C<Tomorrow> or C<DD.MM.YYYY>

=item Format (optional)

C<epub_txt>, C<epub_faks>, C<ascii>, C<mobi>, C<pdf>, C<html_zip>, C<ipad> ...
for a full list and description see source

=back

=cut

sub isAvailable {
    my $self = shift;
    my %p    = validated_hash( \@_,
                            'Date' => { isa => 'TazDate', default => 'Today' },
                            'Format' => { isa => 'TazFormat', optional=> 1 },
    );
    my $date = undef;

    switch ( $p{Date} ) {
        case "Today"    { $date = $self->Today; }
        case "Tomorrow" { $date = $self->Tomorrow; }
        else            { $date = $p{Date}; }
    }

    if ( defined( $p{Format} ) ) {    # check also if format available
        if ( defined( $self->{Issues}->{$date}->{ $p{Format} } ) ) {
            return "true";
        }

    }
    else {                            # just the date
        if ( defined( $self->{Issues}->{$date} ) ) {
            return "true";
        }
    }
    return "false";

} ## end sub isAvailable

=head2 downloadIssue(Date=>'Tomorrow', Format=>'epub', TargetDir=>'.')

download the taz issue for the requested C<Date> in C<Format> to 
C<TargetDir>

returns C<OK> or dies with HTTP Error Code

B<Params>

=over 2

=item Date

can be C<Today>, C<Tomorrow> or C<DD.MM.YYYY>
default is C<Today>

=item Format

C<epub_txt>, C<epub_faks>, C<ascii>, C<mobi>, C<pdf>, C<html_zip>, C<ipad> ...
for a full list and description see source
default is C<epub>

=item TargetDir

directory in which the file is downloaded to

=back

=cut

sub downloadIssue {
    my $self = shift;
    my %p = validated_hash(
                          \@_,
                          'Date' => { isa => 'TazDate', default => 'Today' },
                          'Format' => { isa => 'TazFormat', default => 'epub' },
                          'TargetDir' => { isa => 'Str', required => 1 }
    );
    my $date        = undef;
    my $url         = undef;
    my $auth_string = undef;
    my $target_file = undef;
    my $status      = undef;

    switch ( $p{Date} ) {
        case "Today"    { $date = $self->Today; }
        case "Tomorrow" { $date = $self->Tomorrow; }
        else            { $date = $p{Date}; }
    }

    if ( -x $p{TargetDir} ) {
        if ( $self->isAvailable( Date => $p{Date}, Format => $p{Format} ) eq
             'true' )
        {

            $url         = $self->{Issues}->{$date}->{ $p{Format} }->{url};
            $auth_string = $self->User . ":" . $self->Password . "\@";

            $url =~ s/^https:\/\//https:\/\/$auth_string/o;

            $target_file = File::Spec->catfile( $p{TargetDir},
                         $self->{Issues}->{$date}->{ $p{Format} }->{filename} );

            $status = getstore( $url, $target_file );
            if ( $status eq '200' ) {
                return "OK";
            }
            else {
                die "Problem downloading "
                    . $url . " to "
                    . $target_file
                    . "! HTTP Status was "
                    . $status;
            }
        }
        else {
            die "Sorry! taz issue for "
                . $p{Date} . " in "
                . $p{Format}
                . " is not available!";
        }

    } ## end if ( -x $p{TargetDir} )
    else {
        die "Directory " . $p{TargetDir} . " is not writable!";
    }

} ## end sub downloadIssue

no Moose;

=head1 AUTHOR

Peter Mayr, C<< <at.peter.mayr at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<at.peter.mayr at gmail.com>
or open an issue at L< https://github.com/hatorikibble/taz-downloader/issues >


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc TazDownloader


You can also look for information at Github: 
L< https://github.com/hatorikibble/taz-downloader/issues >


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Peter Mayr.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1;    # End of TazDownloader
