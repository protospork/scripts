use Modern::Perl;
use Text::Unidecode;

#a hiragana trainer... sort of flash card thingy
#might add katakana later


binmode STDOUT, ":utf8"; #turn off that ridiculous widechar warning

my @gana = (12353..12431, 12434, 12435);
#these are the vowels and N, I think it makes sense to weight them a bit more
push @gana, (12353, 12356, 12357, 12360, 12362, 12435); 
#push @gana, (12432, 12433, 12436); #wi, we, and vu - but they're useless IRL
map { $_ = chr $_ } @gana;

print "Round Length? ";
my $num = 0 + <STDIN>;
say $num.' "words" then.';

my ($right, $wrong) = (0, 0);
while ($num){
	my ($string, $len) = ($gana[int rand $#gana], (int rand 5)+1);
	while ($len){ $len--; $string .= $gana[int rand $#gana]; }
	say $string;
	chomp(my $in = <STDIN>);
	
	#extra space for single-char sounds helps keeping track of where you are
	$in =~ s/ //g; 
	#unidecode disagrees with my books on these
	$in =~ s/shi/si/g;
	$in =~ s/tsu/tu/g;
	$in =~ s/chi/ti/g;
	$in =~ s/fu/hu/g;
	
	if ($in ~~ lc(unidecode($string))){
		say 'yep';
		$right++;
	} else {
		say 'no, it\'s '.(unidecode $string);
		$wrong++;
	}
	$num--;
}

say $right.' correct, '.$wrong.' messed up.';