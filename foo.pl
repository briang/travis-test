#!/opt/perlbrew/perls/dev/bin/perl

use 5.008;

#:TAGS:

use strict;  use warnings;

use Data::Dump; # XXX
################################################################################
use Capture::Tiny 'capture';
use CPAN::Changes;
use Getopt::Long::Descriptive;
use Time::Piece;

( my $APP_NAME = $0 ) =~ s|.*/||;

my ($opt, $usage) = describe_options(
    "$APP_NAME %o",
    [ 'branch|B=s',  'the branch to use', { default => 'master' } ],
    [ 'bump|b=s',    'the version bump between versions', { default => '0.001' }, ],
    [ 'changes|c=s', 'the name of the file containing the changelog', { default  => 'Changes' } ],
    [ 'dry-run|d',   'show what would happen, without making changes' ],
    [ 'edit|e=s',    'launch editor after updating changelog', { default => $ENV{VISUAL} || $ENV{EDITOR} } ],
#   [ 'force',       'force update even if errors' ],
#   [ 'info|i',      'information about the repo and changelog' ],
    [ 'suffix|s=s',  'suffix to use for backup file', { default => '.bak' } ],
    [ 'verbose|v',   'print extra stuff' ],
    [],
    [ 'help',      'print usage message and exit', { shortcircuit => 1 } ],

    { show_defaults => 1 }
);

print($usage->text), exit if $opt->help;

=head2 git

    @git_output_lines  = git($command, @options) # 1
    $git_output_string = git($command, @options) # 2

=cut

sub git {
    my @cmd = ( 'git', @_ );
    print "@cmd\n" if $opt->verbose;
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

=head2 is_dirty

      @list_of_dirty_files = is_dirty() # 1
      $repo_is_dirty       = is_dirty() # 2

=cut

sub is_dirty { grep { ! /^##/ } git('status', '--porcelain') }
################################################################################
# die qq[Working tree is not clean (see git status for details)\n]
#   if is_dirty(); # XXX

my $last_version_from_git = (get_tags)[0]->{text};
my $new_version           = $last_version_from_git + $opt->bump;
my $date                  = localtime->ymd();
my @commit_messages       = map {
    s/^\S*\s+//; $_
} git('log', 'master', '--oneline', "$last_version_from_git..");

print qq[No commits since last tagged version\n] and exit
  unless @commit_messages;

my $changes = CPAN::Changes->load( $opt->changes );
my $last_version_from_changes = ($changes->releases)[-1]->version;
die << "EOM" unless $last_version_from_git == $last_version_from_changes;
Version mismatch:
    Changes: $last_version_from_changes
        Git: $last_version_from_git
EOM

my $release = CPAN::Changes::Release->new(
    version => $new_version,
    date    => $date,
    changes => { "" => \@commit_messages },
);

$changes->add_release( $release );

if ($opt->dry_run) {
    print STDOUT $changes->serialize;
    exit;
}

my $changes_old = $opt->changes . $opt->suffix;
rename $opt->changes, $changes_old
  or die qq[cannot rename '$opt->changes': $!\n];

open my $OUT, ">", $opt->changes
  or die qq[cannot open '$opt->changes': $!\n];
print $OUT $changes->serialize;
close $OUT;
