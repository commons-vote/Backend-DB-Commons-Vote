use strict;
use warnings;

use Test::More 'tests' => 3;
use Test::NoWarnings;

BEGIN {

	# Test.
	use_ok('Commons::Vote::Backend::Transform');
}

# Test.
require_ok('Commons::Vote::Backend::Transform');
