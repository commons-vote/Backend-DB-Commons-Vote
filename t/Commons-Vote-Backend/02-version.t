use strict;
use warnings;

use Commons::Vote::Backend;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Commons::Vote::Backend::VERSION, 0.01, 'Version.');
