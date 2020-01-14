#!/usr/bin/perl

use strict;
use warnings;

use IO::All qw/ io /;

my ($version) =
    ( map { m{\$VERSION *= *'([^']+)'} ? ($1) : () }
        io->file("./lib/WWW/Search/AOL.pm")->getlines() );

if ( !defined($version) )
{
    die "Version is undefined!";
}

my @cmd = (
    "git", "tag", "-m",
    "Tagging WWW-Search-AOL as $version",
    "releases/WWW-Search-AOL/$version",
);

print join( " ", map { /\s/ ? qq{"$_"} : $_ } @cmd ), "\n";
exec(@cmd);
