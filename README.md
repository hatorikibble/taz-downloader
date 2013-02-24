# NAME

TazDownloader - Download the taz e-paper!

# VERSION

Version 0.01

# SYNOPSIS

This module checks for available taz e-paper issues and can download them
in various formats

    use TazDownloader;

    my $T=TazDownloader->new(User=>'foo', Password=>'bar');

    print $T->isAvailable(Date=>'Tomorrow'); # "true|false"

    print $T->isAvailable(Date=>'Today'); # "true|false"

    print $T->isAvailable(Date=>'23.02.2013'); # "true|false"

    print $T->isAvailable(Date=>'23.02.2013', Format=>'ascii'); # "true|false"



    $T->downloadIssue(TargetDir=>"/tmp", 
                      Format=>'epub\_faks', 
                      Date=>'23.02.2013' 
                     );

## BUILD

Constructor, also get RSS-Feed of available issues

## isAvailable(Date=>'Today')

checks if taz issue is available for `Date`

__Params__

- Date

can be `Today`, `Tomorrow` or `DD.MM.YYYY`

- Format (optional)

`epub\_txt`, `epub\_faks`, `ascii`, `mobi`, `pdf`, `html\_zip`, `ipad` ...
for a full list and description see source

## downloadIssue(Date=>'Tomorrow', Format=>'epub', TargetDir=>'.')

download the taz issue for the requested `Date` in `Format` to 
`TargetDir`

returns `OK` or dies with HTTP Error Code

__Params__

- Date

can be `Today`, `Tomorrow` or `DD.MM.YYYY`
default is `Today`

- Format

`epub\_txt`, `epub\_faks`, `ascii`, `mobi`, `pdf`, `html\_zip`, `ipad` ...
for a full list and description see source
default is `epub`

- TargetDir

directory in which the file is downloaded to

# AUTHOR

Peter Mayr, `<at.peter.mayr at gmail.com>`

# BUGS

Please report any bugs or feature requests to `at.peter.mayr at gmail.com`
or open an issue at ["/github.com/hatorikibble/taz-downloader/issues" in https:](http://search.cpan.org/perldoc?https:#/github.com/hatorikibble/taz-downloader/issues)




