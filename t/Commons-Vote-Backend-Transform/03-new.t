use strict;
use warnings;

use Commons::Vote::Backend::Transform;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = Commons::Vote::Backend::Transform->new;
isa_ok($obj, 'Commons::Vote::Backend::Transform');
