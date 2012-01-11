use Modern::Perl;
use Text::Unidecode;
use Term::ANSIColor;
use utf8;

#a hiragana trainer... sort of flash card thingy
#todo: 'hardcore mode' where you're only shown the definition
#todo: /.o u/ may be written as (ex) 'booshi', not 'boushi' but I've seen it both ways :\
#todo: repetition symbol && voiced repetition symbol aren't in the hiragana range \x{309d} \x{309e}

my $debugmode = 1;

binmode STDOUT, ":utf8"; #turn off that ridiculous widechar warning

$ARGV[0] ? menu($ARGV[0]) : find_dict();

sub find_dict {
	my @dir = <*>;
	if (grep "edict_sub", @dir){
		print colored	(
						'Using edict_sub. If you\'d prefer edict, call the script with'."\n".
						'`perl kana.pl edict`',
						'green'
						);
		print "\n";
		return menu('edict_sub');
	} elsif (grep "edict", @dir){
		print colored ('Found edict, will use as dictionary.', 'green');
		print "\n";
		return menu('edict');
	} elsif (grep "jmdict", @dir){
		print colored ('JMDict is unsupported. Download edict instead, it\'s the same content', 'red');
		print "\n";
		exit;
	} else {
		print colored ('No dictionary file found. Defaulting to nonsense mode', 'red');
		print "\n";
		return nonsense();
	}
}

sub menu {
	my $dict = $_[0];
	
#	print colored ("NOTE: ALL CHOICES CURRENTLY JUST POINT TO HIRAGANA\n", 'red'); #no longer true \o/
	
	##define menu
	my (@menuL, @menuR);
	#left column
	push @menuL, (sprintf "%02d", 1);
	push @menuL, (sprintf " | %35s  ", 'normal mode - hiragana & katakana');
	push @menuL, (sprintf "%02d", 2);
	push @menuL, (sprintf " | %35s  ", 'hiragana only'); #submenu TODO: give all submenu items choice numbers you can type immediately (shortcuts)
	push @menuL, (sprintf "%02d", 3);
	push @menuL, (sprintf " | %35s  ", 'katakana only'); #submenu
	#right column
	push @menuR, (sprintf "%02d", 4);
	push @menuR, (sprintf " | %35s  ", 'search dictionary');
	push @menuR, (sprintf "%02d", 5);
	push @menuR, (sprintf " | %35s  ", 'validate dictionary');
	##build menu
	while (@menuL){
		my ($num, $txt) = (shift @menuL, shift @menuL);
		print colored ($num, 'blue on_cyan');
		print colored ($txt, 'cyan on_blue');
		if (@menuR){
			print colored (shift @menuR, 'blue on_cyan');
			print colored (shift @menuR, 'cyan on_blue');
		}
		print "\n";
	}
	##take choice
	print colored ("Choose a Number ", 'cyan');
	chomp (my $choice = <STDIN>);
	if ($choice !~ /^[0-9]+$/){ 
		print colored ('I asked for a number between 1 and 5. This isn\'t hard.', 'red'); 
		print "\n";
		return menu(@_); 
	}
	##submenu?
	if ($choice == 2 || $choice == 3){
		$choice *= 10;
		print colored ((sprintf "%02d", ($choice + 1)), 'blue on_cyan');
		print colored ((sprintf " | %35s  ", 'standard mode: no tech jargon'), 'cyan on_blue');
		print "\n"; #sticking newlines in the colored strings colors the next line
		print colored ((sprintf "%02d", ($choice + 2)), 'blue on_cyan');
		print colored ((sprintf " | %35s  ", 'adages (colloquial metaphors) ONLY'), 'cyan on_blue');
		print "\n";
	##take choice again
		print colored ("Choose a Number ", 'cyan');
		chomp ($choice = <STDIN>);
	}
	##out of bounds?
	if (($choice > 5 && $choice < 21) || $choice > 32){ #FLAWED - FIX THIS
		print colored ("Invalid choice, returning to root menu.\nTrying to leave? CTRL-C", 'red');
		print "\n";
		return menu(@_);
	}
	if ($choice == 31 or $choice == 32){
		katakana($dict, $choice);
	} else {
		hiragana($dict, $choice);
	}
}

sub nonsense { #this thing doesn't handle digraphs right, whoops
	my @gana = (12353..12431, 12434, 12435);
	#these are the vowels and N, I think it makes sense to weight them a bit more
	push @gana, (12353, 12356, 12357, 12360, 12362, 12435); 
	#push @gana, (12432, 12433, 12436); #wi, we, and vu - but they're useless IRL
	map { $_ = chr $_ } @gana;

	print colored (	"WARNING: This mode is seriously outdated and only outputs gibberish. \n".
					"Download jedict and the real options will be unlocked.\n", 'red');
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

sub hiragana {
	open my $file, '<:encoding(euc-jp)', $_[0] || die $!;
	my %entries;


	print colored ('Hiragana', 'cyan on_blue');
	print "\n";
	
	say 'menu choice '.$_[1] if $debugmode;
	
	my $adage;
	if ($_[1] == 22){
		$adage++;
		print colored ('Adage mode enabled.', 'cyan on_blue');
		print "\n";
	}
	
	#build the dictionary
	while (<$file>){
		my ($term, $def) = ($_ =~ m!^.+?\[([^;]+?)(?:;[^\]]+)*\]\s+/(.+?)(?:/\(2\).+)?/$!);
#		if ($debugmode && defined $term){ say $term; } #slows down the load and is obviously spammy
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
	if ($debugmode){ say ((scalar keys %entries).' words in dictionary.'); }
	
	print colored ("Round Length? ", 'green');
	my $num = 0 + <STDIN>;
	if ($debugmode){ say colored ($num.' words then.', 'green'); }
	
	
	my ($right, $wrong, @gana) = (0, 0, keys %entries);
	while ($num){
		my ($string) = ($gana[int rand $#gana]);
		say colored ($string.' {'.$entries{$string}.'}', 'cyan');
		chomp(my $in = <STDIN>);
		$in = lc $in;
		
		#extra space for single-char sounds helps keeping track of where you are
		$in =~ s/ //g; 
		
		my $sol = kanafix($string);
		
		say 'you said '.$in if $debugmode;
		say 'I think  '.$sol if $debugmode;
		
		
		if ($in ~~ $sol){
			$right++;
			say colored ('yep ('.$right.' right|'.$wrong.' wrong)', 'green');
		} else {
			$wrong++;
			say colored ('no, it\'s '.$sol.' ('.$right.' right|'.$wrong.' wrong)', 'red');
		}
		$num--;
	}
}
sub katakana {
	open my $file, '<:encoding(euc-jp)', $_[0] || die $!;
	my %entries;


	print colored ('Katakana', 'cyan on_blue');
	print colored (' WORK IN PROGRESS. I don\'t even fucking know katakana.', 'red on_black');
	print "\n";
	
	say 'menu choice '.$_[1] if $debugmode;
	
	my $adage;
	if ($_[1] == 32){
		$adage++;
		print colored ('Adage mode enabled.', 'cyan on_blue');
		print "\n";
	}
	
	#build the dictionary
	while (<$file>){
		my ($term, $def) = ($_ =~ m!^.+?\[([^;]+?)(?:;[^\]]+)*\]\s+/(.+?)(?:/\(2\).+)?/$!);
#		if ($debugmode && defined $term){ say $term; } #slows down the load and is obviously spammy
		next unless defined $term;
		if ($term =~ /[^\p{Katakana}]/ || $def =~ /\((?:obsc?|Buddh|comp|geom|gram|ling|math|physics)\)/i){ 
			next; 
		} elsif ($adage && $def =~ /\(exp\)/){
			$entries{$term} = $def
		} elsif ($adage){
			next;
		} elsif (! $adage){ #vanilla mode
			$entries{$term} = $def; 
		}
	}
	if ($debugmode){ say ((scalar keys %entries).' words in dictionary.'); }
	
	print colored ("Round Length? ", 'green');
	my $num = 0 + <STDIN>;
	if ($debugmode){ say colored ($num.' words then.', 'green'); }
	
	
	my ($right, $wrong, @kana) = (0, 0, keys %entries);
	while ($num){
		my ($string) = ($kana[int rand $#kana]);
		say colored ($string.' {'.$entries{$string}.'}', 'cyan');
		chomp(my $in = <STDIN>);
		$in = lc $in;
		
		#extra space for single-char sounds helps keeping track of where you are
		$in =~ s/ //g; 
		
		my $sol = kanafix($string);
		
		say 'you said '.$in if $debugmode;
		say 'I think  '.$sol if $debugmode;
		
		
		if ($in ~~ $sol){
			$right++;
			say colored ('yep ('.$right.' right|'.$wrong.' wrong)', 'green');
		} else {
			$wrong++;
			say colored ('no, it\'s '.$sol.' ('.$right.' right|'.$wrong.' wrong)', 'red');
		}
		$num--;
	}
}
sub kanafix {
	my $string = $_[0];
	my $katakana;
	if ($string =~ /[\p{Katakana}]/){ $katakana++; } #not sure if there are mixed phrases
	if ($string =~ /[\x{3063}\x{30c3}]/){ #sokuon (little tsu)
		if ($string =~ s![\x{3063}\x{30c3}](.)!my $ch = $1; if(unidecode($ch) =~ /([kstcpfmrn])/){ $1.$ch; } else { $ch; }!eg){ warn 'regex' if $debugmode; }
	}
	my $ti;
	if ($string =~ /[\x{30a1}\x{30a3}\x{30a5}\x{30a7}\x{30a9}]/){ #katakana's extended ranges
		$ti++ if $string =~ /\x{30c6}\x{30a3}/;
		if ($string =~ s!(.)([\x{30a1}\x{30a3}\x{30a5}\x{30a7}\x{30a9}])!my ($ch1,$ch2) = (unidecode $1,unidecode $2); $ch1 =~ s/.$/$ch2/; $ch1 =~ s/^(k|g)/$1w/; $ch1!eg){ warn 'regex' if $debugmode; }
	}
	
	my $sol = lc(unidecode($string));
	
	#DIGRAPHS (even if this works, it won't flag wrong answers correctly) #hm?
	if ($string =~ /[\x{3083}\x{3085}\x{3087}\x{30e3}\x{30e5}\x{30e7}]/){ #yoon
		if ($sol =~ s/(?<=[knhmrgbp])i(?=y[aou])//g){ warn 'regex' if $debugmode; }
		if ($sol =~ s/siy(?=[aou])/sh/g){ warn 'regex' if $debugmode; }
		if ($sol =~ s/tiy(?=[aou])/ch/g){ warn 'regex' if $debugmode; }
		if ($sol =~ s/ziy(?=[aou])/j/g){ warn 'regex' if $debugmode; }
	
	#make sure that sokuon was actually dealt with
	} 
	if ($string =~ /[\x{3063}\x{30c3}]/){
		warn "sokuon wasn't removed: ".$string;
	}
	if ($string =~ /[\x{30a1}\x{30a3}\x{30a5}\x{30a7}\x{30a9}]/){
		warn "katakana digraphs are still broken: ".$string;
	}
	
	#unidecode disagrees with my books on these
	if ($sol =~ s/si/shi/g){ warn 'regex' if $debugmode; }
	if ($sol =~ s/tu/tsu/g){ warn 'regex' if $debugmode; }
	if (! $ti){ if ($sol =~ s/ti/chi/g){ warn 'regex' if $debugmode; } } #otherwise makes ティ end up wrong
	if ($sol =~ s/(?<=[aeiou])hu|^hu/fu/g){ warn 'regex' if $debugmode; } #was probably breaking chu/shu
	if ($sol =~ s/zi/ji/g){ warn 'regex' if $debugmode; }
	if ($sol =~ s/du/zu/g){ warn 'regex' if $debugmode; } #tsu with dakuten. rare
	if ($katakana){ if ($sol =~ s/ze/je/g){ warn 'regex' if $debugmode; } } #katakana extension for foreign words
	
	if ($sol =~ s/tch/cch/g){ warn 'regex' if $debugmode; } #remnant of the sokuon thing - chi didn't exist yet so it doubled ti
	
	return $sol;
}
__END__

=head1 INSTRUCTIONS:

=encoding utf8

=over 1

=item 1:

		WINDOWS-ONLY:
		install cygwin and puttycyg (normal cygterm will show you garbage instead of runes).
		you'll also want to make puttycyg use a font with japanese glyphs - MS Gothic (without the @)
		is the only sure bet I know of

=item 2:

		download edict_sub.gz or edict.gz from http://ftp.monash.edu.au/pub/nihongo/00INDEX.html#dic_fil
		and extract it (ideally, in the same place you put kana.pl)

=item 3:

		type C<cpan -i Modern::Perl Text::Unidecode Term::ANSIColor> into your terminal/puttycyg
		and follow those instructions

=item 4:

		navigate to the folder with kana.pl in it and type C<perl kana.pl edict_sub>
		(replace edict_sub with edict if necessary)

=back

=head2 UHOHs

2012-01-05 08:14

C<<

えんはいなものあじなもの {(exp) inscrutable and interesting are the ways people are brought together}
enhainamonoojinamono
no, it's enhainamonoazinamono

>>

C<<

こうふくをもとめて {(exp) in search (pursuit) of happiness}
koufukuwomutomete
regex ln215
you said koufukuwomutomete
I think  koufukuwomotomete
no, it's koufukuwomotomete

>>

2011-01-06 09:32

C<<

りっしんしゅっせ {(n,vs) success in life}
risshinshusse
regex ln193
regex ln202
regex ln212
regex ln213
you said risshinshusse
I think  risshinshutsuse
no, it's risshinshutsuse 

>>

/eval use Text::Unidecode; use Modern::Perl; print '---'; my $st = 'ぜっきょう'; print $st; $st =~ s!\x{3063}(.)!my $ch = $1; if(unidecode($ch) =~ /([kstc])/){ $1.$ch; } else { die 'wat'; }!e; print $st; $st = unidecode $st; $st =~ s/(?<=[knhmrgbp])i(?=y[aou])//g; print $st;
haha wow (I just wanted that for posterity)