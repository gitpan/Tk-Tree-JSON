#!/usr/bin/perl -w

# A JSON viewer using Tk::Tree::JSON.

# Copyright (c) 2008 José Santos. All rights reserved.
# This program is free software. It can be redistributed and/or modified under 
# the same terms as Perl itself.

use strict;

use Tk;
use Tk::Tree::JSON;

die "Syntax: $0 <file.json>\n" unless (scalar @ARGV == 1);

my $json_filename = shift;
my ($FOREGROUND, $BACKGROUND) = ("black", "#FFFFFF");
my $textarea;

my $top = MainWindow->new;

my $json_tree = $top->ScrolledJSON(
	-background => $BACKGROUND, -foreground => $FOREGROUND, -height => 20, 
);

$json_tree->configure(-browsecmd => sub {
	my $value = $json_tree->get_value;
	$textarea->delete("1.0", "end");
	if (defined $value) {
		$textarea->insert("end", $value);
	}
});
$json_tree->load_json_file($json_filename);

# text area (for currently selected element in tree if JSON textual value)
$textarea = $top->Text(
	-height => 10, -background => $BACKGROUND, -foreground => $FOREGROUND, 
);

# pack gui components
$json_tree->pack(-side => 'top', -fill => 'x', -expand => 1);
$textarea->pack(-side => 'top', -fill => 'x', -expand => 0);

MainLoop;