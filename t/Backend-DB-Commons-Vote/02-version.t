use strict;
use warnings;

use Backend::DB::Commons::Vote;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Backend::DB::Commons::Vote::VERSION, 0.01, 'Version.');
