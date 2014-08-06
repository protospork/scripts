use strict;
use warnings;
use utf8;
use Xchat ':all';
use vars qw( %config $cfgpath @blacklist $do_hentai $Ccomnt $Cname $Csize $Curl $Ccomnt $Chntai $debug $submit_url);
use URI;
use URI::Escape;
use JSON;
use LWP;
no warnings 'misc';

# how to deal w/shitty services:
#hook activity in target channel, re-send message in own nick if it times out?
# - timers are awful
#periodically check for some kind or usermode or channel +r (confirm that)?
# - +r check before each msg would be okay, otherwise see previous
#manual command to switch from botserv<->local?
# - shitty but better than nothing


my $ver = '4.20';
register('relay', $ver, 'bounce new TokyoTosho uploads into an irc channel', \&unload);
hook_print('Channel Message', \&whoosh, {priority => PRI_HIGHEST});


prnt("relay $ver loaded");
sub unload { prnt "relay $ver unloaded"; }

my $cfgpath = 'X:\My Dropbox\Public\GIT\scripts\xchat\cfg\xrelay.pm';	#I'm doomed to need to hardcode this
my ($bot, $botchan) = ('TokyoTosho', '#tokyotosho-api');
my ($bot2, $botchan2) = ('ServrheV5', '#commie-subs');
my ($ctrlchan, $spamchan) = ('#fridge', '#wat');	#$ctrlchan gets a notice for everything announced everywhere but $spamchan.
my ($anime, $music, $destsrvr) = ('#anime', '#wat', 'irc.galador.org');

my %dupe;
my $last = ' '; #maybe look into making this an array and returning the last #, or last [string] and match
my $botserv = 1;
hook_command('relay_last_announce', \&sayprev);
hook_command('relay_dump_cache', \&dumpcache);
hook_command('relay_through_botserv', \&togglebot);

#Sample test line:
#	/recv :TokyoTosho!~TokyoTosh@Tokyo.Tosho PRIVMSG #tokyotosho-api :Torrent367273Anime1[TMD]_Bakuman_-_10_[F7D2E973].mkvhttp://www.nyaa.eu/?page=download&tid=178017213.52MBshut up I'm testing something


sub whoosh {
	my ($speaker, $msg) = ($_[0][0], $_[0][1]);
	my ($chan,$srvr) = (get_info('channel'),get_info('server'));
	my $commie = 0;

	# if ($speaker =~ /$bot(?:\[Dev\])?/ && $chan eq $botchan){
	# 	#good
	# } elsif ($speaker =~ $bot2 && $chan eq $botchan2){
	# 	debug_say('yes this is commie');
	# 	$commie = 1;
	# } else {
	# 	return EAT_NONE;
	# }

	if ($msg =~ /Torrent(.*?)(.*?)(.*?)(.*?)(.*?)([0-9\.MGK]*i?B)(?:)?(.+)?/ || $commie == 1){
		my ($rlsid, $cat, $name, $URL, $size) = ($1, $2, $4, $5, $6);

		if ($commie){
			$rlsid = time;
			$cat = 'Anime';
			$size = '000.00MB';
			if ($msg =~ /^(.+?) (\d+) released\. Torrent \@ (http\S+)$/){
				$name = '[Commie] '.$1.' - '.$2.' [00000BAD].mkv';
				$URL = $3;
				$URL =~ s/view/download/;
				secret_function($URL);
			} else {
				return EAT_NONE;
			}
		}

		if (exists($dupe{$rlsid})){
			return EAT_NONE;
		}
		$dupe{$rlsid} = $name;

		my $comment = '';
		if (defined($7)){
			$comment = $7;
		}

		($name, $comment, $URL, $cat, $size) = reformat_info($name, $comment, $URL, $cat, $size);

		do $cfgpath;	#load the config
		if ($@){ prnt("$@\x07", $ctrlchan, $destsrvr); return EAT_NONE; }
		if (! %config){ prnt("Relay can't load config\x07file", $ctrlchan, $destsrvr); return EAT_NONE; }
		if (! @blacklist){ prnt("Relay can't load\x07blacklist", $ctrlchan, $destsrvr); return EAT_NONE; }
		if (! $Ccomnt){ prnt("Relay can't load\x07colorscheme", $ctrlchan, $destsrvr); return EAT_NONE; }


		my $output = "\x03".$Cname.$name." \x03".$Csize.$size." \x03".$Curl.$URL."\x0F \x03".$Ccomnt.$comment."\x0F";
		$output =~ s/\s*\x03$Ccomnt *\x0F$//; #just in case there's no comment
		if ($cat =~ m'^Hentai'){
			return EAT_NONE
				unless $do_hentai == 1;
			$output = "\x03".$Chntai."Hentai\x0F".$output;
		}
		my $spam;
		if ($botserv){
			$spam = 'bs say '.$spamchan.' '.$output;
		} else {
			$spam = 'msg '.$spamchan.' '.$output;
		}

		debug_say("Checking $name against general blacklist");
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
			my ($cfg_cat, $cfg_groups, $cfg_stitle, $cfg_blacklist) = @$value;
			#scalar, arrayref, scalar, arrayref

			$cat =~ s/\bBatch/Anime-Batch/; #lets $cat match /Anime/, so full batches get announced

			next unless $cat =~ /\Q$cfg_cat\E/i;
			next unless $name =~ /\Q$cfg_title\E/i;

			#make sure it's an acceptable group if we have a whitelist
			my ($okgroup, $other) = (0, 0);
			debug_say("Checking group on $name");
			if (defined($cfg_groups)){
				$okgroup = 1
					if grep $name =~ /\[.*\Q$_\E.*\]/i, (@$cfg_groups);
			}
			else {
				#we'll still take what we can get
				$okgroup = 1;
			}

			#I suspect this is broken hardcore, but that's the least of my problems right now
			if (defined($cfg_blacklist)){
				debug_say("Checking $name against individual blacklist");
				for (@$cfg_blacklist){
					last if !defined $_;

					my ($grp, $term) = (split /:/, $_, 2) ##references exist for a reason asshole
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



			#now the actual channel announces
			if ($okgroup == 1 && $other == 0){
				if ($cat eq 'Anime'){
					if ($botserv){
						command('bs say '.$anime.' '.$output, undef, $destsrvr);
					} else {
						command('msg '.$anime.' '.$output, undef, $destsrvr);
					}
				$last = $output;
				#don't return, we want the summary in $ctrlchan and possible topic update
				}
				elsif ($cat eq 'Music'){
					command('msg '.$music.' '.$output, undef, $destsrvr);
					$last = $output;
				}
				elsif ($cat =~ m'^Hentai'){ #remember to enable $do_hentai in the cfg if you want this
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
		#this block prints anything that made it through the blacklist but isn't a series listed in the config
		if ($cat =~ /Anime|Batch|^Music$|Manga/){
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

	debug_say("&newtopic triggered for $short");
	set_context($anime, $destsrvr);
	my $topic = get_info('topic');
	if ($topic !~ /$short/i){
		prnt("\x0320ERROR\x0F\tTitle not found in topic: ".$short, $ctrlchan, $destsrvr);
	} else {
		$topic =~ /$short (\d+)/i; #was (\d\d?), broke three digit epnos
		if (! defined($1)){
			debug_say("Title not found in topic, despite being in topic");
			return;
		}

		if ($1 >= $newep || $newep =~ /^((1[02]|4)80|(7|19)20)$/){
			debug_say("Old episode or actually a resolution");
			return;
		} else {
			debug_say("Attempting to change topic.");
			$topic =~ s/$short (\d+)/$short $newep/i;
			if ($newep - $1 != 1){ command("notice ".$ctrlchan." Topic was: ".$topic, $ctrlchan, $destsrvr); }
#			command('cs topic '.$anime.' '.$topic, $anime, $destsrvr); #adelais is broken
			command('topic '.$anime.' '.$topic, $anime, $destsrvr);
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

sub debug_say {
	return 0 unless $debug;
	prnt($_[0], $ctrlchan, $destsrvr);
	return 1;
}

sub togglebot {
	$botserv++;
	$botserv %= 2;
	$botserv 
	? prnt ("now relaying through botserv")
	: prnt ("now relaying through local nick");
	return EAT_XCHAT;
}

sub reformat_info {
	my ($name, $comment, $URL, $cat, $size) = @_;

	debug_say("Rewriting info for $name");
	$name =~ s/_(?!ST\])/ /g;        #Replace underscore with space, except for the one in GX_ST
	$name =~ s/\.(?!\w{3}$|264)/ /g; #Replace dots with spaces
	$name =~ s/\x{200B}//g;          #200B is zero-width space

	$comment =~ s/\x{200B}//g;       #TT throws them in for proper line-wrapping
	$comment =~ s{#(\S+?)\@(\S+\.(?:com|net|org))}{irc://$2/$1}gi; #irc:// links

	$URL =~ s/download/view/i
		if $URL =~ /nyaa\.(se|eu)/i;
	$URL =~ s/\(/%28/g;
	$URL =~ s/\)/%29/g;

	#(not) rounding!
	my ($size,$unit) = ($size =~ /(\d+(?:\.\d+)?)([GMK]i?B)/);
	$unit =~ s/i//;
	if ($unit eq 'GB'){
		$size = sprintf "%.2f", $size;
		$size .= $unit;
	} elsif ($unit eq 'MB'){
		$size = sprintf "%.0f", $size;
		$size .= $unit;
	} else {
		$size .= $unit;
	}

	$cat = 'Hentai (Manga)' #why? I don't remember
		if $URL =~ /sukebei/i;

	return ($name, $comment, $URL, $cat, $size);
}
sub secret_function {
	prnt($submit_url.$_[0], $ctrlchan, $destsrvr);
}