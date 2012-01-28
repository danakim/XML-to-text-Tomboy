#!/usr/bin/perl

# Modules
use XML::Simple;
use Data::Dumper;
use File::Find;
use Getopt::Long;
use Cwd 'abs_path';

# Check if any arguments were given to the script
if (scalar(@ARGV) == 0) { die("\nOptions:\n\n-i --input <folder>: The input folder with the tomboy notes to be converted.\n-o --output <folder>: Destination folder to which the plain text notes will be written to.\n"); }

# Get the command line options of input and output folder
GetOptions ('input|i=s'  => \$tomboy_folder,
			'output|o=s' => \$output_folder);

# Check if both options are passed
if (!$tomboy_folder or !$output_folder) { 
    print("\nBoth input folder and output folder must be passed to the script!\n");
    exit 255;
}

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

        # Go through the note file and cleanup the generated links tags
        # otherwise they will show up ugly in the result
        open (TMP_FILE, "$note");
        @lines=<TMP_FILE>;
        close TMP_FILE;
        foreach ( @lines )
            {
                s/\<link\:url\>//g;
                s/\<\/link\:url\>//g;
            }
	
		# Create XML object
		my $xml = new XML::Simple;
		# Read XML file
		my $data = $xml->XMLin("@lines");

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
