package Lingua::Concordance;

# Concordance.pm - keyword-in-context (KWIC) search interface

# Eric Lease Morgan <eric_morgan@infomotions.com>
# June 7, 2009 - first investigations
# June 8, 2009 - tweaked _by_match; still doesn't work quite right


# configure defaults
use constant RADIUS  => 20;
use constant SORT    => 'none';
use constant ORDINAL => 1;

# include
use strict;
use warnings;

# define
our $VERSION = '0.01';

sub new {

	# get input
	my ( $class ) = @_;
	
	# initalize
	my $self = {};
	
	# set defaults
	$self->{ radius }  = RADIUS;
	$self->{ sort }    = SORT;
	$self->{ ordinal } = ORDINAL;
	
	# return
	return bless $self, $class;
	
}


sub text {

	# get input
	my ( $self, $text ) = @_;
	
	# check...
	if ( $text ) {
	
		# clean...
		$text =~ s/\n/ /g;
		$text =~ s/ +/ /g;
		$text =~ s/\b--\b/ -- /g;
		
		# set
		$self->{ text } = $text;
		
	}
	
	# return
	return $self->{ text };
	
}


sub query {

	# get input; check & set; return
	my ( $self, $query ) = @_;
	if ( $query ) { $self->{ query } = $query }
	return $self->{ query };
	
}


sub radius {

	# get input; check & set; return
	my ( $self, $radius ) = @_;
	if ( $radius ) { $self->{ radius } = $radius }
	return $self->{ radius };
	
}


sub ordinal {

	# get input; check & set; return
	my ( $self, $ordinal ) = @_;
	if ( $ordinal ) { $self->{ ordinal } = $ordinal }
	return $self->{ ordinal };
	
}


sub sort {

	# get input; check & set; return
	my ( $self, $sort ) = @_;
	if ( $sort ) { $self->{ sort } = $sort }
	return $self->{ sort };
	
}


sub lines {

	# get input
	my ( $self ) = shift;
	
	# declare
	my @lines        = ();
	my @sorted_lines = ();
	
	# define
	my $text     = $self->text;
	my $query    = $self->query;
	my $radius   = $self->radius;
	my $width    = 2 * $self->radius;
	my $ordinal  = $self->ordinal;
		
	# cheat; because $1, below, is not defined at compile time?
	no warnings;

	# gete the matching lines
	while ( $text =~ /$query/gi ) {
	
		my $match   = $1;
		my $pos     = pos( $text );
		my $start   = $pos - $self->radius - length( $match );
		my $extract = '';
		
		if ( $start < 0 ) {
		
			$extract = substr( $text, 0, $width + $start + length( $match ));
			$extract = ( " " x -$start ) . $extract;
			
		}
		
		else {
		
			$extract = substr( $text, $start, $width + length( $match ));
			my $deficit = $width + length( $match ) - length( $extract );
			if ( $deficit > 0 ) { $extract .= ( " " x $deficit ) }
		
		}
		
		push @lines, $extract;
	
	}
	
	# brach according to sorting preference
	if ( $self->sort eq 'left' ) {
	
		foreach ( sort { _by_left( $self, $a, $b ) } @lines ) { push @sorted_lines, $_ }

	}
	
	elsif ( $self->sort eq 'right' ) {
	
		foreach ( sort { _by_right( $self, $a, $b ) } @lines ) { push @sorted_lines, $_ }

	}
	
	elsif ( $self->sort eq 'match' ) {
	
		foreach ( sort { _by_match( $self, $a, $b ) } @lines ) { push @sorted_lines, $_ }

	}
	
	else { @sorted_lines = @lines }
	
	# done
	return @sorted_lines;
	
}


sub _by_left {

	# get input; find left word, compare, return
	my ( $self, $a, $b ) = @_;
	return lc( _on_left( $self, $a )) cmp lc( _on_left( $self, $b )); 
	
}


sub _on_left {

	# get input; remove punctuation; get left string; split; return ordinal word
	my ( $self, $s ) = @_;
	my @words = split( /\s+/, &_remove_punctuation( $self, substr( $s, 0, $self->radius )));
	return $words[ scalar( @words ) - $self->ordinal - 1 ];

}


sub _remove_punctuation {
	
	my ( $self, $s ) = @_;
	$s = lc( $s );
	$s =~ s/[^-a-z ]//g;
	$s =~ s/--+/ /g;
	$s =~ s/-//g;
	$s =~ s/\s+/ /g;
	return $s;

}


sub _by_right {

	# get input; find right word, compare, return
	my ( $self, $a, $b ) = @_;
	return lc( _on_right( $self, $a )) cmp lc( _on_right( $self, $b )); 
	
}


sub _on_right {

	# get input; remove punctuation; get right string; split; return ordinal word
	my ( $self, $s ) = @_;
	my @words = split( /\s+/, &_remove_punctuation( $self, substr( $s, -$self->radius )));
	return $words[ $self->ordinal ];

}


sub _by_match {

	my ( $self, $a, $b ) = @_;		
	return substr( $a, length( $a ) - $self->radius ) cmp substr( $b, length( $b ) - $self->radius );
	
}


=head1 NAME

Lingua::Concordance - Keyword-in-context (KWIC) search interface


=head1 SYNOPSIS

  use Lingua::Concordance;
  $concordance = Lingua::Concordance->new;
  $concordance->text( 'A long time ago, in a galaxy far far away...' );
  $concordance->query( 'far' );
  foreach ( $concordance->lines ) { print "$_\n" }


=head1 DESCRIPTION

Given a scalar (such as the content of a plain text electronic book or journal article) and a regular expression, this module implements a simple keyword-in-context (KWIC) search interface -- a concordance. Its purpuse is to return lists of lines from a text containing the given expression. See the Discussion section, below, for more detail.


=head1 METHODS


=head2 new

Create a new, empty concordance object:

  $concordance = Lingua::Concordance->new;


=head2 text

Set or get the value of the concordance's text attribute where the input is expected to be a scalar containing some large amount of content, like an electronic book or journal article:

  # set text attribute
  $concordance->text( 'Call me Ishmael. Some years ago- never mind how long...' );

  # get the text attribute
  $text = $concordance->text;

Note: The scalar passed to this method gets internally normalized, specifically, all carriage returns are changed to spaces, and multiple spaces are changed to single spaces.


=head2 query

Set or get the value of the concordance's query attribute. The input is expected to be a regular expression but a simple word or phrase will work just fine:

  # set query attribute
  $concordance->query( 'Ishmael' );

  # get query attribute
  $query = $concordance->query;

See the Discussion section, below, for ways to make the most of this method through the use of powerful regular expressions. This is where the fun it.


=head2 radius

Set or get the length of each line returned from the lines method, below. Each line will be padded on the left and the right of the query with the number of characters necessary to equal the value of radius. This makes it easier to sort the lines:

  # set radius attribute
  $concordance->radius( $integer );

  # get radius attribute
  $integer = $concordance->query;
	
For terminal-based applications it is usually not reasonable to set this value to greater than 30. Web-based applications can use arbitrarily large numbers. The internally set default value is 20.


=head2 sort

Set or get the type of line sorting:

  # set sort attribute
  $concordance->sort( 'left' );

  # get sort attribute
  $sort = $concordance->sort;
	
Valid values include:

=over

* none - the default value; sorts lines in the order they appear in the text -- no sorting

* left - sorts lines by the (ordinal) word to the left of the query, as defined the ordinal method, below

* right - sorts lines by the (ordinal) word to the right of the query, as defined the ordinal method, below

* match - sorts lines by the value of the query (mostly)

=back

This is good for looking for patterns in texts, such as collocations (phrases, bi-grams, and n-grams). Again, see the Discussion section for hints.


=head2 ordinal

Set or get the number of words to the left or right of the query to be used for sorting purposes. The internally set default value is 1:

  # set ordinal attribute
  $concordance->ordinal( 2 );

  # get ordinal attribute
  $integer = $concordance->ordinal;

Used in combination with the sort method, above, this is good for looking for textual patterns. See the Discussion section for more information.


=head2 lines

Return a list of lines from the text matching the query. Our reason de existance:

  @lines = $concordance->lines;


=head1 DISCUSSION

[Elaborate upon a number of things here such as but not limited to: 1) the history of concordances and concordance systems, 2) the usefulness of concordances in the study of linguistics, 3) how to expoit regular expressions to get the most out of a text and find interesting snipettes, and 4) how the module might be implemented in scripts and programs.]


=head1 BUGS

The internal _by_match subroutine, the one used to sort results by the matching regular expression, does not work exactly as expected. Instead of sorting by the matching regular expression, it sorts by the string exactly to the right of the matched regular expression. Consquently, for queries such as 'human', it correctly matches and sorts on human, humanity, and humans, but matches such as Humanity do not necessarily come before humanity.


=head1 TODO

=over

* Write Discussion section.

* Implement error checking.

* Fix the _by_match bug.

* Enable all of the configuration methods (text, query, radius, sort, and ordinal) to be specified in the constructor.

* Require the text and query attributes to be specified as a part of the constructor, maybe.

* Remove line-feed characters while normalizing text to accomdate Windows-based text streams, maybe.

* Write an example CGI script, to accompany the distribution's terminal-based script, demonstrating how the module can be implemented in a Web interface.

* Write a full-featured terminal-based script enhancing the one found in the distribution.

=back


=head1 ACKNOWLEDGEMENTS

The module implementes, almost verbatim, the concordance programs and subroutines described in Bilisoly, R. (2008). Practical text mining with Perl. Wiley series on methods and applications in data mining. Hoboken, N.J.: Wiley. pgs: 169-185. "Thanks Roger. I couldn't have done it without your book!"


=head1 AUTHOR

Eric Lease Morgan <eric_morgan@infomotions.com>

=cut

# return true or die
1;
