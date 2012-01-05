use Modern::Perl;
use Text::Unidecode;
use Term::ANSIColor;
use utf8;

#a hiragana trainer... sort of flash card thingy
#todo: separate dictionary handlers from quiz section
#todo: katakana



binmode STDOUT, ":utf8"; #turn off that ridiculous widechar warning

$ARGV[0] ? menu($ARGV[0]) : nonsense();

sub menu {
	my $dict = $_[0];
	
	print colored ("NOTE: ALL CHOICES CURRENTLY JUST POINT TO HIRAGANA/STD\n", 'red');
	
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
	##
	
	take($dict, $choice);
}

sub nonsense { #this thing doesn't handle digraphs right, whoops
	my @gana = (12353..12431, 12434, 12435);
	#these are the vowels and N, I think it makes sense to weight them a bit more
	push @gana, (12353, 12356, 12357, 12360, 12362, 12435); 
	#push @gana, (12432, 12433, 12436); #wi, we, and vu - but they're useless IRL
	map { $_ = chr $_ } @gana;

	print colored (	"WARNING: This input mode is seriously outdated and only outputs gibberish. \n".
					"You should really go download jedict.\n", 'red');
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
		
		#geminate (sokuon)
		#little tsu before a consonant sound just lengthens it IE こっこう is kokkou, not kotsukou
		if ($string =~ /っ/){
			$string =~ s!\x{3063}(.)!my $ch = $1; if(unidecode($ch) =~ /([kstc])/){ $1.$ch; } else { die 'wat'; }!e;
		}
		
		my $sol = lc(unidecode($string));
		#DIGRAPHS (even if this works, it won't flag wrong answers correctly)
		if ($string =~ /[ゃゅょ]/){
			$sol =~ s/(?<=[knhmrgbp])i(?=y[aou])//g;
			$sol =~ s/(?<=[sc]h)iy(?=[aou])//g; #shi / chi don't actually exist yet it's si / ti
			$sol =~ s/siy(?=[aou])/sh/g;
			$sol =~ s/tiy(?=[aou])/ch/g; #okay that should fix ^
			$sol =~ s/ziy(?=[aou])/j/g;
		
		#make sure that sokuon was actually dealt with
		} elsif ($string =~ /っ/){
			die "sokuon wasn't removed";
		}
		
		#unidecode disagrees with my books on these ##then I should be editing the unidecode string, not the input :|
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

=head1 INSTRUCTIONS:

=encoding utf8

=over 1

=item 1:

		WINDOWS-ONLY:
		install cygwin and puttycyg (normal cygterm will show you garbage instead of runes)

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

2012-01-04 06:09
C<<
ぜっきょう {(n,vs) exclamation/scream/shout/(P)}
zekkyou
no, it's zetukiyou 
>>
^fixed^

/eval use Text::Unidecode; use Modern::Perl; print '---'; my $st = 'ぜっきょう'; print $st; $st =~ s!\x{3063}(.)!my $ch = $1; if(unidecode($ch) =~ /([kstc])/){ $1.$ch; } else { die 'wat'; }!e; print $st; $st = unidecode $st; $st =~ s/(?<=[knhmrgbp])i(?=y[aou])//g; print $st;
haha wow (I just wanted that for posterity)