#!/opt/perlbrew/perls/dev/bin/perl

use 5.008;

#:TAGS:

use strict;  use warnings;

use Data::Dump; # XXX
################################################################################
use Capture::Tiny 'capture';
use CPAN::Changes;
use Hash::Util 'lock_hash'; # XXX
use Time::Piece;

my %opt = (
    branch       => 'master',
    changes_file => 'Changes',
    verbose      => 0,
    version_bump => 0.01,
);
lock_hash %opt;

=head2 git

    @git_output_lines  = git($command, @options) # 1
    $git_output_string = git($command, @options) # 2

=cut

sub git {
    my @cmd = ( 'git', @_ );
    print "@cmd\n" if $opt{verbose};
    my ($stdout, $stderr, $exit) = capture { system @cmd };
    die $stderr if $exit;
    return wantarray ? split(/\n/, $stdout) : $stdout;
}

=head2 get_tags

    @list_of_tags = get_tags()

=cut

sub get_tags {
    my @tags = git( 'tag', q[--format=%(objectname)~%(creatordate:iso)~%(refname:strip=2)] );
    return sort { -($a->{date} cmp $b->{date}) }
           map  { my @f = split /~/, $_, 3;
                  { sha => $f[0], date => $f[1], text => $f[2] }
           } @tags;
}

=head2 get_commits

    @list_of_commit_hashes = get_commits()

=cut

sub get_commits_XXXX {
    my $s = git( 'rev-list', q[--header], $opt{branch} );

    map {
        my ($meta, $message) = split /\n\n/, $_, 2;
        my ($sha)            = $meta    =~ /(.*)/;
        my ($title)          = $message =~ /\s*(.*)/;
        { sha => $sha, title => $title }
    } split /\0/, $s;
}

=head2 is_dirty

      @list_of_dirty_files = is_dirty() # 1
      $repo_is_dirty       = is_dirty() # 2

=cut

sub is_dirty { grep { ! /^##/ } git('status', '--porcelain') }
################################################################################
# die qq[Working tree is not clean (see git status for details)\n]
#   if is_dirty(); # XXX

my $last_version_from_git = (get_tags)[0]->{text};
my $new_version           = $last_version_from_git + $opt{version_bump};
my $date                  = localtime->ymd();
my @commit_messages       = map {
    s/^\S*\s+//; $_
} git('log', 'master', '--oneline', "$last_version_from_git..");

my $changes = CPAN::Changes->load( $opt{changes_file} );
my $last_version_from_changes = ($changes->releases)[-1]->version;
die << "EOM" unless $last_version_from_git == $last_version_from_changes;
Version mismatch:
    Changes: $last_version_from_changes
        Git: $last_version_from_git
EOM

my $release = CPAN::Changes::Release->new(
    version => $new_version,
    date => $date,
    changes => { "" => \@commit_messages },
);

$changes->add_release( $release );

my $changes_old = "$opt{changes_file}.bak";
rename $opt{changes_file}, $changes_old
  or die qq[cannot rename '$opt{changes_file}': $!\n];

open my $OUT, ">", $opt{changes_file}
  or die qq[cannot open '$opt{changes_file}': $!\n];

print $OUT $changes->serialize;
