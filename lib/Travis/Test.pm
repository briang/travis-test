package Travis::Test;

use 5.006;
use strict;
use warnings;

=head1 NAME

Travis::Test - A Test. For Travis. Duh.

=head1 VERSION

This document describes Travis::Test version 1

=head1 BUILD STATUS

=for html
<table>
  <tr>
    <td>Travis CI:</td>
    <td><img
      src="https://travis-ci.org/briang/travis-test.svg?branch=master"
      alt="TravisCI Status"/></td>
  </tr>
  <tr>
    <td>AppVeyor:</td>
    <td><img
      src="https://ci.appveyor.com/api/projects/status/github/briang/travis-test?branch=master&svg=true"
      alt="AppVeyor Status"/></td>
  </tr>
</table>

=cut

our $VERSION = '1.0';

sub banana {
    return 25;
}

1;
