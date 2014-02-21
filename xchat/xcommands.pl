use Modern::Perl;
use LWP;
use JSON;
use Xchat qw':all';
use Text::Unidecode;
use Win32::Unicode::File; #needed solely for filesize in now_playing

#absolutely none of the commands in this script have error handling and that's terrible
# eval use strict; my ($x,$o); for (split //, "&2"){ my $r = sprintf "%x", ord $_; $o .= $_.' '.$r.'; '; $x .= '\x{'.$r.'}'; } print $o; print $x;

my $ver = time;
register('Xchat Custom Commands', $ver, 'Everything, vol. 1', sub{ prnt('Xchat Commands '.$ver.' unloaded.'); });
prnt('Xchat Commands '.$ver.' loaded.');

my $ua = LWP::UserAgent->new( 'timeout' => 2 );
my $json = JSON->new->utf8;

hook_command('MPC', \&now_playing);
sub now_playing {
	my $text = $ua->get('http://localhost:13579/status.html')->decoded_content;
	$text =~ s/^OnStatus\(|\)$//g;
	my ($quote, $t1,$last, @out);
	for my $ch (split //, $text){
		given ($ch){
			when ('"'){
				$quote
				? $quote--
				: $quote++;
			}
			when (','){
				if ($quote){
					$t1 .= $ch;
				} else {
					push @out, $t1;
					$t1 = '';
				}
			}
			when (' '){
				if ($quote){
					$t1 .= $ch;
				}
			}
			default {
				$t1 .= $ch;
			}
		}
		$last = $ch;
	}
	push @out, $t1;
	$text = [@out];

	$text->[0] =~ s/\\//g;

	# would pulling size from http://localhost:13579/info.html be saner than a filesystem call?
	$text->[-1] = sprintf "%.2f", ((file_size ($text->[-1])) / 1048576);
	if ($text->[5] =~ s/^00://){
		$text->[3] =~ s/^00://;
	}

	command 'action np: '.$text->[0].' || '.$text->[1].': '.$text->[3].'/'.$text->[5].' || Size: '.$text->[-1].'MB';
	return EAT_XCHAT;
}

hook_command('XBMC', \&xbmc);
sub xbmc { #xbmcHttp is supposedly deprecated, but the thing they replaced it with is useless
	my $text = $ua->get('http://192.168.250.125:8080/xbmcCmds/xbmcHttp?command=getcurrentlyplaying')->decoded_content;
	my %info;
	for (split /\n/, $text){
		next if $_ =~ />$/;
		$_ =~ /^<li>(.+?):(.+)$/;
		$info{lc $1} = $2;
	}
	$info{'file size'} = sprintf "%.2f", ($info{'file size'} / 1048576);
	command 'action np: '.$info{'title'}.' || '.$info{'playstatus'}.': '.$info{'time'}.'/'.$info{'duration'}.' || Size: '.$info{'file size'}.'MB';
	return EAT_XCHAT;
}

hook_command("**", \&clearqueries);
sub clearqueries { #clears the queries from *status znc spams when it loses the internet
	my @empty;
	for (get_list('channels')){
		$_->{channel} =~ /^\*/ ?
		push @empty, $_->{context} :
		next;
	}
	for (@empty){
		set_context($_);
		command("close");
	}
	return EAT_XCHAT;
}

hook_command("kitchen", \&timer);
hook_command("countdown", \&timer);
sub timer { #just a countdown timer
	my $time = $_[0][1] * 60;

	prnt("\00324TIMER\017\t".$_[0][1]." minute timer started");
	command('timer '.$time.' notice '.(get_info('nick'))." your timer\x07is up");
	for (10..15){ command('timer '.($time + $_).' recv :bitch!~dead@127.0.0.1 PRIVMSG '.(get_info('channel'))." :\x{03}24seriously\x07get out of here"); }
	return EAT_XCHAT;
}

hook_command("beepflood_words", \&asshole);
hook_command("beepflood_chars", \&asshole);
sub asshole {
	my @phrase;
	if ($_[0][0] =~ /words$/i){
		@phrase = split /\s+/, $_[1][1];
	} else {
		@phrase = split //, $_[1][1];
	}

	my @beep;
	my $pace = .5;
	my $quant = scalar @phrase;
	while ($quant > 0){
		push @beep, "\007";
		$quant--;
	}
	my $www = .1;
	for(@beep){
		command("timer $www say $phrase[$www/$pace]$_");
		$www += $pace;
	}
	return EAT_XCHAT;
}
#translits runes to romaji
hook_command('translit', \&tlit);
hook_command('tlit', \&tlit);
sub tlit {
	my $raw = $_[1][1];
	my $line = unidecode($raw);

	$raw = "\x0321".$raw."\x0F";
	length $raw < 13 	#13 length includes those four formatting chars
	? prnt($raw."\t".$line)
	: prnt($raw.' :: '.$line);

	return EAT_XCHAT;
}

#converts ascii strings to wideface japanese characters
hook_command('romaji', sub{
	my ($st,$st2) = ($_[1][1],'');
	for (split //, $st){
		$_ = chr((ord $_) + 65248) unless /\s|\./;
		$st2 .= $_;
	}
	command('say '.$st2);
	return EAT_XCHAT;
});

hook_command('rot13', \&rot13);
sub rot13 {
	my $line = $_[1][1];
	my $out;

	for (split //, $line){
		my $ord = ord $_;
		if (($ord >= 65 && $ord <= 77) || ($ord >= 97 && $ord <= 109)){
			$ord += 13;
		} elsif (($ord >= 78 && $ord <= 90) || ($ord >= 110 && $ord <= 122)){
			$ord -= 13;
		}

		$out .= chr $ord;
	}
	command ('say '.$out);
	return EAT_XCHAT;
}
hook_command('curs', \&squiggles);
sub squiggles {
	my $str = $_[1][1];
	$str =~ tr/A-Za-z0-9/\x{1D4D0}-\x{1D503}\x{1D7EC}-\x{1D7F5}/;
	command("say $str");
	return EAT_XCHAT;
}
hook_command('zg', \&zalgo);
sub zalgo {
	my ($text, $action) = ($_[1][1], '0');
	if ($text =~ m|^/me|){ $text =~ s|/me ||; $action = 1;}
	my @chars = split //, $text;
	my $zalgo = shift @chars;
	$zalgo .= "\x{489}";
	my $colorstring = '';
	for (@chars){
		if ($_ =~ /\x{3}/){ $colorstring = $_; next; } elsif ($_ =~ /[\d,]/ && length($colorstring) >= 1 && length($colorstring) < 6){ $colorstring .= $_; next; }
		elsif ($_ !~ /[\d,]/ && length($colorstring) >= 2){ $zalgo .= $colorstring; $colorstring = ''; }
		$zalgo .= "$_";
		unless ($_ =~ /^ $/){ $zalgo .= "\x{489}"; }
	}
	if ($action eq '1'){ command("action $zalgo"); } else { command("say $zalgo"); }
}
