use strict;
use warnings;
use utf8;
use Xchat ':all';
use vars qw( %config $cfgpath @blacklist $do_hentai $do_airtime $Ccomnt $Cname $Csize $Curl $Ccomnt $Chntai );
use URI;
use JSON;
use LWP;

my $ver = '3.0';
register('relay', $ver, 'complete rewrite. again. :(', \&unload);
hook_print('Channel Message', \&whoosh, {priority => PRI_HIGHEST});
hook_command('dumprelaycache', \&dumpcache);
hook_command('dumprelaytimers', \&dump_timers);
hook_command('lastannounce', \&sayprev);
prnt("relay $ver loaded");
sub unload { prnt "relay $ver unloaded"; }

##shouldn't this all be in the config file? (nope)
my $cfgpath = 'X:\My Dropbox\Public\GIT\scripts\xchat\cfg\xrelay.pm';	#I'm doomed to need to hardcode this
my ($bot, $botchan) = ('TokyoTosho', '#tokyotosho-api');
my ($ctrlchan, $spamchan) = ('#fridge', '#wat');	#$ctrlchan gets a notice for everything announced everywhere but $spamchan.
my ($anime, $music, $destsrvr) = ('#anime', '#wat', 'irc.adelais.net');
my %dupe; my $last = ' '; my $airtimes_set = 0;
my %titles; #cached 'TID => [TitleEN, Title]' from syoboi
my @timers;

#Sample test line:
#	/recv :TokyoTosho!~TokyoTosh@Tokyo.Tosho PRIVMSG #tokyotosho-api :Torrent367273Anime1[TMD]_Bakuman_-_10_[F7D2E973].mkvhttp://www.nyaa.eu/?page=download&tid=178017213.52MBshut up I'm testing something


sub whoosh {
	my ($speaker, $msg) = ($_[0][0], $_[0][1]); 
	my ($chan,$srvr) = (get_info('channel'),get_info('server'));
	
	unless ($speaker =~ /$bot/ && $chan eq $botchan){ return EAT_NONE; }
	
	if ($msg =~ /Torrent(.*?)(.*?)(.*?)(.*?)(.*?)([0-9\.MGK]*i?B)(?:)?(.+)?/){
		my ($rlsid, $cat, $name, $URL, $size) = ($1, $2, $4, $5, $6);
		
		return EAT_NONE if exists($dupe{$rlsid});
		$dupe{$rlsid} = $name;
		
		my $comment = '';
		if (defined($7)){ $comment = $7; }
		
		
		$name =~ s/_(?!ST\])/ /g;        #Replace underscore with space, except for the one in GX_ST
		$name =~ s/\.(?!\w{3}$|264)/ /g; #Replace dots with spaces
		$name =~ s/\x{200B}//g;        #200B is zero-width space
		
		$comment =~ s/\x{200B}//g;     #TT throws them in for proper line-wrapping
		$comment =~ s{#(\S+?)\@(\S+\.(?:com|net|org))}{irc://$2/$1}gi; #irc:// links
		
		$URL =~ s/download/torrentinfo/i if $URL =~ /nyaa\.eu/i;
		$URL =~ s/download/details/i if $URL =~ /anirena/i; #does anirena even still exist
		$URL =~ s/\(/%28/g; $URL =~ s/\)/%29/g;		
		
		#rounding!
		my ($size,$unit) = ($size =~ /(\d+(?:\.\d+)?)([GMK]i?B)/); 
		$unit =~ s/i//;
		if ($unit eq 'GB'){ $size = sprintf "%.2f", $size; $size .= $unit; }
		elsif ($unit eq 'MB'){ $size = sprintf "%.0f", $size; $size .= $unit; }
		else { $size .= $unit; }
		
		$cat = 'Hentai (Manga)' if $URL =~ /sukebei/i;	
		
		
		do $cfgpath;	#load the config
		if (! %config){ prnt("Relay can't load config\x07file", $ctrlchan, $destsrvr); return EAT_NONE; }
		if (! @blacklist){ prnt("Relay can't load\x07blacklist", $ctrlchan, $destsrvr); return EAT_NONE; }
		if (! $Ccomnt){ prnt("Relay can't load\x07colorscheme", $ctrlchan, $destsrvr); return EAT_NONE; }
		
		#add timers to announce when a show has aired
		if ($do_airtime &&! $airtimes_set){
			set_airtimes(\%config);
		}
		
		my $output = "\x03".$Cname.$name." \x03".$Csize.$size." \x03".$Curl.$URL."\x0F \x03".$Ccomnt.$comment."\x0F";	
		$output =~ s/\s*\x03$Ccomnt *\x0F$//; #just in case there's no comment
		if ($cat =~ m'^Hentai'){ return EAT_NONE unless $do_hentai == 1; $output = "\x03".$Chntai."Hentai\x0F".$output; }
		my $spam = 'bs say '.$spamchan.' '.$output;
		
		for (@blacklist){ #wow that's ugly. I'll fix it later
			if ((lc $name) =~ (quotemeta(lc $_))){ return EAT_NONE; } 
			if (defined($comment)){ if ((lc $comment) =~ (quotemeta(lc $_))){ return EAT_NONE; } }
			if ($URL =~ (quotemeta(lc $_))){ return EAT_NONE; }
		}
		
		
#aaaand we finally get down to the job at hand
		my ($cfg_title, $value);
		while (($cfg_title, $value) = each %config){
#			$value =~ s/\t//g; #what
			my ($cfg_cat, $cfg_groups, $cfg_stitle, $cfg_blacklist, $cfg_syo_tid) = @$value;
			
			$cat =~ s/Batch/Anime-Batch/;
			next unless $cat =~ /$cfg_cat/; 
			next unless lc($name) =~ (quotemeta (lc $cfg_title));
			
			my ($okgroup, $other) = (0, 0);
			
			if (defined($cfg_groups)){ for (@$cfg_groups){ if ($name =~ /\[.*\Q$_\E.*\]/i){ $okgroup = 1; } } }	#\Q and \E are supposed to delimit regex-quoted things
			else { $okgroup = 1; }
			
			if (defined($cfg_blacklist)){ for (split /,\s*/, $cfg_blacklist){ if ((lc $name) =~ (quotemeta(lc($_)))){ $other = 1; } } }
			
			if ($okgroup == 1 && $other == 0){
			
				if ($cat eq 'Anime'){ command('bs say '.$anime.' '.$output, undef, $destsrvr); $last = $output; } 
				elsif ($cat eq 'Music'){ command('msg '.$music.' '.$output, undef, $destsrvr); $last = $output; }
				elsif ($cat =~ m'^Hentai'){ command($spam, undef, $destsrvr); return EAT_NONE; }
				else { command($spam, undef, $destsrvr); $last = $output; return EAT_NONE; }
				
				command("notice ".$ctrlchan." \x0324".$name." (\x0Fhttp://tokyotosho.info/details.php?id=".$rlsid."\x0324)\x0F", $ctrlchan, $destsrvr);
				if ($name =~ /$cfg_title.+?(?:S\d)?.*?([\d\.]+)/i && defined($cfg_stitle) && $cfg_stitle ne ''){ newtopic($1, $cfg_stitle); }	
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
	if ($topic !~ /$short/i){ prnt("\x0320ERROR\x0F\tTitle not found in topic: ".$short, $ctrlchan, $destsrvr); } else {
		$topic =~ /$short (\d+)/i; #was (\d\d?), broke three digit epnos
		return unless defined($1);
		if ($1 >= $newep || $newep == 720 || $newep == 1080){ return; } else {
			command("notice ".$ctrlchan." Topic was: ".$topic, $ctrlchan, $destsrvr);
			$topic =~ s/$short \d+/$short $newep/i;
			command('cs topic '.$anime.' '.$topic, $anime, $destsrvr);
		}
	}
}

sub sayprev {
	if ($last eq ' '){
		prnt("Nothing has been announced yet.") ;
		return EAT_XCHAT;
	} else {
		command('msg '.get_info('channel').' '.$last);
	}
}

sub dumpcache {
	for (keys %dupe){ delete($dupe{$_}); }
	prnt("Relay cache emptied.");
	return EAT_XCHAT;
}

sub set_airtimes {
	$airtimes_set = 1;
	set_context($anime, $destsrvr);
	my ($cfg,$topic) = ($_[0], get_info('topic'));
	
	my $TIDs = {}; #build a list of unique TIDs to request
	for (values %{$cfg}){
		if ($_->[4] && $_->[2]){
			$TIDs->{$_->[4]} = $_->[2];
		}
	}
	
	for (keys %{$TIDs}){
		my $short = $TIDs->{$_};
		if ($topic =~ /$short (\d+)/i){ # this method will only announce an airtime if the title is in the topic- I'm not too sure how I feel about that :\
			my $epno = $1; $epno++;
			my $info = get_airtime($_, $epno);
			if ($info =~ /^ERROR/){
				prnt($info, $ctrlchan, $destsrvr);
				return;
			}
			
			my $neat_time = [localtime $info->[1]];
			$neat_time = ((sprintf "%02d", $neat_time->[2]).':'.(sprintf "%02d", $neat_time->[1]).' '.(1900 + $neat_time->[5]).'-'.(sprintf "%02d", 1 + $neat_time->[4]).'-'.(sprintf "%02d", $neat_time->[3]));
			
			my $timer = hook_timer($info->[0], sub{ place_timer($info, $epno, $_); return REMOVE; });
			prnt('Timer '.$timer.' added for '.$info->[2].'/'.$info->[3].'/'.$_.' episode '.$info->[5].' at '.$neat_time, $ctrlchan, $destsrvr);
			push @timers, $timer;
		} else {
			next;
		}		
	}
}

sub place_timer {
	my ($info, $epno, $tid) = @_;
	command('bs say '.$anime.' '.$info->[3].' ('.$info->[2].') episode '.$epno.' just finished airing on '.$info->[4], $ctrlchan, $destsrvr);
#	add_airtime($epno, $tid); #oh god the recursion oh god
}
sub dump_timers {
	for (@timers){
		prnt('Unhooking '.$_, $ctrlchan, $destsrvr);
		unhook $_;
	}
	@timers = ( );
	$airtimes_set = 0;
}

sub add_airtime { #this sub can't be trusted don't use it
	my ($epno,$tid) = ($_[0] + 1, $_[1]);
	my $info = get_airtime($tid, $epno);
	if ($info =~ /^ERROR/){
		prnt($info, $ctrlchan, $destsrvr);
		return;
	}
	
	my $neat_time = [localtime $info->[1]];
	$neat_time = ((sprintf "%02d", $neat_time->[2]).':'.(sprintf "%02d", $neat_time->[1]).' '.(1900 + $neat_time->[5]).'-'.(sprintf "%02d", 1 + $neat_time->[4]).'-'.(sprintf "%02d", $neat_time->[3]));
	
	my $timer = hook_timer($info->[0], \&place_timer($info, $epno));
	prnt('Timer '.$timer.' added for '.$info->[2].'/'.$info->[3].'/'.$_.' at '.$neat_time, $ctrlchan, $destsrvr);
	push @timers, $timer;
}

sub get_airtime { #there needs to be a pretty-print return option for the inevitable trigger
	my $tid = shift;
	my $ep = shift;
	my $url = URI->new('http://cal.syoboi.jp/json.php');
	$url->query_form({TID => $tid, Req => 'ProgramByCount', Count => $ep});
	
	my $req = LWP::UserAgent->new()->get($url);
	return 'ERROR '.$req->status_code unless $req->is_success;
	
	my $json = JSON->new->pretty(1)->utf8(1)->decode($req->content)->{'Programs'} || return 'ERROR: Invalid JSON';	
	my $timeout;
	for (sort keys %{$json}){ #should only need the first item from this loop
		my $ttls = get_titles($json->{$_}{'TID'});
		
		return 'ERROR: '.$ttls->[0].' '.$json->{$_}{'Count'}.' already aired.' if time > $json->{$_}{'EdTime'};
		$timeout = $json->{$_}{'EdTime'} - time;
		$timeout *= 1000; #we need milliseconds for hook_timer
		return [$timeout, $json->{$_}{'EdTime'}, $ttls->[0], $ttls->[1], $json->{$_}{'ChName'}, $json->{$_}{'Count'}];
	}	
}

sub get_titles {
	if ($titles{$_[0]}){
		return $titles{$_[0]};
	} else {
		my $syoboi = URI->new('http://cal.syoboi.jp/json.php');
		$syoboi->query_form({TID => $_[0], Req => 'TitleLarge'});
		
		my $req = LWP::UserAgent->new()->get($syoboi);
		return 'ERROR: '.$req->status_code unless $req->is_success;
		
		my $json = JSON->new->pretty(1)->utf8(1)->decode($req->content)->{'Titles'}{$_[0]} || die $!;
		
		return 'ERROR: TID mismatch' unless $_[0] eq $json->{'TID'};
		
		$titles{$json->{'TID'}} = [$json->{'TitleEN'}, $json->{'Title'}];
		
		return $titles{$_[0]};
	}
}