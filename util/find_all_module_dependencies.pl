#!/usr/bin/env perl
use strict;
use Cwd;
use File::Spec;

my $indir = $ARGV[0];
if (!defined($indir)){
	$indir = cwd();
}

$indir = File::Spec->rel2abs($indir);

my $cmd1 = "find . -name '*.pl' -exec sh -c \"grep '^use ' {} | grep -v constant | grep -v 'use lib' | grep -v 'use strict' \" \\;";

my $list1 = execute_cmd($cmd1);

my $cmd2 = "find . -name '*.pm' -exec sh -c \"grep '^use ' {} | grep -v constant | grep -v 'use lib' | grep -v 'use strict' \" \\;";

my $list2 = execute_cmd($cmd2);

my $lookup = {};

my $ctr = 0;

&process_list($list1);

&process_list($list2);

print "\nHere are the unique '$ctr' Perl modules depended upon by the Perl code in directory '$indir':\n";

my $outfile = "./modules_list_file.txt";

open (OUTFILE, ">$outfile") || die "Could not open '$outfile' in write mode : $!";

print OUTFILE "## date-created: " . localtime() . "\n";

print OUTFILE "## method-created: " . File::Spec->rel2abs($0) . "\n";

foreach my $key (sort keys %{$lookup}){

	print $key . "\n";

	print OUTFILE $key . "\n";
}

close OUTFILE;

print "\nWrote the module list to '$outfile'.\n";

print "You can install these using ./bin/perlbrew_helper.pl --modules_list_file modules_list_file.txt\n";

print "Please remember to specify the virtual environment if/when you do so.\n";

exit(0);

##-----------------------------------------------------------
##
##    END OF MAIN -- SUBROUTINES FOLLOW
##
##-----------------------------------------------------------


sub process_list {
	
	my ($list) = @_;

	foreach my $line (@{$list}){

		$line =~ s|^\s*use\s+||;
		$line =~ s|^\s+||;
		$line =~ s|\s+$||;
		$line =~ s|;\s*$||;


		if (!exists $lookup->{$line}){
			$lookup->{$line}++;
			$ctr++;
		}
	}
}


sub execute_cmd {

    my ($ex) = @_;

    print "About to execute '$ex'\n";

    my @results;
   
    eval {
        @results = qx($ex);
    };

    if ($?){
        confess("Encountered some error while attempting to execute '$ex' : $! $@");
    }

    return \@results;
}