#!/usr/bin/env perl

use strict;  use warnings;

BEGIN {
    if ($ENV{EMACS}) {
        chdir '..' until -d 't';
        use lib 'lib';
    }
}

################################################################################
use Test::More qw(no_plan);

use Travis::Test;

is Travis::Test::banana(), 25, "A banana costs HOW MUCH!!!1!";

done_testing;
