use strict;
use warnings;

use Commons::Vote::Backend;
use DBD::SQLite;
use English;
use Error::Pure::Utils qw(clean);
use File::Temp qw(tempdir);
use File::Spec::Functions qw(catfile);
use Schema::Commons::Vote;
use Test::More 'tests' => 5;
use Test::NoWarnings;

# Test.
my $tempdir = tempdir(CLEANUP => 1);
my $db_file = catfile($tempdir, 'ex1.db');
my $schema = Schema::Commons::Vote->new->schema->connect('dbi:SQLite:dbname='.$db_file);
isa_ok($schema, 'Schema::Commons::Vote');
my $obj = Commons::Vote::Backend->new(
	'schema' => $schema,
);
isa_ok($obj, 'Commons::Vote::Backend');

# Test.
eval {
	Commons::Vote::Backend->new;
};
is($EVAL_ERROR, "Parameter 'schema' is required.\n",
	"Parameter 'schema' is required.");
clean();

# Test.
eval {
	Commons::Vote::Backend->new(
		'schema' => 'foo',
	);
};
is($EVAL_ERROR, "Parameter 'schema' must be 'Schema::Commons::Vote' instance.\n",
	"Parameter 'schema' must be 'Schema::Commons::Vote' instance.");
clean();
