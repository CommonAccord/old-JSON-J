#!/usr/bin/perl -wl

use warnings;
use strict;

my @missing;
my $path = "./repository/";
my $orig;

sub parse {
	
	my($file,$root,$part) = @_; my $f;

	ref($file) eq "GLOB" ? $f = $file : open $f, $file or die $!;
	$orig = $f unless $orig;
	
	my $content = parse_root($f, $root);
	if($content) { expand_fields($f, \$content, $part); return($content) }

	return;
}


sub parse_root { 
	
	my ($f, $field) = @_; my $root;

	seek($f, 0, 0);	
	while(<$f>) {
		print "[$f]:$. -- looking for $field";
		return $root if ($root) = $_ =~ /^$field\s*=\s*(.*?)$/;
	}
	
	
	seek($f, 0, 0);
	while(<$f>) {
		my($part,$what);	
		if( (($part, $what) = $_ =~ /^([^=]*)=\[(.+?)\]/) and ($field =~ s/^$part//) ) {
			print "PARSING:  $path.$what ---> $part - $field";
			$root = parse($path.$what, $field, $part);
			return $root if $root;
		}
	}
	return $root;

} 

sub expand_fields  {

	my($f,$field,$part) = @_;

	foreach( $$field =~ /\{([^}]+)\}/g ) {
		my $ex = $_;
		my $ox = $part ? $part . $ex : $ex;
		my $value = parse($orig, $ox);
		$value ? $$field =~ s/\{$ex\}/$value/gg : push @missing, $ex;
	}
} 



print "\nResult:\n".parse($ARGV[0], "Model.Root");
print "\nMissing elements: @missing";
