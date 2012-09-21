use strict;
use warnings;
use utf8;
use Xchat ':all';
use vars qw( %config $cfgpath @blacklist $do_hentai $do_airtime $Ccomnt $Cname $Csize $Curl $Ccomnt $Chntai );
use URI;
use JSON;
use LWP;
use Text::Unidecode; #I would love to use Lingua::JA::Romanize::Japanese, but it won't build on windows. unidecode is core

my $ver = '3.16';
register('relay', $ver, 'bounce new uploads from TT into irc', \&unload);
hook_print('Channel Message', \&whoosh, {priority => PRI_HIGHEST});


prnt("relay $ver loaded");
sub unload { prnt "relay $ver unloaded"; }

my $cfgpath = 'X:\My Dropbox\Public\GIT\scripts\xchat\cfg\xrelay.pm';	#I'm doomed to need to hardcode this
my ($bot, $botchan) = ('TokyoTosho', '#tokyotosho-api');
my ($ctrlchan, $spamchan) = ('#fridge', '#wat');	#$ctrlchan gets a notice for everything announced everywhere but $spamchan.
my ($anime, $music, $destsrvr) = ('#anime', '#wat', 'irc.adelais.net');
my %dupe; my $last = ' '; my $airtimes_set = 0;
my %titles; #cached 'TID => [TitleEN, Title]' from syoboi
my @timers; my %timers;

hook_command('lastannounce', \&sayprev);
hook_command('dumprelaycache', \&dumpcache);

hook_command('dumprelaytimers', \&dump_timers);
hook_command('loadrelaytimers', sub { if ($airtimes_set){ prnt 'dump existing timers first'; return; } else { set_airtimes(); } });
hook_command('listrelaytimers', \&list_timers);

#Sample test line:
#	/recv :TokyoTosho!~TokyoTosh@Tokyo.Tosho PRIVMSG #tokyotosho-api :Torrent367273Anime1[TMD]_Bakuman_-_10_[F7D2E973].mkvhttp://www.nyaa.eu/?page=download&tid=178017213.52MBshut up I'm testing something


sub whoosh {
	my ($speaker, $msg) = ($_[0][0], $_[0][1]); 
	my ($chan,$srvr) = (get_info('channel'),get_info('server'));
	
	unless ($speaker =~ /$bot(?:\[Dev\])?/ && $chan eq $botchan){ return EAT_NONE; }
	
	if ($msg =~ /Torrent(.*?)(.*?)(.*?)(.*?)(.*?)([0-9\.MGK]*i?B)(?:)?(.+)?/){
		my ($rlsid, $cat, $name, $URL, $size) = ($1, $2, $4, $5, $6);
		
		if (exists($dupe{$rlsid})){
			return EAT_NONE;
		}
		$dupe{$rlsid} = $name;
		
		my $comment = '';
		if (defined($7)){ 
			$comment = $7; 
		}
		
		
		$name =~ s/_(?!ST\])/ /g;        #Replace underscore with space, except for the one in GX_ST
		$name =~ s/\.(?!\w{3}$|264)/ /g; #Replace dots with spaces
		$name =~ s/\x{200B}//g;        #200B is zero-width space
		
		$comment =~ s/\x{200B}//g;     #TT throws them in for proper line-wrapping
		$comment =~ s{#(\S+?)\@(\S+\.(?:com|net|org))}{irc://$2/$1}gi; #irc:// links
		
		$URL =~ s/download/torrentinfo/i 
			if $URL =~ /nyaa\.eu/i;			
		$URL =~ s/\(/%28/g; 
		$URL =~ s/\)/%29/g;		
		
		#rounding!
		my ($size,$unit) = ($size =~ /(\d+(?:\.\d+)?)([GMK]i?B)/); 
		$unit =~ s/i//;
		if ($unit eq 'GB'){ $size = sprintf "%.2f", $size; $size .= $unit; }
		elsif ($unit eq 'MB'){ $size = sprintf "%.0f", $size; $size .= $unit; }
		else { $size .= $unit; }
		
		$cat = 'Hentai (Manga)' 
			if $URL =~ /sukebei/i;	
		
		
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
		if ($cat =~ m'^Hentai'){ 
			return EAT_NONE 
				unless $do_hentai == 1; 
			$output = "\x03".$Chntai."Hentai\x0F".$output; 
		}
		my $spam = 'bs say '.$spamchan.' '.$output;
		
		for (@blacklist){
			if ($name =~ /\Q$_\E|HorribleSubs.+\[1080p/i){ #hardcoding is bad but so is my blacklist engine
				return EAT_NONE; 
			} 			
			if (defined($comment) && $comment =~ /\Q$_\E/i){ 
				return EAT_NONE; 
			}
			if ($URL =~ /\Q$_\E/i){ 
				return EAT_NONE; 
			}
		}
		
		
#aaaand we finally get down to the job at hand
		my ($cfg_title, $value);
		while (($cfg_title, $value) = each %config){
			my ($cfg_cat, $cfg_groups, $cfg_stitle, $cfg_blacklist, $cfg_syo_tid) = @$value;
			
			$cat =~ s/Batch/Anime-Batch/;
			next unless $cat =~ /\Q$cfg_cat\E/i; 
			next unless $name =~ /\Q$cfg_title\E/i;
			
			my ($okgroup, $other) = (0, 0);
			
			if (defined($cfg_groups)){ 
				$okgroup = 1 
					if grep $name =~ /\[.*\Q$_\E.*\]/i, (@$cfg_groups);
			}
			else { 
				#we'll still take what we can get
				$okgroup = 1; 
			}
			
			if (defined($cfg_blacklist)){ 
				for (@$cfg_blacklist){
					last if !defined $_;
						
					my ($grp, $term) = (split /:/, $_, 2)
						|| prnt "There's an uhoh in the blacklisting section";
					my $wl = $term =~ s/^\^//;
					
					if ($wl && $okgroup){
						if ($name =~ /\Q$term\E/i){
							#check the next
						}
						else {
							#it's the wrong release from the right group
							$other = 1;
						}
					}
					elsif (! $wl && $okgroup){
						if ($name =~ /\Q$term\E/i){
							#it's the wrong release from the right group
							$other = 1;
						}
						else {
							#check the next
						}
					}
					else {
						#it's the right release from the wrong group
						#I'm reasonably sure this one should never match
						$other = 1
							unless $okgroup == 1;
					}
				}
			}
			
			if ($okgroup == 1 && $other == 0){
			
				if ($cat eq 'Anime'){ 
					command('bs say '.$anime.' '.$output, undef, $destsrvr); 
					$last = $output; 
				}
				elsif ($cat eq 'Music'){ 
					command('msg '.$music.' '.$output, undef, $destsrvr); 
					$last = $output; 
				}
				elsif ($cat =~ m'^Hentai'){ #wait. why isn't $do_hentai in here?
					command($spam, undef, $destsrvr); 
					$last = $output;
					return EAT_NONE; 
				} 
				else { 
					command($spam, undef, $destsrvr); 
					$last = $output; 
					return EAT_NONE; 
				}
				
				command("notice ".$ctrlchan." \x0324".$name." (\x0Fhttp://tokyotosho.info/details.php?id=".$rlsid."\x0324)\x0F", $ctrlchan, $destsrvr);
				
				if ($name =~ /$cfg_title.+?(?:S\d)?.*?([\d\.]+)/i && defined($cfg_stitle) && $cfg_stitle ne ''){ 
					newtopic($1, $cfg_stitle); 
				}	
				
				return EAT_NONE;
				
			}
			else {
				command($spam, undef, $destsrvr);
				$last = $output;
				return EAT_NONE;
			}
		}
		if ($cat =~ /Anime|Batch|^Music$|Manga/){ #does this do anything? shouldn't. maybe I should test it sometime
			command($spam, undef, $destsrvr); 
			$last = $output; 
		} 
		return EAT_NONE;
	}
}

sub newtopic {
	my ($newep, $short) = @_;
	
	$newep =~ s/^0(\d)/$1/; 
	$newep =~ s/\.$//;
	
	set_context($anime, $destsrvr);
	my $topic = get_info('topic');
	if ($topic !~ /$short/i){ 
		prnt("\x0320ERROR\x0F\tTitle not found in topic: ".$short, $ctrlchan, $destsrvr); 
	} else {
		$topic =~ /$short (\d+)/i; #was (\d\d?), broke three digit epnos
		return unless defined($1);
		
		if ($1 >= $newep || $newep == 720 || $newep == 1080){ 
			return; 
		} else {
			$topic =~ s/$short (\d+)/$short $newep/i;
			if ($newep - $1 > 1){ command("notice ".$ctrlchan." Topic was: ".$topic, $ctrlchan, $destsrvr); }
#			command('cs topic '.$anime.' '.$topic, $anime, $destsrvr); #anope is broken
			command('topic '.$topic, $anime, $destsrvr);
			
			#now unset that timer if necessary
			for my $key (keys %timers){
				if ($timers{$key} =~ $short && $timers{$key} =~ /0?$newep$/){
					unhook($_);
#					add_airtime($short, ++$newep); #doesn't exist yet, but this is where it should be called from
				}
			}
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
	set_context($anime, $destsrvr);
	my ($cfg,$topic) = ($_[0], get_info('topic'));
	
	#build a list of unique TIDs to request
	my $TIDs = {}; 
	for (values %{$cfg}){
		my $ntr = $_;
		#my ($tid, $stitle) = ($_->[4], $_->[2]);
		if ($ntr->[4] && $ntr->[2]){
			unless (grep 'horrible' =~ /$_/i, $ntr->[1]){ #no sense announcing ends of simulcasted shows (was this already fixed elsewhere?)
				$TIDs->{$ntr->[4]} = $ntr->[2]; 
			}
		}
	}
	#I could probably combine these two loops but :effort:
	for (keys %{$TIDs}){
		my $short = $TIDs->{$_};
		my $epno;
		if ($topic =~ /$short +(\d+)/i){ # this method will probably announce anything in the config file even if it's old as shit
			$epno = $1; $epno++;
		# } else { #what the hell was I thinking? this just spams a whole bunch of destined-to-fail requests and locks xchat for a year
			# $epno = 1;
		}		
		
		my $info = get_airtime($_, $epno);
		if ($info =~ /^ERROR/){
			prnt($info, $ctrlchan, $destsrvr);
			next;
		} elsif ($info =~ /^EXCEPTION/){
			prnt($info, $ctrlchan, $destsrvr);
			undef $info;
			$info = get_airtime($_, ++$epno);
			if ($info =~ /^ERROR|EXCEPTION/){ #I'm fucking retarded
				prnt($info, $ctrlchan, $destsrvr);
				next;
			}
		}
		
		my $neat_time = [localtime $info->[1]];
		$neat_time = ((sprintf "%02d", $neat_time->[2]).':'.(sprintf "%02d", $neat_time->[1]).' '.(1900 + $neat_time->[5]).'-'.(sprintf "%02d", 1 + $neat_time->[4]).'-'.(sprintf "%02d", $neat_time->[3]));
		
		my $timer = hook_timer($info->[0], sub{ place_timer($info, $epno, $_); return REMOVE; });
		prnt('Timer '.$timer.' added for '.$info->[2].'/'.$info->[3].'/'.$_.' episode '.$info->[5].' at '.$neat_time, $ctrlchan, $destsrvr);

		$timers{$timer} = $short.' '.$epno;
	}
	$airtimes_set = 1; #why is this first instead of last? I'm moving it
}

sub place_timer {
	my ($info, $epno, $tid) = @_;
	command('bs say '.$anime.' '.$info->[3].' ('.$info->[2].') episode '.$epno.' just finished airing on '.$info->[4], $ctrlchan, $destsrvr);
}
sub dump_timers {
	for (keys %timers){
		prnt('Unhooking '.$_, $ctrlchan, $destsrvr);
		unhook $_;
	}

	%timers = ( );
	$airtimes_set = 0;
}
sub list_timers {
	for (keys %timers){
		prnt $_.' :: '.$timers{$_};
	}
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
	for (sort keys %{$json}){ #should only need the first item from this loop ##incorrect, first is not always earliest
		my $ttls = get_titles($json->{$_}{'TID'});
		
		if (! $ttls->[0]){ #section should be valid for both hiragana and katakana. still stumped for kanji
			$ttls->[0] = unidecode($ttls->[1]); 
			$ttls->[0] =~ s![\x{3063}\x{30c3}](.)!my $ch = $1; if(unidecode($ch) =~ /([kstcp])/){ $1.$ch; } else { 'UHOH'; }!e; #sokuon
			if ($ttls->[1] =~ /[\x{3083}\x{3085}\x{3087}\x{30e3}\x{30e5}\x{30e7}]/){ #yoon
				$ttls->[0] =~ s/(?<=[knhmrgbp])i(?=y[aou])//g;
				$ttls->[0] =~ s/siy(?=[aou])/sh/g;
				$ttls->[0] =~ s/tiy(?=[aou])/ch/g;
				$ttls->[0] =~ s/ziy(?=[aou])/j/g;
			}
			$ttls->[0] =~ s/si/shi/g;
			$ttls->[0] =~ s/tu/tsu/g;
			$ttls->[0] =~ s/ti/chi/g;
			$ttls->[0] =~ s/(?<=[aeiou])hu|^hu/fu/g;
			$ttls->[0] =~ s/zi/ji/g;
			$ttls->[0] =~ s/du/zu/g; #tsu with dakuten. rare
		}
		
		if (time > $json->{$_}{'EdTime'}){
			return 'EXCEPTION: '.$ttls->[0].'/'.$ttls->[1].' '.$json->{$_}{'Count'}.' already aired.';			
		}
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