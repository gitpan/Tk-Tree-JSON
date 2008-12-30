package Tk::Tree::JSON;

# Tk::Tree::JSON - JSON tree widget

# Copyright (c) 2008 José Santos. All rights reserved.
# This program is free software. It can be redistributed and/or modified under 
# the same terms as Perl itself.

use strict;
use warnings;
use Carp;

BEGIN {
	use vars qw($VERSION @ISA);
	require Tk::Tree;
	require JSON;
	require Tk::Derived;
	$VERSION	= '0.01';
	@ISA		= qw(Tk::Derived Tk::Tree);
}

Construct Tk::Widget 'JSON';

sub Tk::Widget::ScrolledJSON { shift->Scrolled('JSON' => @_) }

# ConfigSpecs default values
my $VALUE_MAX_LENGTH = 80;

sub Populate {
	my ($myself, $args) = @_;
	$myself->SUPER::Populate($args);
	$myself->ConfigSpecs(
		-arraysymbol		=> ["PASSIVE", "arraySymbol", 
								"ArraySymbol", '[]'],
		-objectsymbol		=> ["PASSIVE", "objectSymbol", 
								"ObjectSymbol", '{}'],
		-namevaluesep		=> ["PASSIVE", "nameValueSep", 
								"NameValueSep", ': '],
		-valuemaxlength		=> ["METHOD", "valueMaxLength", 
								"VALUEMaxLength", $VALUE_MAX_LENGTH],
		-valuelongsymbol	=> ["PASSIVE", "valueLongSymbol", 
								"VALUELongSymbol", '...'],
		-itemtype			=> ["SELF", "itemType", "ItemType", 'text']
	);
}

# ConfigSpecs methods

# get/set max number of characters for displaying of JSON text values
sub valuemaxlength {
	my ($myself, $args) = @_;
	if (@_ > 1) {
		$myself->_configure(-valuemaxlength => &_value_max_length($args));
	}
	return $myself->_cget('-valuemaxlength');
}

# validate given max number of characters for displaying of JSON text values
# return given number if it is valid, $VALUE_MAX_LENGTH otherwise
sub _value_max_length {
	$_ = shift;
	/^\+?\d+$/ ? $& : &{ sub {
		carp "Attempt to assign an invalid value to -valuemaxlength: '$_' is" .
			" not a positive integer. Default value ($VALUE_MAX_LENGTH)" . 
			" will be used instead.\n";
		$VALUE_MAX_LENGTH
	}};
}

# application programming interface

sub load_json_file {	# load_json_file($json_filename)
	my ($myself, $json_file) = @_;
	if (!$myself->info('exists', '0')) {
		local $/ = undef;
		open FILE, $json_file or die "Could not open file $json_file: $!";
		my $json_string = <FILE>;
		close FILE;
		$myself->_load_json($myself->addchild(''), 
			&_json_parser->decode($json_string));
		$myself->autosetmode;# set up automatic handling of open/close events
	} else {
		carp "A JSON structure has already been loaded into the tree." .
			" JSON file $json_file will not be loaded.";
	}
}

sub load_json_string {	# load_json_string($json_string)
	my ($myself, $json_string) = @_;
	if (!$myself->info('exists', '0')) {
		$myself->_load_json($myself->addchild(''), 
			&_json_parser->decode($json_string));
		$myself->autosetmode;# set up automatic handling of open/close events
	} else {
		carp "A JSON structure has already been loaded into the tree." .
			" JSON string will not be loaded.";
	}
}

sub get_value {	# get_value()
	my $myself = shift;
	$myself->entrycget($myself->selectionGet(), '-data');
}

# helper methods

# _json_parser(): get a JSON::Parser instance.
sub _json_parser { JSON->new }

# _load_json($parent_path, $struct): load JSON elems under entry at $parent_path
# $struct is the json structure to add. it can be:
# - a json object represented in perl as an associative array ref
# - a json array represented in perl as an array ref
# - a json value represented in perl as a scalar
# entry's -data and -text are set, respectively, to:
# undef and {}								<= $struct is json object
# undef and []								<= $struct is json array
# undef and name : {}						<= $struct is name/json object
# undef and name : []						<= $struct is name/json array
# txtvalue and name : formatted txtvalue	<= $struct is name/txtvalue
# txtvalue and formatted txtvalue			<= $struct is txtvalue
# nb: {}, [] and : may be overriden by corresponding config options
sub _load_json {
	my ($myself, $parent_path, $struct) = ($_[0], $_[1], $_[2]);
	my $ref_type = ref $struct;
	my $text = ($myself->entrycget($parent_path, '-text') or '');
	my $entry_path;
	if ('HASH' eq $ref_type) {
		$myself->entryconfigure($parent_path, 
			-text => $text . $myself->cget('-objectsymbol')
		);
		while (my ($name, $value) = each %$struct) {
			$entry_path = $myself->addchild($parent_path, 
				-text => $name . $myself->cget('-namevaluesep')
			);
			$myself->_load_json($entry_path, $value);
		}
	} elsif ('ARRAY' eq $ref_type) {
		$myself->entryconfigure($parent_path, 
			-text => $text . $myself->cget('-arraysymbol')
		);
		foreach (@$struct) {
			$entry_path = $myself->addchild($parent_path);
			$myself->_load_json($entry_path, $_);
		}
	} else {
		$struct = defined $struct ? $struct : 'null';
		$myself->entryconfigure($parent_path, -data => $struct, 
			-text => $text . $myself->_format_text($struct)
		);
	}
}

sub _format_text { # _format_text($text): format/return text accordingly
	my ($myself, $text) = @_;
	my $value_max_length = $myself->cget('-valuemaxlength');
	length($text) > $value_max_length 
		? substr($text, 0, $value_max_length) . 
			$myself->cget('-valuelongsymbol')
		: $text;
}

1;

__END__

=head1 NAME

Tk::Tree::JSON - JSON tree widget

=head1 SYNOPSIS

 use Tk::Tree::JSON;

 $top = MainWindow->new;

 $json_tree = $top->JSON(?options?);
 $json_tree = $top->ScrolledJSON(?options?);

 $json_tree->load_json_file("file.json");
 $json_tree->load_json_string(
 	'[2008, "Tk::Tree::JSON", null, false, true, 30.12]');

=head1 DESCRIPTION

B<JSON> graphically displays the tree of JSON structures loaded from either a 
JSON file or a JSON string. 

B<JSON> enables Perl/Tk applications with a widget that allows visual 
representation and interaction with JSON structure trees. 

Target applications may include JSON viewers, editors and the like. 

=head1 STANDARD OPTIONS

B<JSON> is a subclass of L<Tk::Tree> and therefore inherits all of its 
standard options. 

Details on standard widget options can be found at L<Tk::options>.

=head1 WIDGET-SPECIFIC OPTIONS

=over 4

=item Name:		B<arraySymbol>

=item Class:		B<ArraySymbol>

=item Switch:		B<-arraysymbol>

Set the symbol representing JSON arrays.

Default value: C<[]>. 

=item Name:		B<objectSymbol>

=item Class:		B<ObjectSymbol>

=item Switch:		B<-objectsymbol>

Set the symbol representing JSON objects.

Default value: C<{}>. 

=item Name:		B<nameValueSep>

=item Class:		B<NameValueSep>

=item Switch:		B<-namevaluesep>

Set the separator to add between names and values of JSON objects.

Default value: C<: >. 

=item Name:		B<valueMaxLength>

=item Class:		B<VALUEMaxLength>

=item Switch:		B<-valuemaxlength>

Set the maximum number of characters to be displayed for JSON text values. 
Content of such values is trimmed to a length of B<valueMaxLength> characters.

Default value: C<80>. 

=item Name:		B<valueLongSymbol>

=item Class:		B<VALUELongSymbol>

=item Switch:		B<-valuelongsymbol>

Set the symbol to append to JSON text values with length greater than 
B<valueMaxLength> characters.

Default value: C<...>. 

=back

=head1 WIDGET METHODS

The B<JSON> method creates a widget object. This object supports the 
B<configure> and B<cget> methods described in L<Tk::options> which can be used 
to enquire and modify the options described above. The widget also inherits 
all the methods provided by the generic L<Tk::Widget> class.

An B<JSON> is not scrolled by default. The B<ScrolledJSON> method creates a 
scrolled B<JSON>.

The following additional methods are available for B<JSON> widgets:

=over 4

=item $json_tree->B<load_json_file>(F<$json_filename>)

Load a JSON structure from a file into the tree. If the tree is already loaded 
with a JSON structure, no reloading occurs and a warning message is issued.

Return value: none.

Example(s):

 # load JSON structure from file document.json into the tree
 $json_tree->load_json_file('document.json');

=back

=over 4

=item $json_tree->B<load_json_string>(F<$json_string>)

Load a JSON structure represented by a string into the tree. If the tree is 
already loaded with a JSON structure, no reloading occurs and a warning message 
is issued.

Return value: none.

Example(s):

 # load JSON structure from json string into the tree
 $json_tree->load_json_string('{"name1": "text1", "name2": "text2"}');

=back

=over 4

=item $json_tree->B<get_value>()

For the currently selected element, retrieve the value of the underlying JSON 
structure according to the following logic:

=over 8

=item * JSON structure is either a string, number, true, false or null: full 
text content of JSON structure is retrieved

=item * JSON structure is a name/value pair where value is neither a JSON array 
nor a JSON object: full text content of value is retrieved

=item * JSON structure is none of the above: undef is retrieved

=back

Return value: Full text content of JSON structure represented by selected 
element if it is either a string, number, true, false, null or a non-array 
non-object value of a name/value pair, or undef if it is either an array or 
object.

Example(s):

 # retrieve value of currently selected element
 $value = $json_tree->get_value();

=back

=head1 EXAMPLES

A JSON viewer using B<Tk::Tree::JSON> can be found in the F<examples> directory 
included with this module. 

=head1 VERSION

B<Tk::Tree::JSON> version 0.01.

=head1 AUTHOR

Santos, José.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-tk-tree-json at rt.cpan.org> or through the web interface at 
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Tk-Tree-JSON>. The author will 
be notified and there will be automatic notification about progress on bugs as 
changes are made.

=head1 SUPPORT

Documentation for this module can be found with the following perldoc command:

    perldoc Tk::Tree::JSON

Additional information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Tk-Tree-JSON>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Tk-Tree-JSON>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Tk-Tree-JSON>

=item * Search CPAN

L<http://search.cpan.org/dist/Tk-Tree-JSON>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2008 José Santos. All rights reserved.

This program is free software. It can redistributed and/or modified under the 
same terms as Perl itself.

=head1 ACKNOWLEDGEMENTS

Thanks to my family.

=head1 DEDICATION

I dedicate B<Tk::Tree::JSON> to Dr. Gabriel.

=cut
