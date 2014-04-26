#strip katakana phrases out of twitter logs and format them for the quizbot
#also run some word freq stuff

use Modern::Perl;
use File::Slurp;
use YAML qw'DumpFile';

open my $file, '<:utf8', $ARGV[0] || die "File not found.";
# my $file = read_file($ARGV[0], binmode => ':utf8');

#a hash where the right side counts the number of occurrences,
#which will be saved to a file using YAML
#depending on entry count, probably remove all items below n
my %entr; 

while (<$file>){
	my (@t1) = ($_ =~ m/[\p{Katakana}\x{30FC}]+/g);
	for my $word (@t1){
		$entr{$word}++;
	}
}
anal();
DumpFile('katakana_'.time.'.po', \%entr) || die $!;

sub anal {	#analytics, ho!
	my @top10;

	while (my ($k, $v) = each %entr){
		if ($v > 20 && length $k > 2){ #20 is probably too low a threshold
			push @top10, (sprintf "%05d: %s", ($v, $k));
		} else {
			delete $entr{$k};
		}
	}
	@top10 = reverse sort @top10;


	say $_ for (@top10[0..9]); #useless because windows is garbage but hey, sure
	return @top10;
}