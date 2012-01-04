use Modern::Perl;
use Text::Unidecode;
use Term::ANSIColor;
use utf8;

#a hiragana trainer... sort of flash card thingy
#todo: kyo/rya/etc
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
		
		#DIGRAPHS (even if this works, it won't flag wrong answers correctly)
		if ($string =~ /[ゃゅょ]/){
			$in =~ s/(?:([knhmrg])y|([sc]h|j))(?=[aou])/$1$2iy/g;
		#	$in =~ s/([knhmrg])y(?=[aou])/$1iy/g; 
		#	$in =~ s/([sc]h|j)(?=[aou])/$1iy/g; print $in;
		}
		
		#unidecode disagrees with my books on these
		$in =~ s/shi/si/g;
		$in =~ s/tsu/tu/g;
		$in =~ s/chi/ti/g;
		$in =~ s/fu/hu/g;
		$in =~ s/ji/zi/g;
		
		
		my $sol = lc(unidecode($string));
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