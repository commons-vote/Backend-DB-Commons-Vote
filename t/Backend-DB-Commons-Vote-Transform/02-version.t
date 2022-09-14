use strict;
use warnings;

use Backend::DB::Commons::Vote::Transform;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Backend::DB::Commons::Vote::Transform::VERSION, 0.01, 'Version.');
