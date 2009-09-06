use inc::Module::Install;
name 'PSGIRef';
all_from 'lib/PSGIRef.pm';

requires 'Any::Moose';
requires 'Test::TCP';

tests 't/*.t t/*/*.t';
author_tests 'xt';

build_requires 'Test::Exception';
build_requires 'Test::More';
test_requires 'URI';
test_requires 'IO::Socket::INET';

use_test_base;
auto_include;
auto_set_repository;
WriteAll;
