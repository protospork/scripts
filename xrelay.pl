use strict;
use warnings;
use utf8;
use Xchat ':all';
use vars qw( %config $cfgpath @blacklist $Ccomnt $Cname $Csize $Curl $Ccomnt $Chntai );

my $ver = '2.6';
register('relay', $ver, 'complete rewrite. again. :(', \&unload);
hook_print('Channel Message', \&whoosh, {priority => PRI_HIGHEST});
hook_command('dumprelaycache', \&dumpcache);
hook_command('lastannounce', \&sayprev);
prnt("relay $ver loaded");
sub unload { prnt "relay $ver unloaded"; }

##shouldn't this all be in the config file?
my $cfgpath = 'cfg/xrelay.pm';	#this path is untested and almost definitely incorrect
my ($bot, $botchan) = ('TokyoTosho', '#tokyotosho-api');
my ($ctrlchan, $spamchan) = ('#fridge', '#wat');	#$ctrlchan gets a notice for everything announced everywhere but $spamchan.
my ($anime, $music, $destsrvr) = ('#anime', '#cfounders', 'irc.adelais.net');
my %dupe; my $last = ' ';

#	/recv :TokyoTosho!~TokyoTosh@Tokyo.Tosho PRIVMSG #tokyotosho-api :Torrent367273Anime1[gg]_Bakuman_-_10_[F8D3E973].mkvhttp://www.nyaatorrents.org/?page=download&tid=178017213.52MBshut up I'm testing something


sub whoosh {
	my ($speaker, $msg) = ($_[0][0], $_[0][1]); my $chan = get_info('channel'); my $srvr = get_info('server');
	unless ($speaker =~ /$bot/ && $chan eq $botchan){ return EAT_NONE; }
	if ($msg =~ /Torrent(.*?)(.*?)(.*?)(.*?)(.*?)([0-9\.MGK]*i?B)(?:)?(.+)?/){
		my ($rlsid, $cat, $name, $URL, $size) = ($1, $2, $4, $5, $6);
		
		return EAT_NONE if exists($dupe{$rlsid});
		$dupe{$rlsid} = $name;
		
		my $comment;
		if (defined($7)){ $comment = "$7"; } else { $comment = "no comment"; }
		
		$name =~ s/_(?!ST\])/ /g;	#I don't get it >_>	##GX_ST's fault. probably.
		$name =~ s/\.(?!\w{3}$|264)/ /g;	#should fix [Doremi].Motto.Ojamajo.Doremi.15.[8B6524C7].avi ##lookbehind/ahead, keep . if both are numbers
		$name =~ s/\x{200B}//g; $comment =~ s/\x{200B}//g;	#200B is zero-width space
		$comment =~ s{#(\S+?)\@(\S+\.(?:com|net|org))}{irc://$2/$1}gi; #irc:// links
		$comment =~ s/^no comment$//;
		
		$URL =~ s/download/torrentinfo/i if $URL =~ /nyaa\.eu/i;
		$URL =~ s/download/details/i if $URL =~ /anirena/i;
		$URL =~ s/\(/%28/g; $URL =~ s/\)/%29/;
		
		$size =~ /(\d+(?:\.\d+)?)([GMK]i?B)/; my $unit = $2; $size = $1;
		$unit =~ s/i//;
		if ($unit eq 'GB'){ $size = sprintf "%.2f", $size; $size .= $unit; }
		elsif ($unit eq 'MB'){ $size = sprintf "%.0f", $size; $size .= $unit; }
		else { $size .= $unit; }
		
		$cat = 'Hentai (Manga)' if $URL =~ /sukebei/i;
		
		
		do $cfgpath;	#I think I went about this backwards
		if (! %config){ prnt("Relay can't load config\x{07}file: $!", $ctrlchan, $destsrvr); return EAT_NONE; }
		if (! @blacklist){ prnt("Relay can't load blacklist:\x{07}$!", $ctrlchan, $destsrvr); return EAT_NONE; }
		if (! $Ccomnt){ prnt("Relay can't load colorscheme:\x{07}$!", $ctrlchan, $destsrvr); return EAT_NONE; }
		
		
		my $output = "\003$Cname" . "$name" . " \003$Csize" . "$size " . "\003$Curl" . "$URL" . "\017 \003$Ccomnt" . "$comment\017";	
		$output =~ s/\s*\003$Ccomnt *\017$//;
		if ($cat =~ m'^Hentai'){ return EAT_NONE; $output = "\003$Chntai" . "Hentai\017" . "$output"; }
		my $spam = "bs say $spamchan $output";
		
		for (@blacklist){ 
			if ((lc $name) =~ (quotemeta(lc $_))){ return EAT_NONE; } 
			if (defined($comment)){ if ((lc $comment) =~ (quotemeta(lc $_))){ return EAT_NONE; } }
			if ($URL =~ (quotemeta(lc $_))){ return EAT_NONE; }
		}
		
		my ($title, $value);
		while (($title, $value) = each %config){
			$value =~ s/\t//g;
			my ($category, $groups, $shortname, $trackers, $badthings) = split /\|/, $value;
			
			$cat =~ s/Batch/Anime-Batch/;
			next unless $cat =~ /$category/; next unless lc($name) =~ (quotemeta (lc $title));
			
			my ($okgroup, $oktracker, $other) = (0, 0, 0);
			
			if (defined($groups) && $groups ne ''){ for (split /,\s*/, $groups){ if ($name =~ /\[.*\Q$_\E.*\]/i){ $okgroup = 1; } } }	#\Q and \E are supposed to delimit regex-quoted things
			else { $okgroup = 1; }	#what? check if it's an okay group and then if it isn't, say it is anyway?
			
			if (defined($trackers) && $trackers ne ''){ for (split /,\s*/, $trackers){ if ((lc $URL) =~ (quotemeta(lc $_))){ $oktracker = 1; } } }
			else { $oktracker = 1 if $URL =~ /nyaa|anirena/i; }
			
			if (defined($badthings)){ for (split /,\s*/, $badthings){ if ((lc $name) =~ (quotemeta(lc($_)))){ $other = 1; } } }
			
			if ($okgroup == 1 && $oktracker == 1 && $other == 0){
			
				if ($cat eq 'Anime'){ command("bs say $anime $output", undef, $destsrvr); $last = $output; } 
				elsif ($cat eq 'Music'){ command("msg $music $output", undef, $destsrvr); $last = $output; }
				elsif ($cat =~ m'^Hentai'){ command($spam, undef, $destsrvr); return EAT_NONE; }
				else { command($spam, undef, $destsrvr); $last = $output; return EAT_NONE; }
				
				command("notice $ctrlchan \00324$name (\017http://tokyotosho.info/details.php?id=$rlsid\00324)\017", $ctrlchan, $destsrvr);
				if ($name =~ /$title.+?(?:S\d)?.*?([\d\.]+)/i && defined($shortname) && $shortname ne ''){ newtopic($1, $shortname); }	
				return EAT_NONE;
				
			} else {
				command($spam, undef, $destsrvr);
				$last = $output;
				return EAT_NONE;
			}
		}
		if ($cat =~ /Anime|Batch|^Music$|Manga/){ command($spam, undef, $destsrvr); $last = $output; } 
		return EAT_NONE;
	}
}

sub newtopic {
	my ($newep, $short) = @_;
	$newep =~ s/^0(\d)/$1/; $newep =~ s/\.$//;
	set_context($anime, $destsrvr);
	my $topic = get_info('topic');
	if ($topic !~ /$short/i){ prnt("\00320ERROR\017\tTitle not found in topic: $short", $ctrlchan, $destsrvr); } else {
		$topic =~ /$short (\d\d?)/i;
		return unless defined($1);
		if ($1 >= $newep || $newep == 720 || $newep == 1080){ return; } else {
			command("notice $ctrlchan Topic was: $topic", $ctrlchan, $destsrvr);
			$topic =~ s/$short \d+/$short $newep/i;
			command("cs topic $anime $topic", $anime, $destsrvr);
		}
	}
}

sub sayprev {
	if ($last eq ' '){
		prnt("Nothing has been announced yet.") ;
		return EAT_XCHAT;
	} else {
		command("msg " . get_info('channel') . " $last");
	}
}

sub dumpcache {
	for (keys %dupe){ delete($dupe{$_}); }
	prnt("Relay cache apparently deleted");
	return EAT_XCHAT;
}