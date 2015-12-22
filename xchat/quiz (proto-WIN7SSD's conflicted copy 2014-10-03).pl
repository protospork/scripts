use Modern::Perl;
use Xchat qw':all';
use Lingua::JA::Kana;
use utf8;
use File::Slurp;
use Tie::YAML;
use YAML qw'LoadFile';

my @acceptable_chans = ('#fridge', '#tac', '#anime', '#wat', '#nihongobot');
my $cmd = qr/^;/; #trigger character
my $local = 0;
#todo:
#-the replies to others' messages don't need timers
#-make the script work in PM
#-highlight katakana and hiragana in different colors

tie my %score, 'Tie::YAML', 'score.po' || unload();

register('nihongo quiz', time, "what is wrong with me", \&unload);

hook_print('Channel Message', \&quiz);
hook_print('Your Message', \&quiz);

command("charset utf8"); #sick of this shit
prnt "quiz loaded";
my $entries = LoadFile("X:/My Dropbox/Public/GIT/scripts/misc/kana_library.po") || prnt 'library load fail: '.$!;

my $mode = 'b';
#my %entries; #terms & answers from edict
#we can't just pull straight from %entries - no way to pull randomly from a hash
my @library = keys %$entries;
map { $_ = [$_, kana_to_roma($_), $entries->{$_}] } @library;
prnt (($#library + 1).' words in dictionary.');

#talk to yourself, or others?
my $command = "say";
if ($local){
	$command = "echo";
}


my $listening = [[0,0],0]; #not really sure initializing it fully-structured matters
my $lines_since_q = 0;
my $round = 0;

sub unload {
	prnt "quiz unloaded";
}
sub quiz {
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
	if ($msg =~ /^${cmd}help/){
		spam_help($deets);
	} elsif ($msg =~ /^${cmd}scores/){
		dump_scores($deets);
	} elsif ($listening->[0][0]){
		if ($msg =~ /^${cmd}end/){
			round_done($deets);
		} elsif ($msg =~ /^${cmd}skip/ || ($lines_since_q > 50 && $msg !~ $listening->[0][1])){
			#skip the question, either because it's been to long or because we were asked to
			command "timer 1 $command ".$listening->[0][0]." is ".$listening->[0][1].", you idiots.";
			new_q($deets);
		} elsif ($msg =~ /^$listening->[0][1]/){

			command "timer 1 $command ".$deets->{'nick'}." is correct.";

			$score{$deets->{'chan'}}{$deets->{'nick'}}++;
			$round--;
			if ($round > 0){
				new_q($deets);
			} else {
				round_done($deets);
			}
		} else {
			$lines_since_q++;
			return EAT_NONE;
		}
	} elsif ($msg =~ /^${cmd}begin(\d+)?([kh])?/){
		my ($num);
		if ($1){ $num = $1; } #round length
		else { $num = 5; }
		if ($2){ $mode = $2; } #charset (katakana, hiragana, both)
		else { $mode = 'b'; }
		$num += 0; #to force it to stop being a string
		if ($num > 99){ $num = 99; } #don't be a dick.
		new_round($deets, $num, $mode);
	}

	return EAT_NONE;
}
sub dump_scores {
	my @out;

	for my $ply (keys %{$score{$_[0]->{'chan'}}}){
		push @out, $score{$_[0]{'chan'}}{$ply}.': '.$ply;
	}

	if (@out){
		no warnings qw'uninitialized numeric'; #it doesn't like number-sorting strings ##no, these aren't global
		@out = reverse sort { $a <=> $b } @out;
		my $c = "timer 1 $command ".(join '; ', @out[0..7]); #only show top n scorers
		$c =~ s/(;\s*)+$//g;
		command $c;
	} else {
		command "echo uhoh";
	}

	tied(%score)->save;
	return;
}
sub new_q {
	$listening->[0] = choice();
	$lines_since_q = 0;
	command "timer 3 $command Q".$round.": ".$listening->[0][0]." (".$listening->[0][2].")";
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
sub kana_to_roma {
	my $roma = kana2romaji($_[0]);

    #FOR THE NEW QUIZ PARSER, THE Y IN THE FIRST TWO RULES IS OPTIONAL
    $roma =~ s/(?<=j)ix[uy]//g; #it romanizes じょ as jixyo, etc.
    $roma =~ s/(?<=ch)ixy//g;
    $roma =~ s/(?<=[hfbpkgnmr])ix//g; #and you want to keep the y for most of them

    $roma =~ s/(?<=[td])ex//g;

    $roma =~ s/(?<=v)ux//g; #all V sounds except vu use vowel extensions

    $roma =~ s/dh(?=[ui])/dz/g; #ちぢ つづ

    return $roma;
}
sub search_for_term {
	my $term = $_[0];
	my @out;

	for (keys %$entries){
		if ($_ =~ $term){
			if ($#out > 3){
				push @out, [$term, "Too many results, try http://www.csse.monash.edu.au/~jwb/cgi-bin/wwwjdic.cgi"];
				last;
			}
			push @out, [$_, $entries->{$_}];
		}
	}

	if (!@out){
		push @out, [$term, "No results for $term"];
	}

	@out = map { $_->[0].': '.$_->[1] } @out;

	return @out;
}
