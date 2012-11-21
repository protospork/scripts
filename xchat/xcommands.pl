use Modern::Perl;
use LWP;
use JSON;
use Xchat qw':all';
use HTML::TreeBuilder;
use Text::Unidecode;
if ($^O eq 'MSWin32'){ use Win32::Unicode::File; } #needed solely for filesize in now_playing

#absolutely none of the commands in this script have error handling and that's terrible


my $ver = time;
register('Xchat Custom Commands', $ver, 'Everything, vol. 1', sub{ prnt('Xchat Commands '.$ver.' unloaded.'); });
prnt('Xchat Commands '.$ver.' loaded.');

my $ua = LWP::UserAgent->new( 'timeout' => 2 );
my $json = JSON->new->utf8;

hook_command('MPC', \&now_playing);
sub now_playing {
	my $text = $ua->get('http://localhost:13579/status.html')->decoded_content;
	$text =~ s/^OnStatus\(|\)$//g;
	$text = [split /,\s*/, $text];
	s/^'|'$//g for (@$text);
	if ($^O eq 'MSWin32'){ #not that MPC runs on linux
		$text->[-1] = sprintf "%.2f", ((file_size ($text->[-1])) / 1048576);
	} else {
		$text->[-1] = sprintf "%.2f", ((stat($text->[-1]))[7] / 1048576); #unicode breaks stat on win32
	}
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
		$_->{channel} =~ /\*status/ ? 
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

hook_command('twit', \&twitter);
sub twitter { #this locks the whole client and isn't particularly useful
	command('say https://twitter.com'.(HTML::TreeBuilder->new_from_content($ua->get('https://twitter.com/intent/user?screen_name='.$_[0][1])->decoded_content)->look_down(_tag => 'a', class => 'tweet-timestamp')->extract_links->[0][0]));
	return EAT_XCHAT;
}
hook_command('hex', sub{prnt($_[0][1].' is '.(sprintf "%x", $_[0][1])); return EAT_XCHAT; }); #translate a number from decimal to hex

#converts ascii strings to wideface japanese characters
hook_command('smallcaps', sub{my ($st,$st2) = ($_[1][1],''); $st =~ tr/A-Z/a-z/; for (split //, $st){ $_ = chr((ord $_) + 65216) unless $_ !~ /[a-z]/; $_ = chr((ord $_) + 65248) unless $_ !~ /[0-9~\[\]:;'"<>}{|\\\/_,?!@#$%^&*()\-+=*]/; $st2 .= $_; } command('say '.$st2); return EAT_XCHAT;});
hook_command('romaji', sub{my ($st,$st2) = ($_[1][1],''); for (split //, $st){ $_ = chr((ord $_) + 65248) unless /\s|\./; $st2 .= $_; } command('say '.$st2); return EAT_XCHAT;});

#translits kana/kanji to romaji
hook_command('translit', \&tlit); 
hook_command('tlit', \&tlit);
sub tlit {
	my $raw = $_[1][1];
	my $line = unidecode($raw);
	
	my %ranges;
	for (split //, $raw){
		if (/[\p{Hiragana}]/){	$ranges{'Hiragana'}++; }
		elsif (/[\p{Katakana}]/){	$ranges{'Katakana'}++; }
		elsif (/[\p{Han}]/){		$ranges{'Han'}++; }
		elsif (/[\p{Ascii}]/){ $ranges{'Ascii'}++; }
		else { $ranges{'other'}++ }
	}
	my @content;
	push @content, ($_.': '.$ranges{$_}) for sort keys %ranges;
	
	$raw = "\x0321".$raw."\x0F";
	length $raw < 13 	#13 length includes those four formatting chars
		? prnt($raw."\t".$line.' ['.(join ', ', @content).']') 
		: prnt($raw.' :: '.$line.' ['.(join ', ', @content).']'); 
	
	return EAT_XCHAT; 
}

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