use Modern::Perl;
use Text::Unidecode;
use Term::ANSIColor;
use utf8;

#a hiragana trainer... sort of flash card thingy
#todo: geminate (sokuon)
#	little tsu before a consonant just lengthens it IE こっこう is kokkou, not kotsukou
#todo: separate dictionary handlers from quiz section
#todo: katakana

#INSTRUCTIONS:
#	1: WINDOWS-ONLY:
#		install cygwin and puttycyg (normal cygterm will show you garbage instead of runes)
#	2:
#		download edict_sub.gz or edict.gz from http://ftp.monash.edu.au/pub/nihongo/00INDEX.html#dic_fil
#		and extract it (ideally, in the same place you put kana.pl)
#	3:
#		type `cpan -i Modern::Perl Text::Unidecode Term::ANSIColor` into your terminal/puttycyg
#		and follow those instructions
#	4:
#		navigate to the folder with kana.pl in it and type `perl kana.pl edict_sub` 
#		(replace edict_sub with edict if necessary)



binmode STDOUT, ":utf8"; #turn off that ridiculous widechar warning

$ARGV[0] ? take($ARGV[0]) : nonsense();

sub nonsense { #this thing doesn't handle digraphs right, whoops
	my @gana = (12353..12431, 12434, 12435);
	#these are the vowels and N, I think it makes sense to weight them a bit more
	push @gana, (12353, 12356, 12357, 12360, 12362, 12435); 
	#push @gana, (12432, 12433, 12436); #wi, we, and vu - but they're useless IRL
	map { $_ = chr $_ } @gana;

	print colored ("Round Length? ", 'white');
	my $num = 0 + <STDIN>;
	say colored ($num.' "words" then.', 'green');

	my ($right, $wrong) = (0, 0);
	while ($num){
		my ($string, $len) = ($gana[int rand $#gana], (int rand 5)+1);
		while ($len){ $len--; $string .= $gana[int rand $#gana]; }
		say colored ($string, 'cyan');
		chomp(my $in = <STDIN>);
		
		#extra space for single-char sounds helps keeping track of where you are
		$in =~ s/ //g; 
		#unidecode disagrees with my books on these
		$in =~ s/shi/si/g;
		$in =~ s/tsu/tu/g;
		$in =~ s/chi/ti/g;
		$in =~ s/fu/hu/g;
		
		if ($in ~~ lc(unidecode($string))){
			$right++;
			say colored ('yep ('.$right.' right|'.$wrong.' wrong)', 'green');
		} else {
			$wrong++;
			say colored ('no, it\'s '.(unidecode $string).' ('.$right.' right|'.$wrong.' wrong)', 'red');
		}
		$num--;
	}
}

sub take {
	open my $file, '<:encoding(euc-jp)', $_[0] || die $!; #the jedict files are euc-jp
	my %entries;
	
#MENU
#todo:	in addition to adage mode, how about noun/verb/adjective modes
#		and a 'hardcore mode' where you're only shown the definition
#		or grab some of those garbage types from line 83 and turn them into dedicated modes
	print colored ("Adage/expression mode? ", 'cyan');
	chomp(my $adage = <STDIN>);
	if ($adage =~ /^no$/i){ $adage = 0; }
	
	while (<$file>){
		my ($term, $def) = ($_ =~ m!^.+?\[([^;]+?)(?:;[^\]]+)*\]\s+/(.+?)(?:/\(2\).+)?/$!);
#		say $term if defined $term; #slows down the load and is obviously spammy
		next unless defined $term;
		if ($term =~ /[^\p{Hiragana}]/ || $def =~ /\((?:obsc?|Buddh|comp|geom|gram|ling|math|physics)\)/i){ 
			next; 
		} elsif ($adage && $def =~ /\(exp\)/){
			$entries{$term} = $def
		} elsif ($adage){
			next;
		} elsif (! $adage){ #vanilla mode
			$entries{$term} = $def; 
		}
	}
	say ((scalar keys %entries).' words in dictionary.');
	
	print colored ("Round Length? ", 'white');
	my $num = 0 + <STDIN>;
	say colored ($num.' words then.', 'green');
	
	
	my ($right, $wrong, @gana) = (0, 0, keys %entries);
	while ($num){
		my ($string) = ($gana[int rand $#gana]);
		say colored ($string.' {'.$entries{$string}.'}', 'cyan');
		chomp(my $in = <STDIN>);
		$in = lc $in;
		
		#extra space for single-char sounds helps keeping track of where you are
		$in =~ s/ //g; 
		
		if ($string =~ /っ/){
			$string =~ s!\x{3063}(.)!my $ch = $1; if(unidecode($ch) =~ /([kstc])/){ $1.$ch; } else { die 'wat'; }!e;
		}
		
		my $sol = lc(unidecode($string));
		#DIGRAPHS (even if this works, it won't flag wrong answers correctly)
		if ($string =~ /[ゃゅょ]/){
#			no warnings 'uninitialized'; #perl throws warnings about $1 or $2 being uninitialized
#			$in =~ s/(?:([knhmrgbp])y|([sc]h|j))(?=[aou])/$1$2iy/g;
			$sol =~ s/(?<=[knhmrgbp])i(?=y[aou])//g;
			$sol =~ s/(?<=[sc]h)iy(?=[aou])//g;
			$sol =~ s/ziy(?=[aou])/j/g;
		
		#geminate (sokuon)
		#little tsu before a consonant sound just lengthens it IE こっこう is kokkou, not kotsukou
		} elsif ($string =~ /っ/){
#			$in =~ s/([kstc])\1/tsu$1/g;
#			$sol =~ s/tsu([kstc])/\1\1/g; #THIS IS NOT A SOLUTION. FIX THIS IMMEDIATELY.
			die "sokuon wasn't removed";
		}
		
		#unidecode disagrees with my books on these ##then I should be editing the unidecode string, not the input :|
#		$in =~ s/shi/si/g;
#		$in =~ s/tsu/tu/g;
#		$in =~ s/chi/ti/g;
#		$in =~ s/fu/hu/g;
#		$in =~ s/ji/zi/g;
		$sol =~ s/si/shi/g;
		$sol =~ s/tu/tsu/g;
		$sol =~ s/ti/chi/g;
		$sol =~ s/hu/fu/g;
		$sol =~ s/zi/ji/g;
		
		
		if ($in ~~ $sol){
			$right++;
			say colored ('yep ('.$right.' right|'.$wrong.' wrong)', 'green');
		} else {
			$wrong++;
			say colored ('no, it\'s '.(unidecode $string).' ('.$right.' right|'.$wrong.' wrong)', 'red');
		}
		$num--;
	}
}

__END__

=head1 UHOHs

2012-01-04 06:09
C<<
ぜっきょう {(n,vs) exclamation/scream/shout/(P)}
zekkyou
no, it's zetukiyou 
>>
tofix: not a fix, but editting the unidecode string instead of the input will be clearer

/eval use Text::Unidecode; use Modern::Perl; print '---'; my $st = 'ぜっきょう'; print $st; $st =~ s!\x{3063}(.)!my $ch = $1; if(unidecode($ch) =~ /([kstc])/){ $1.$ch; } else { die 'wat'; }!e; print $st; $st = unidecode $st; $st =~ s/(?<=[knhmrgbp])i(?=y[aou])//g; print $st;
haha wow (I just wanted that for posterity)