#!/usr/bin/env perl

use strict;  use warnings;
use Test::More qw(no_plan);

use Travis::Test;

is Travis::Test::banana(), 25, "A banana costs HOW MUCH!!!1!";

done_testing;
