use Modern::Perl;
use LWP;
use JSON;
use Xchat qw':all';
use HTML::TreeBuilder;
use Text::Unidecode;

#absolutely none of the commands in this script have error handling and that's terrible


my $ver = time;
register('Xchat Custom Commands', $ver, 'Everything, vol. 1', sub{ prnt('Xchat Commands '.$ver.' unloaded.'); });
prnt('Xchat Commands '.$ver.' loaded.');

my $ua = LWP::UserAgent->new( 'timeout' => 2 );
my $json = JSON->new->utf8;

hook_command('MPC', \&now_playing);
sub now_playing {
	my $text = $ua->get('http://localhost:13579/status.html')->decoded_content;
	$text =~ s/^OnStatus\('|'\)$//g;
	my @info = split /'?,\s*'?/, $text;
	my $filesize = sprintf "%.2f", ((stat($info[-1]))[7] / 1048576);
	if ($info[5] =~ s/^00://){
		$info[3] =~ s/^00://;
	}
	
	command 'action np: '.$info[0].' || '.$info[1].': '.$info[3].'/'.$info[5].' || Size: '.$filesize.'MB';
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
hook_command('translit', \&trans); #this is fine except in the sense that it doesn't fucking work
sub tlit {
	my $line = unidecode($_[1][1]);
	command('say '.$line); 
	return EAT_XCHAT; 
}