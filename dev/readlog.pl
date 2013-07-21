#!/usr/bin/perl
if (@ARGV != 2) {
  print "Usage: readlog 'logfile' 'uid'\n" ;
  die ;
}
$Filename = @ARGV[0];
$UID = @ARGV[1] ;
open File, $Filename, or die "can't open $Filename" ;
$readingThread = 0 ;
while (<File>) {
  if (m/\[.*?\]/) {
    if (m/\[uid:$UID\]/) {
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
