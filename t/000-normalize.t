#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Search::Tools::UTF8 qw( is_valid_utf8 );

sub run_it {
    my ($cmd) = @_;
    my @out = `$cmd`;
    return join( '', @out );
}

my $csv = run_it("perl norm-csv.pl < sample-with-broken-utf8.csv");

ok( is_valid_utf8($csv),
    "output of sample-with-broken-utf8.csv is valid UTF-8" );

$csv = run_it("perl norm-csv.pl < sample.csv");

ok( is_valid_utf8($csv), "output of sample.csv is valid UTF-8" );

done_testing();    # must run at end or pre-declare number of tests
