use Modern::Perl;
use Proc::Reliable;
use File::Copy;

#NEEDS:
# slurp folder support
# can I use the pngcrush context menu key?
# currently won't fire unless only one file is selected

my $safe_zone = 'H:\\PNG_DUMP\\';
copy($ARGV[0], $safe_zone.$ARGV[0]) #this will only work passing non-absolute filepaths to the script
	or die $!;
copy($ARGV[0], $ARGV[0].'2')
	or die $!;
unlink $ARGV[0];

my $done = system('pngcrush '.$ARGV[0].'2 '.$ARGV[0]);

unlink $ARGV[0].'2';


$^O eq 'MSWin32' 
	? system 'pause' 
	#I say 'any', but it might have to be enter? If so, listening to stdin makes more sense
	: system 'read -p "Press any key to continue."'; 
exit;