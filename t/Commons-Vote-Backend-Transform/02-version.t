use strict;
use warnings;

use Commons::Vote::Backend::Transform;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Commons::Vote::Backend::Transform::VERSION, 0.01, 'Version.');
