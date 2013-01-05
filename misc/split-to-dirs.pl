use Modern::Perl;
use File::Copy;
use Cwd;

my @files = glob "*.*";
map { $_ = [$_, cwd."/$_"] } @files; #need complete path

#make the overflow folder
unless (cwd =~ /_OVERFLOW\/?$/){ 
	mkdir '_OVERFLOW';
	chdir '_OVERFLOW';
}
#and subfolders
mkdir $_ for (0..9);

my $i = 0; 
for (@files){ 
	if (-d $_->[1] || $_->[1] =~ /\.pl$/){ next; }
	say $_->[1]; 
	move $_->[1], (($i%10)."/$_->[0]") || die $!; 
	$i++; 
}