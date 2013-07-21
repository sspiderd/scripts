#!/usr/bin/perl
if (@ARGV != 2) {
  print "Usage: readlog 'logfile' 'threadname'\n" ;
  die ;
}
$Filename = @ARGV[0];
$Thread = @ARGV[1] ;
open File, $Filename, or die "can't open $Filename" ;
$readingThread = 0 ;
while (<File>) {
  if (m/^\d{4}-\d{2}-\d{2}.*\[.*?\]/) {
    if (m/\[$Thread\]/) {
	$readingThread = 1 ;
    } else {
	$readingThread = 0 ;
    }
  }
  if ($readingThread) {
	print $_ ;
  }
}
close File;
