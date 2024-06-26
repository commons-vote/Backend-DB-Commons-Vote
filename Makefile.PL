use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'DB backend for commons.vote application.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.03;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Backend-DB-Commons-Vote';
readme_from 'Vote.pm';
recursive_author_tests('xt');
requires 'Backend::DB' => 0;
requires 'Class::Utils' => 0;
requires 'Data::Commons::Vote::Competition' => 0;
requires 'Data::Commons::Vote::Image' => 0;
requires 'Data::Commons::Vote::Section' => 0;
requires 'Data::Commons::Vote::Person' => 0;
requires 'Data::Commons::Vote::PersonLogin' => 0;
requires 'Data::HashType' => 0;
requires 'Encode' => 0;
requires 'Error::Pure' => 0;
requires 'Unicode::UTF8' => 0;
requires 'perl' => '5.8.0';
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/Backend-DB-Commons-Vote/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/Backend-DB-Commons-Vote';
resources 'repository' => 'git://github.com/michal-josef-spacek/Backend-DB-Commons-Vote';
test_requires 'DBD::SQLite' => 0;
test_requires 'English' => 0;
test_requires 'Error::Pure::Utils' => 0.22;
test_requires 'File::Object' => 0.03;
test_requires 'File::Temp' => 0;
test_requires 'File::Spec::Functions' => 0;
test_requires 'Schema::Commons::Vote' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.01';

# Run.
WriteAll();
