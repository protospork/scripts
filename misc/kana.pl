use Modern::Perl;
use Text::Unidecode;

#a hiragana trainer... sort of flash card thingy
#might add katakana later


binmode STDOUT, ":utf8"; #turn off that ridiculous widechar warning

my @gana = (12353..12436);
map { $_ = chr $_ } @gana;

say "Round Length?";
my $num = 0 + <STDIN>;
say $num.' glyphs then.';

my ($right, $wrong) = (0, 0);
while ($num){
	my $glyph = $gana[int rand $#gana];
	print $glyph;
	chomp(my $in = <STDIN>);
	if ($in ~~ lc(unidecode($glyph))){
		say 'yep';
		$right++;
	} else {
		say 'no, it\'s '.(unidecode $glyph);
		$wrong++;
	}
	$num--;
}

say $right.' correct, '.$wrong.' messed up.';