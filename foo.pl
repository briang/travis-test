#!/usr/bin/env perl

#:TAGS:

use 5.022;

use strict;  use warnings;  use autodie qw/:all/;
use experimental qw(signatures);

use Data::Dump;
################################################################################
use Capture::Tiny 'capture';
use Hash::Util 'lock_hash';

my %opt = (
    branch => 'master',
);
lock_hash %opt;

sub git {
    my @cmd = ( 'git', @_ );
    say "@cmd";
    my ($stdout, $stderr, $exit) = capture { system @cmd };
    die $stderr if $exit;
    return wantarray ? split(/\n/, $stdout) : $stdout;
}

sub get_tags() {
    my @tags = git( 'tag', q[--format=%(objectname)~%(creatordate:iso)~%(refname:strip=2)] );
    return sort { -($a->{date} cmp $b->{date}) }
           map  { my @f = split /~/, $_, 3;
                  { sha => $f[0], date => $f[1], text => $f[2] }
           } @tags;
}

sub get_commits() {
    git( 'rev-list', q[--header], $opt{branch} );
}

dd get_commits();
