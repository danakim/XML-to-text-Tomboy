#!/usr/bin/perl

# Modules
use XML::Simple;
use Data::Dumper;
use File::Find;
use Getopt::Long;
use Cwd 'abs_path';

# Get the command line options of input and output folder
GetOptions ('input|i=s'  => \$tomboy_folder,
			'output|o=s' => \$output_folder);

# Cleanup the folders and transform them to absolute paths
$tomboy_folder = abs_path($tomboy_folder);
$output_folder =~ s/\/$//g;
$output_folder = abs_path($output_folder);

# Test to see if output folder exists - if not, create it
unless (-d $output_folder) {
	mkdir("$output_folder", 0755) || die("Could not create output folder $output_folder: $!\n");
}

# Go through all the notes in the folder and parse them
find(\&parse_note, $tomboy_folder);

# Function to actually parse the note into a text file
sub parse_note
	{
		my $note = $_;
		return unless -f $note;
		return unless $note =~ /.note$/;
		
		# Create XML object
		my $xml = new XML::Simple;
		# Read XML file
		my $data = $xml->XMLin("$note");

		# Define title and clean it up as it will be used as a file name
		my $title = "$data->{'title'}";
		$title =~ s/[^A-Za-z0-9\-\.\ \_]//g;
		$title =~ s/\s+/\ /g; 

		# Check to see if the content is an array or not - sometimes the parser does that - and define it
		if(ref($data->{'text'}->{'note-content'}->{'content'})) {
			our $content = join("\n", @{$data->{'text'}->{'note-content'}->{'content'}}, @{$data->{'text'}->{'note-content'}->{'link:url'}});
		} else {
			our $content = join("\n", $data->{'text'}->{'note-content'}->{'content'}, $data->{'text'}->{'note-content'}->{'link:url'});
		}
		
		# Write the note to disk if it is not a template note
		if ($title !~ m/Template$/) {
			open (NOTE_FILE, ">$output_folder/$title.txt") || print "Could not write note text file $output_folder/$title.txt: $!\n";
			binmode(NOTE_FILE, ":utf8");
			print (NOTE_FILE "$content\n");
			close (NOTE_FILE);
		}
	}
