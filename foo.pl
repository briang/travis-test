#!/usr/bin/env perl

#:TAGS:

use 5.022;

use strict;  use warnings;
use experimental qw(signatures);

use Data::Dump;
################################################################################
use Capture::Tiny 'capture';
use Hash::Util 'lock_hash'; # XXX
use Time::Piece;

my %opt = (
    branch       => 'master',
    changes_file => 'Changes',
    verbose      => 0,
    version_bump => 0.01,
);
lock_hash %opt;

sub git {
    my @cmd = ( 'git', @_ );
    say "@cmd" if $opt{verbose};
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

sub get_commits_XXXX() {
    my $s = git( 'rev-list', q[--header], $opt{branch} );

    map {
        my ($meta, $message) = split /\n\n/, $_, 2;
        my ($sha)            = $meta    =~ /(.*)/;
        my ($title)          = $message =~ /\s*(.*)/;
        { sha => $sha, title => $title }
    } split /\0/, $s;
}

sub is_dirty { grep { ! /^##/ } git('status', '--porcelain') }

die qq[Working tree is not clean (see git status for details)\n]
  if is_dirty();

my $previous_tag    = (get_tags())[0]->{text};
my $next_tag        = $previous_tag + $opt{version_bump};
my $date            = localtime->ymd();
my @commit_messages = git('log', 'master', '--oneline', "$previous_tag..");

my $changes = "$next_tag    $date\n" . join "\n", map {
      s/.*?\s/        - /;
      $_
  } @commit_messages;

my $changes_old = "$opt{changes_file}.bak";
rename $opt{changes_file}, $changes_old
  or die qq[cannot rename '$opt{changes_file}': $!\n];

open my $IN,  "<", $changes_old
  or die qq[cannot open '$changes_old': $!\n];
open my $OUT, ">", $opt{changes_file}
  or die qq[cannot open '$opt{changes_file}': $!\n];

print $OUT scalar readline $IN;
print $OUT "\n$changes\n";
print $OUT readline $IN;
