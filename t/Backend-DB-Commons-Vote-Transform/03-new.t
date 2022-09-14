use strict;
use warnings;

use Backend::DB::Commons::Vote::Transform;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = Backend::DB::Commons::Vote::Transform->new;
isa_ok($obj, 'Backend::DB::Commons::Vote::Transform');
