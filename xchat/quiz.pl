use Modern::Perl;
use Xchat qw':all';
use Text::Unidecode;
use utf8;
use File::Slurp;
use Tie::YAML;
use YAML qw'LoadFile';

my @acceptable_chans = ('#fridge', '#tac', '#anime', '#wat');
my $cmd = qr/^;/; #trigger character
my $local = 0;
#todo:
#-leave in base chars but obv add the rest of the alphabet
#-and katakana
#---find a way to avoid hardcoding all the fucking glyphs (pull words from edict, split // into hash?)

#-the replies to others' messages don't need timers

#-make the script work in PM

tie my %score, 'Tie::YAML', 'score.po' || unload();

register('nihongo quiz', time, "what is wrong with me", \&unload);

hook_print('Channel Message', \&inevitable_failure);
hook_print('Your Message', \&inevitable_failure);

prnt "quiz loaded";
# load_dict("X:/My Dropbox/Public/GIT/scripts/misc/edict_sub");
#my %entries = load_dict("X:/My Dropbox/Public/GIT/scripts/misc/kana_library.po");
my $entries = LoadFile("X:/My Dropbox/Public/GIT/scripts/misc/kana_library.po") || prnt 'fail';

my $mode = 'b';
#my %entries; #terms & answers from edict
#we can't just pull straight from %entries - no way to pull randomly from a hash
my @library = keys %$entries;
map { $_ = [$_, kanafix($_), $entries->{$_}] } @library;
prnt (($#library + 1).' words in dictionary.');
# my @library = ("\x{3042}", "\x{3044}", "\x{3046}", "\x{3048}", "\x{304a}");
# map { $_ = [$_, unidecode $_] } @library;

#talk to yourself, or others?
my $command = "say";
if ($local){
	$command = "echo";
}


my $listening = [[0,0],0]; #not really sure initializing it fully-structured matters
my $round = 0;

sub unload { 
	prnt "quiz unloaded"; 
}
sub inevitable_failure {
	my $deets;
	($deets->{'nick'}, $deets->{'msg'}) = ($_[0][0], $_[0][1]); 
	($deets->{'chan'},$deets->{'srvr'}) = (get_info('channel'),get_info('server'));
	
	#strip any errant color codes
	my $mynick = get_info('nick');
	$mynick =~ s/^[^ -~][\d,]{1,5}//;
	$deets->{'nick'} =~ s/^[^ -~][\d,]{1,5}//;
	
	#answer needs some processing to minimize pedantry
	my $msg = lc $deets->{'msg'};
	$msg =~ s/ //g;	
	
	#chat
	if (!$listening->[0] && $msg !~ /$cmd/){ return EAT_NONE; }
	#wrong channel
	unless (grep $deets->{'chan'} eq $_, (@acceptable_chans)){ return EAT_NONE; }
	#for now, we'll only run one quiz at a time. multiples means overhauling score/round tracking
	if ($listening->[1] && $listening->[1] ne $deets->{'chan'}){ return EAT_NONE; }
	#make sure we're supposed to play with others
	if ($mynick !~ $deets->{'nick'} && $local){ return EAT_NONE; }
	
	#if there's a question out, see if it was just answered	
	if ($msg =~ /${cmd}help/){
		spam_help($deets);
	} elsif ($msg =~ /${cmd}scores/){
		dump_scores($deets);
	} elsif ($listening->[0][0]){
		if ($msg =~ /${cmd}end/){
			round_done($deets);
		} elsif ($msg =~ /${cmd}skip/){
			command "timer 1 $command ".$listening->[0][1];
			new_q($deets);
		} elsif ($msg =~ $listening->[0][1]){
			
			command "timer 1 $command ".$deets->{'nick'}." is correct.";
			
			$score{$deets->{'chan'}}{$deets->{'nick'}}++;
			$round--;
			if ($round > 0){
				new_q($deets);
			} else {
				round_done($deets);
			}
		} else {
			return EAT_NONE;
		}
	} elsif ($msg =~ /${cmd}begin(\d+)?([kh])?/){
		my ($num);
		if ($1){ $num = $1; } #round length
		else { $num = 5; }	
		if ($2){ $mode = $2; } #charset (katakana, hiragana, both)
		else { $mode = 'b'; }
		$num += 0; #to force it to stop being a string
		if ($num > 99){ $num = 99; } #don't be a dick.
#		command "timer 1 $command New round of $num starting."; #superfluous
		new_round($deets, $num, $mode);
	}
	
	return EAT_NONE;
}
sub dump_scores {
	my @out;
	
	for my $ply (keys %{$score{$_[0]->{'chan'}}}){
		push @out, (sprintf "%02d", $score{$_[0]->{'chan'}}{$ply}).': '.$ply;
	}
	if (@out){
		command "timer 1 $command ".(join ' ', reverse sort @out);
	} else {
		command "echo uhoh";
	}
	tied(%score)->save;
	return;
}
sub new_q {
	$listening->[0] = choice();
	command "timer 3 $command Q".$round.": ".$listening->[0][0]." (".$listening->[0][2].")";# [".$listening->[0][1]."]";	
}
sub choice {
	my $re;
	given ($mode){
		when ('k'){
			$re = qr/[^\p{Katakana}\x{30FC}]/;
		} when ('h'){
			$re = qr/[^\p{Hiragana}\x{30FC}]/;
		} default {
			$re = qr/[^\p{Katakana}\p{Hiragana}\x{30FC}]/;
		}
	}
	my $choice = $library[rand @library];
	if ($choice->[0] =~ $re){
		$choice = choice();
	}
	return $choice;
}
sub new_round {
	$listening->[0] = [0,0];
	$listening->[1] = $_[0]{'chan'};
	
	$round = $_[1];
	$mode = $_[2];
	
	new_q($_[0]);
}
sub round_done {
	command "timer 1 $command Round over. Scores:";
	dump_scores($_[0]);
	$mode = 'b';
	command "timer 2 $command ';begin' to start another round.";
	$listening = [[0,0],0];
}
sub spam_help {
	my $helpmsg = 
		"'\x{02}begin [#]\x{02}': Start a new round. ".
		"'\x{02}end\x{02}': End the current round. ".
		"'\x{02}skip\x{02}': Skip the current question. ".
		"'\x{02}scores\x{02}': Show the channel scoreboard.";
	command "timer 1 $command $helpmsg";
}
sub load_dict {
	#loading full 12mb edict file makes windows think the client died
#	open my $file, '<:encoding(euc-jp)', $_[0] || prnt "Edict not found.";

	# my $re = qr/[^\p{Katakana}\p{Hiragana}\x{30FC}]/; #to remove kanji and whatever


	# my $justonce = 0;
	#build the dictionary
	# while (<$file>){
		# my ($term, $def) = ($_ =~ m!^.+?\[([^;]+?)(?:;[^\]]+)*\]\s+/(.+?)(?:/\(2\).+)?/$!);
		# next unless defined $term;
		# if ($term =~ $re || $def =~ /[,(](?:obsc?|Buddh|comp|geom|gram|ling|math|physics|exp)[,)]/i){ 
			# next; 
		# } else { 
			# $entries{$term} = $def; 
		# }
		# if ($justonce){
			# $justonce--;
			# prnt "$term = $entries{$term}";
		# }
	# }
	
	
	#there's really no point to this function anymore
	my $entries = LoadFile($_[0]) || prnt 'fail';
	prnt ((scalar keys %$entries).' terms in dictionary.');
	return %$entries;
}
#because unidecode is wrong more than it isn't
sub kanafix {
	my $string = $_[0];
	my $katakana; #hiragana is the default state
	if ($string =~ /[\p{Katakana}]/){ $katakana++; } #hope there aren't mixed phrases
	if ($string =~ /[\x{3063}\x{30c3}]/){ #sokuon (little tsu)
		$string =~ s![\x{3063}\x{30c3}](.)!my $ch = $1; if(unidecode($ch) =~ /([dzjkstcpfmrn])/){ $1.$ch; } else { $ch; }!eg; #not sure if that else will ever come up
	}
	
	$string =~ s!(.)\x{30FC}!my $ch = $1; if(unidecode($ch) =~ /([aeiou])/){ $ch.$1; } else { $ch; }!eg; #(mainly) katakana vowel extender
	
	my $ti;
	if ($string =~ /[\x{30a1}\x{30a3}\x{30a5}\x{30a7}\x{30a9}]/){ #katakana's extended ranges
		$ti++ if $string =~ /\x{30c6}\x{30a3}/;
		$string =~ s!(.)([\x{30a1}\x{30a3}\x{30a5}\x{30a7}\x{30a9}])!my ($ch1,$ch2) = (unidecode $1,unidecode $2); $ch1 =~ s/.$/$ch2/; $ch1 =~ s/^(k|g)/$1w/; $ch1!eg;
	}
	
	my $sol = lc(unidecode($string));
	
	#DIGRAPHS (even if this works, it won't flag wrong answers correctly) #hm?
	if ($string =~ /[\x{3083}\x{3085}\x{3087}\x{30e3}\x{30e5}\x{30e7}]/){ #yoon
		$sol =~ s/(?<=[knhmrgbp])i(?=y[aou])//g;
		$sol =~ s/siy(?=[aou])/sh/g;
		$sol =~ s/tiy(?=[aou])/ch/g;
		$sol =~ s/ziy(?=[aou])/j/g;
	
	} 
	
	#unidecode disagrees with my books on these
	$sol =~ s/si/shi/g;
	$sol =~ s/tu/tsu/g;
	if (! $ti){ $sol =~ s/ti/chi/g; } #otherwise makes ?? end up wrong
	$sol =~ s/(?<=[aeiou])hu|^hu/fu/g; #was probably breaking chu/shu ##isn't actually being called wtf
	$sol =~ s/zi/ji/g;
	$sol =~ s/du/zu/g; #tsu with dakuten. rare
	if ($katakana){ $sol =~ s/ze/je/g; } #katakana extension for foreign words
	
	$sol =~ s/tch/cch/g; #remnant of the sokuon thing - chi didn't exist yet so it doubled ti
	
	return $sol;
}

