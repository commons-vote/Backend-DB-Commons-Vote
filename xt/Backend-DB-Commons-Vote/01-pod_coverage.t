use strict;
use warnings;

use Test::NoWarnings;
use Test::Pod::Coverage 'tests' => 2;

# Test.
pod_coverage_ok('Backend::DB::Commons::Vote', 'Backend::DB::Commons::Vote is covered.');
