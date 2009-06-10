#!/usr/bin/perl

# concordance.pl - rudimentary KWIC search engine

# Eric Lease Morgan <eric_morgan@infomotions.com>
# June 7, 2009 - first investigations using Lingua::Concordance


# include
use lib './lib';
use Lingua::Concordance;
use strict;

# configure
my $file  = $ARGV[ 0 ];
my $query = $ARGV[ 1 ];
if ( ! $file or ! $query ) {

	print "Usage: $0 <file> <regular_expression>\n";
	exit;
	
}

# slurp
open INPUT, "$file" or die "Can't open input: $!\n";
my $text = do { local $/; <INPUT> };
close INPUT;

# configure
my $concordance = Lingua::Concordance->new;
$concordance->text( $text );
$concordance->query( $query );
$concordance->radius( 20 );
$concordance->sort( 'none' );
$concordance->ordinal( 1 );

# do the work
foreach ( $concordance->lines ) { print "$_\n" }

# done
exit
