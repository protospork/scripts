use Irssi;
use Irssi::Irc;
use LWP::UserAgent;
use HTML::Entities;
use HTML::TreeBuilder;
# use HTML::ExtractMeta;
use URI::Escape;
use File::Path qw'make_path';
use Net::Twitter::Lite::WithAPIv1_1;
use WebService::GData::YouTube; #psure I'm not using this
use Tie::YAML;
use JSON;
use URI;
use Modern::Perl;
use File::Slurp;
#use warnings; #there are a lot of ininitialized value warnings I can't be bothered fixing
no warnings qw'uninitialized';
use experimental qw(smartmatch switch); #it's complete bullshit that I even have to do this
use utf8;

use vars qw(
	@ignoresites @offchans @mirrorchans @offtwitter @nomirrornicks @defaulttitles @junkfiletypes
	@meanthings @cutthesephrases @neweggreplace @yield_to $image_chan @norelaynicks @ignorenicks
	@filesizecomment $largeimage $maxlength $spam_interval $mirrorfile $imgurkey  %shocksites
	$debugmode $controlchan %censorchans @dont_unshorten $url_shorteners $ver $yt_api_key
	@notruncate $VERSION %IRSSI $tw_consumer_key $tw_consumer_secret $tw_token $tw_token_secret
);

#<alfalfa> obviously c8h10n4o2 should be programmed to look for .au in hostmasks and then return all requests in upsidedown text

$VERSION = "0.2.5";
%IRSSI = (
    authors => 'protospork',
    contact => 'protospork\@gmail.com',
    name => 'url thingy',
    description => 'grabs page titles'
);

#build the directory for the config/memory files if necessary
unless (-e $ENV{HOME}."/.irssi/scripts/cfg/"){ #should I make sure it's a directory as well?
	make_path($ENV{HOME}."/.irssi/scripts/cfg/");
}


#fix the per-nick spam protection: check nick && $lastmsg or whatever


my %titlecache; my %lastlink;
tie my %mirrored, 'Tie::YAML', $ENV{HOME}.'/.irssi/scripts/cfg/mirrored_imgs.po' or die $!;

my ($lasttitle, $lastchan, $lastcfgcheck, $lastsend,$tries) = (' ', ' ', ' ', (time-5),0);

Irssi::signal_add_last('message public', 'pubmsg');
Irssi::signal_add_last('message irc action', 'pubmsg');
Irssi::signal_add_last('message private', 'pubmsg');
Irssi::command_bind('gettitle_conf_reload', \&loadconfig);

my $ua = LWP::UserAgent->new(
	# agent => 'Mozilla/5.0 (X11; U; Linux; i686; en-US; rv:1.9.0.13) Gecko/2009073022 Firefox/3.0.13',
	agent => 'Mozilla/5.0 (Windows NT 6.1; WOW64; rv:17.0) Gecko/20100101 Firefox/17.0',
	max_size => 7000,
	timeout => 6,
	protocols_allowed => ['http', 'https'],
	'Accept-Encoding' => 'gzip,deflate',
	'Accept-Language' => 'en-us,en;q=0.5',
);
my $ismastodon = 0;

sub loadconfig {
	do $ENV{HOME}.'/.irssi/scripts/cfg/gettitle.pm';
		unless ($maxlength){ print "error loading variables from cfg: $@" }

	print "gettitle: config $ver successfully loaded";
	$lastcfgcheck = time;
	return $ver;
}
loadconfig();

sub pubmsg {
	my ($server, $data, $nick, $mask, $target) = @_;
	unless (defined($target)){ $target = $nick; }

	my $notitle = 0;
	if (grep $target eq $_, (@offchans)){ $notitle++; }	#check channel blacklist
	if ($nick =~ m{(?:Bot|Serv)$|c8h10n4o2}i || $mask =~ /bots\.adelais/i || $target =~ /tokyotosho|lurk/){ $notitle++; }	#quit talking to strange bots
	if (grep $nick eq $_, (@ignorenicks)){ $notitle++; }

	#fix this immediately (what is regexp::common using?)
	#return unless $data =~ m{(?:^|\s)((?:https?://)?([^/@\s>.]+\.([a-z]{2,4}))[^\s>]*|https?://(?:boards|images)\.4chan\.org.+(?:jpe?g|gif|png)?)}ix;	#shit's fucked
	return unless $data =~ m{(?:^|\s)(https?://\S+)}ix;
	my $url = $1;

	print $target.': '.$url if $debugmode;
    $ismastodon = 0;

	#load the link as a URI entity and just request the key you need, if possible.
	#	canonizing it should simplify the regexes either way
	$url = URI->new($url)->canonical;

if ($url =~ m=^https?://$url_shorteners=){ #this CANNOT be part of the upcoming elsif chain
		my $url_sh = unwrap_shortener($url); #TODO: stop maintaining a list of shorteners ('maintaining')
		if ($url_sh eq '=\\' || $url_sh eq $url){ return; }
		if (! grep lc $target eq lc $_, @dont_unshorten){
			$server->command("msg $target $url_sh");
		}
	}

	for (keys %shocksites){
		if ($url =~ /$_/i){ #using hash keys as regexes, I should probably just shoot myself
			sendresponse($shocksites{$_},$target,$server);
			return;
		}
	}
	return if grep $url =~ /\Q$_\E/i, (@ignoresites);	#leave somethingawful alone

	if($url !~ /^http/ && $url !~ m|/|) {	# try to avoid tracking site names simply used in conversation
		return;
	} elsif ($url !~ /^http/){
		$url = 'http://' . $url;
	}
	return if $data =~ /[\[<][\x{2}\x{3}0-9, ]*\S+ ?[\]>][\x{2}\x{3}0-9, ]*\w+/i;	# ignore copypasta

	if (exists $lastlink{$nick}){
		if ($url eq $lastlink{$nick} && $target eq $lastchan){ return; }	#spam protection
	}
	$lastlink{$nick} = $url;

	#why are we checking file extensions? this is what mimetypes are for
	for my $extrx (@junkfiletypes){
		return if $url =~ /$extrx$/i;
	}

	my $title = '0';
	my $override = 0;
	($title,$url,$override) = shenaniganry($url,$nick,$target,$data,$server);
	if (! $title || ($title && $title eq '0')){
		$title = get_title($url);
	} else {
		if (! $notitle || $override){
			sendresponse($title,$target,$server);
		}
		return;
	}

	#if gettitle failed harder than should be possible
	if (! defined($title) || ! $title){ return; }

	#if the URL has the title in it
	if ($url =~ /\w+(?:-|\%20|_|\+)(\w+)(?:-|\%20|_|\+)(\w+)/i && $title =~ /$1.*$2/i && $title !~ /deviantart\.com/){ return; }	# wat

	#if someone's a spammer
	#I don't get it, wasn't this already tracked in &sendresponse?
	if ($title eq $lasttitle && $target eq $lastchan && $target ne $controlchan && time - $lastsend < 120){ return; }

	#error fallback titles, index pages, etc
	return if grep $title =~ $_, (@defaulttitles);

	$title = moreshenanigans($title,$nick,$target,$url,$server);

    if ($url =~ /twitter\.com/){
		$notitle = 0;
		$notitle++ if $target ~~ @offtwitter;
	}

	if (defined $title
	&& $title !~ /^1$|shit's broke/ #I have no idea what is doing the 1 thing
	&& ! $notitle){
		sendresponse($title,$target,$server,$url);
	}
}

sub shenaniganry {	#reformats the URLs or perhaps bitches about them
	my ($url,$nick,$chan,$data,$server) = @_; my $return = 0;
	my $insult = $meanthings[(int rand scalar @meanthings)-1];

	# image hosts that can be rewritten as bare links without parsing html
	if ($url =~ m{^https?://(i\.)?imgur\S+?\w{5,7}(?:\?full)?$}i && $url !~ /(?:jpe?g|gif|png)$/i){
		if ($url =~ m{/a(?:lbums?)?/|gallery|,}){
			$server->command('msg '.$image_chan.' '.xcc($chan,$chan).': '.xcc($nick,$url));
		}
	} elsif ($url =~ /imagebin\.ca\/view/){
		$url =~ s/view/img/i;
		$url =~ s/html/jpg/i;
		$return = $url;
	}

	# bare image links, possibly produced by that last block
	if ($url =~ /\.(?:jpe?g|gif|png)\s*(?:$|\?.+)|puu\.sh\/[a-z]+/i){
		my $this = check_image_size($url,$nick,$chan,$server);
		if ($this && $this ne '0'){
			return ($this,$url);
		}
	}

	# API transforms
	if ($url =~ m|[^a-z]twitter\.com/.*status(?:es)?/(\d+)\D*\S*$|i){
		$url = 'TWITTER::'.$1;
		if (grep $chan eq $_, (@offtwitter)){ return; }
	} elsif ($url =~ m[youtu(\.?be|be\.com)|listenonrepeat\.com]i){
		$url =~ s{youtu\.be/([\w-]{11})}{YOUTUBE::$1}i;
		$url =~ s{(?:youtube|listenonrepeat)\.com/(?:watch\S+v=|embed/)([\w-]{11})}{YOUTUBE::$1}i;
	} elsif ($url =~ m{https?://(?:www\.)?amazon\.(\S{2,5})/(?:[a-zA-Z0-9-]+)?/[dg]p(?:/product)?/([A-Z0-9]{10})}){
		$url = 'http://www.amazon.'.$1.'/dp/'.$2;
	} elsif ($url =~ m{boards\.4chan\.org/([^/]+/thread/\d++)}){
		$url = 'http://api.4chan.org/'.$1.'.json';
	} elsif ($url =~ m{store.steampowered.com/app/(\d+)}){
		$url = 'http://store.steampowered.com/api/appdetails?appids='.$1;
	}

	# miscellany
	if ($url =~ m{(?:bash\.org|qdb\.us)/\??(\d+)}i){ if (($1 % 11) > 8){ $return = "that's not funny :|" }
	} elsif ($url =~ m/ytmnd\.com/i){ $return = 'No.';
	} elsif ($url =~ s{https://secure\.wikimedia\.org/wikipedia/([a-z]+?)/wiki/(\S+)}{http://$1.wikipedia.org/wiki/$2}i){ $return = $url;
	} elsif ($url =~ m!gyazo!){
		$return = "gyazo is terrible stop it"
	}


	print $url if $debugmode;
	return ($return,$url);
}

#edit titles in ways I can't do with the config file
sub moreshenanigans {
	my ($title,$ass,$target,$url,$server) = @_;

	if ($title =~ /photobucket/){ $title = imgur($title,$target,$title,$server,$ass); }
	if ($title =~ /let me google that for you/i){ $title = 'FUCK YOU '.uc($ass); }
	$title =~ s/\bwww\.//i;
	$title =~ s/:\s*$//;

	for my $rx (@cutthesephrases){
		$title =~ s/$rx\s*//i;
	}

	for (keys %{$censorchans{$target}}){
		my $repl = $censorchans{$target}->{$_};
		if ($title =~ ucfirst $_){
			$repl = join ' ', map { ucfirst $_ } split / /, $repl;
		} elsif ($title =~ uc $_){
			$repl = uc $repl;
		}

		$title =~ s/$_/$repl/gi;
	}

	$title =~ s/^(.+) - Niconico$/Niconico - $1/;

	#COLORS!
	$title =~ s/^cnn/\00300,04CNN\017/i;
	$title =~ s/^LiveLeak\.com/\00300,04Live\00304,00Leak\017/i;

	$title =~ s/^Newegg(\.com)?/\00302,08Newegg\017/i;
	$title =~ s/^BBC( News)?/\00300BBC\017/i;

    if (length($title) > $maxlength){
        if ($title =~ /^http/){
            #skip
        } elsif (grep $url =~ /$_/, @notruncate){
            #skip
        } elsif ($ismastodon){
            #skip
        } elsif ($title =~ m{pic\.twitter\.com/\w+ \]}){
            #skip
        } else {
            my $maxless = $maxlength - 10;
            $title =~ s/(.{$maxless,$maxlength}) .*/$1/;	# looks for a space so no words are broken
            # $title .= "..."; # \x{2026} makes a single-width ellipsis
            $title .= " \x{07}";
        }
    }

	$title;
}
sub unwrap_shortener { # http://expandurl.appspot.com/#api
	my ($url) = @_;

	return "=\\" if grep $url =~ /\Q$_\E/i, (@ignoresites); #god damnit, google maps

	my $req = $ua->head($url);
	if (!$req->is_success){
		print 'Error '.$req->status_line if $debugmode;
		return '=\\';
	}
	my ($orig_url,$second_last);
	for ($req->redirects){ #iterate over the redirect chain, but only keep the final one
		if ($_->header('Location') =~ m[nytimes.com/glogin]i){
			#NYT paywall redirects you according to some arcane logic that changes every week.
			#Upshot: the final hop is worthless and extremely long.
			last;
		} else {
			$second_last = $orig_url;
			$orig_url = $_->header('Location');
		}
	}
	if (! $orig_url){
		$orig_url = $url;
	}

	print $url.' => '.$orig_url if $debugmode;

	#another script had an issue where the final link was often relative. this either prevents that or breaks everything
	if ($second_last){
		$orig_url = URI->new_abs($orig_url, $second_last)->canonical;
	}

	if (length $orig_url < 200){
		return $orig_url;
	} else {
		# <@zettai_ryouiki> so I can't actually use URI.pm to shorten links because long links actually crash URI.pm
		# $orig_url->query(undef);
		# $orig_url->query_form(undef);
		$orig_url =~ s/\?\S+$//;

		if (length($orig_url) < 200){
			return $orig_url;
		} else {
			return $orig_url->host;
		}
	}
}

sub get_title {
	my ($url) = @_;
	if(defined $titlecache{$url}{'url'} && $url !~ /isup\.me|downforeveryoneorjustme|isitup|4c(?:ha|d)n\S+res/i){
		unless (time - $titlecache{$url}{'time'} > 28800){ #is eight hours a sane expiry? I have no idea!
			print '(cached)' if $debugmode;
			return $titlecache{$url}{'url'};
		}
	}
	if ($url =~ m|TWITTER::|){ return twitter($url); }
	if ($url =~ m|YOUTUBE::(.{11})|){ return youtube($1); }
	my $page = $ua->get($url);
	if (! $page->is_success){
		print 'Error '.$page->status_line if $debugmode;
		return "shit's broke";
	}

	return "shit's broke" if $page->content_type =~ /image/; #fuck if I know

	#now, anything that requires digging in source/APIs for a better link or more info
	given ($url){
		when (m!tinypic.com/(?:r/|view\.php)!){
			if  ($page->decoded_content =~ m|<link rel="image_src" href="(http://i\d+.tinypic.com/\S+_th.jpg)"/>|i){
				my $title = $1;
				$title =~ s/_th//;
				return $title;
			}
		}
		when (m{deviantart\.com/art/}){ return deviantart($page); }
		when (m!amazon\S+[dg]p!){ return; }# amazon($page); }
		when (m!store\.steampowered\.com/api!){ return steam($page, $url); }
		when (m!4chan\S+/(?:res|thread)/!){ return fourchan($page); }
		when (/instagram\.com/){
			 if ($page->decoded_content =~ m{class="photo" src="(https?://distilleryimage\d+\.instagram\.com/\S+\.jpg)"}){
			 	print $1 if $debugmode;
			 	return $1;
			 }
		}
		default {
			my $out;
            if ($page->decoded_content =~ m{<link href='(https://\S+/users/\S+/updates/\S+.atom)' rel='alternate' type='application/atom\+xml'>}
            || $page->decoded_content =~ m{<link title="Single notice \(Atom\)" href="(https://\S+/api/statuses/show/\S+.atom)" type="application/atom\+xml" rel="alternate">}){
                #this is a mastodon || gnusocial toot || status
                return mastodon($page, $url, $1);
            }
            if ($page->decoded_content =~ m|<title>([^<]*)</title>|i){
				$out = $1;
			}
			decode_entities($out);

			$out =~ s/\s+/ /g;
			$out =~ s/^\s|\s$//;

			return $out;
		}
	}
}
sub mastodon {
    my $page = $_[0]; #lwp object
    my $url = $_[1]; #plaintext url we prob don't need
    my $atom = $_[2]; #link to atom/xml api response type thing
    $ismastodon = 1;

    my ($user, $toot, @media);

    print $atom if $debugmode;
    my $slug = $ua->get($atom);
    if ($slug->code eq '200'){
        $slug = $slug->decoded_content;
    } else {
        return $slug->code;
    }
    ($user) = ($slug =~ m{<name>([^<]+)</name>});
    #icosahedron, at least, doesn't have the xml:lang attribute
    ($toot) = ($slug =~ m{<content type="html"(?: xml:lang="\w\w")?>([^<]+)</content>}s);
    $toot = decode_entities($toot);
    $toot =~ s[<br />][ \x{23ce} ]g; #these two collapse linebreaks
    $toot =~ s[</p>\s*<p>][</p><p> \x{23ce} ]sg;

    @media = ($slug =~ m{<link rel="enclosure" type="\S+" length="\d+" href="(https://[^"]+)"/>}g);

    eval { $toot = HTML::TreeBuilder->new_from_content($toot); };
    if ($@ || ! $toot || ! ref $toot || ! $toot->can("look_down")){ return 'masto: '.$toot; }
    $toot = $toot->as_trimmed_text;

    if (@media && $toot !~ m{/media/}){ #some instances don't bother inlining shorlinks in toots, but most(?) do
        return xcc($user).' '.$toot.' '.join(' ', @media);
    } else {
        return xcc($user).' '.$toot;
    }
}
sub twitter {
	my $url = shift;
	# most of this code lifted from https://github.com/isolation/automods/blob/master/AdvTitle.pm#L90
	my $nt = Net::Twitter::Lite::WithAPIv1_1->new(
		consumer_key        => $tw_consumer_key,
		consumer_secret     => $tw_consumer_secret,
		access_token        => $tw_token,
		access_token_secret => $tw_token_secret,
		ssl                 => 1,
        tweet_mode          => 'extended', #this doesn't do anything
	);
	$url =~ s{^TWITTER::(\d+)$}{$1};
	my $status;

	eval { $status = $nt->show_status($url); };
	if ($@ || !$status) { return $@ or return 'wtf'; }
	my $message = $status->{'text'};

	if ($status->{'truncated'} == 1){
        print "why is this truncated";
        if ($status->{'extended_tweet'}->{'full_text'}){
            $message = $status->{'extended_tweet'}->{'full_text'};
        } else {
            if (0){
                $message =~ s/\x{2026}/\x{1F525}/; #replace unicode ellipsis with unicode fire
            } else {
                my $hack = 'https://publish.twitter.com/oembed?url=https://twitter.com/' .
                    $status->{'user'}{'screen_name'} . '/status/' . $url;
                print $hack;
                my $tw_card = $ua->get($hack);
                my $oembed;
                eval { $oembed = JSON->new->utf8->decode($tw_card->decoded_content); };
                if ($@){ return 'this is a disaster: '.$tw_card->status_line.' '.$tw_card->content_type; }

                my $mess = $oembed->{'html'};
                my $tree;
                eval { $tree = HTML::TreeBuilder->new_from_content($mess); };
                if ($@ || ! $tree || ! ref $tree || ! $tree->can("look_down")){ return 'problem! '.$@; }

                my $plaintext = $tree->look_down(_tag => 'p')->as_trimmed_text;

                $plaintext =~ s{pic\.twitter\.com}{https://pic.twitter.com}g;

                $message = $plaintext; #oh boy here we go
            }
        }
    }

	decode_entities($message);
	$message =~ s/\n+|\x{0A}+|\r+/ \x{23ce} /g;
    $message =~ s/\u003Cbr\u003E|<br>/ \x{23ce} /g;
    #collapse multi newlines
    $message =~ s/\x{23ce}(?: \x{23ce})+/\x{23ce}/g;

    $ismastodon = 1; #oops I fucked up the title shortener

	# these two loops replace t.co links with their real targets
	for (@{$status->{'entities'}->{'urls'}}) {
		$message =~ s{$_->{'url'}}{$_->{'expanded_url'}};
		if ($_->{'expanded_url'} =~ m{twitter\.com/\w+/status/(\d+)}){
			#oh fuck oh no
			my $embed = twitter('TWITTER::'.($1));
			$message =~ s{$_->{'expanded_url'}}{[$embed ]};
		}
	}
	for (@{$status->{'entities'}->{'media'}}) {
	# pretty
		$message =~ s{$_->{'url'}}{https://$_->{'display_url'}};
	#convenient
	###FIGURE OUT HOW TO INCLUDE MULTIPLE IMAGES, USE OTHER SCHEME FOR VIDEOS,
	#	$message =~ s{$_->{'url'}}{$_->{'media_url'}:orig};
	}
    # print join ', ', (keys $status->{'user'});
    # ^^ returns:
    # profile_background_tile, profile_background_image_url_https,
    #   has_extended_profile, screen_name, listed_count, geo_enabled,
    #   favourites_count, verified, translator_type, withheld_in_countries,
    #   profile_text_color, profile_link_color, name, follow_request_sent,
    #   time_zone, profile_sidebar_border_color,
    #   profile_background_image_url, id_str, profile_image_url_https, url,
    #   profile_banner_url, location, lang, profile_image_url,
    #   profile_background_color, protected, profile_use_background_image,
    #   id, is_translator, notifications, followers_count, utc_offset,
    #   profile_sidebar_fill_color, statuses_count, default_profile,
    #   following, contributors_enabled, entities, friends_count,
    #   is_translation_enabled, default_profile_image, created_at, description
    my $nazi;
    eval { $nazi = join ', ', @{$status->{'user'}{'withheld_in_countries'}}; };
    if ($nazi =~ /DE|FR/){ #the two countries twitter is legally required to block nazis
        $nazi = "\x{5350}";
    } else { #turkey and whoever else also force blocks
        undef $nazi;
    }
    if ($status->{'user'}->{'verified'} =~ /^true$|^1$/){
		my $mess = xcc($status->{'user'}->{'screen_name'}, '<', 0);
		$mess .= "\x0313\x{2714}\x0F";
        if ($nazi){ $mess .= "\x0313\x{5350}\x0F"; }
		$mess .= (xcc($status->{'user'}{'screen_name'}, $status->{'user'}{'screen_name'}.'>', 0).' '.$message);
		return $mess;
	} else {
        my $mess = xcc($status->{'user'}->{'screen_name'}, '<', 0);
		if ($nazi){ $mess .= "\x0313\x{5350}\x0F"; }
		$mess .= (xcc($status->{'user'}{'screen_name'}, $status->{'user'}{'screen_name'}.'>', 0).' '.$message);
		return $mess;
	}
}
sub youtube {
	my $hash = $_[0];
	my $junk = $ua->get('https://www.googleapis.com/youtube/v3/videos?part=snippet%2CcontentDetails&id='.$hash.'&key='.$yt_api_key);
	return $junk->code unless $junk->is_success;
	my $info;
	eval { $info = JSON->new->utf8->decode($junk->decoded_content); };
	if ($@ || !$info){
		print "omg 1";
		return $@ or return 'wtf';
	} elsif ($info->{'pageInfo'}{'totalResults'}){
		#technically this was a search? dumb
		$info = $info->{'items'}[0];
	} else {
		print "omg 3";
		return 'wtf';
	}

	my $out;
	eval { $out = $info->{'snippet'}{'title'}; };
	if ($@ || !$out){
		print "omg 4";
		return $@ or return 'wtf';
	}

	my $time = $info->{'contentDetails'}{'duration'};
	if ($time !~ /M/){ #fuck you ISO
		$time =~ /H/
			? $time =~ s/(?<=H)/0M/
			: $time =~ s/(?<=T)/0M/;
	} elsif ($time !~ /S/){
		$time .= '0S';
	}
	$time =~ s/(\d+)[HMS]/:$1/g;
	$time =~ s/P(\d+D)?T:?/$1/;
	$time =~ s/^(0*:)//;
	$time =~ s/\b(\d)\b/0$1/g;
	$time =~ s/^(\d\d)$/00:$1/;

	$out = "\00301,00You\00300,04Tube\017 - ".$out." [".$time."]";
	return $out;
}
sub deviantart {
	my $page = shift;
	my $title;
	$page->decoded_content =~ m{id="download-button" href="([^"]+)"|src="([^"]+)"\s+width="\d+"\s+height="\d+"\s+alt="[^"]*"\s+class="fullview}s;
	$title = $1 || $2 || 0;
	return $title unless $title =~ /\.swf$/; #hawk doesn't want videos spoiled or something
}
sub fourchan {
	my $page = shift;
	my $thread;
	eval { $thread = JSON->new->utf8->decode($page->decoded_content); };
	if (! $thread){
		if ($@){ print $@ };
		return '4chan - oops ('.$page->status_line.')'.' '.$page->content_type;
	}

	my ($title, $imgct, $repct) = ('No Title', 0, 0);
	if ($thread->{'posts'}[0]){
		my $op = $thread->{'posts'}[0];

		if ($op->{'sub'}){ $title = $op->{'sub'}; }
		if ($op->{'images'}){ $imgct = $op->{'images'}; }
		if ($op->{'replies'}){ $repct = $op->{'replies'}; }
	}
	return "$title || $repct replies / $imgct images";
}
sub amazon {
	my $page = shift;
	my $obj;
	eval { $obj = HTML::TreeBuilder->new_from_content($page->decoded_content); };
	if ($@ || ! $obj || ! ref $obj || ! $obj->can("look_down")){ return 'amazon: '.$page->status_line.' '.$page->content_type.' '.length($page->content); }

	my $rating;
	eval { $rating = $obj->look_down(_tag => 'span', class => 'crAvgStars'); };
	if ($@ || !$rating){ $rating = 'unrated'; }

	if ($rating && $rating ne 'unrated'){
		$rating = $rating->as_trimmed_text;
		$rating =~ s{^.*?(\d(?:\.\d)?) out of (\d) stars.*$}{$1/$2 Stars}i;
	}

	my $price;
	eval { $price = $obj->look_down(_tag => 'span', id => 'actualPriceValue'); }; #normal items
	if ($@ || !$price){ $price = 'free'; }
	if ($price && $price ne 'free'){
		if ($price->can("as_trimmed_text") && decode_entities($price->as_trimmed_text =~ /[\x{A3}\$]/)){
			$price = $price->as_trimmed_text;
		}
	} elsif ($price eq 'free' && $obj && $obj->can("look_down")) { #seriously, how are these "hurr can't call look_down on undef" errors escaping?
		#this logic takes over for books
		my (@prices,$p);

		eval { $p = $obj->look_down(_tag => 'tbody', id => 'kindle_meta_binding_winner')->look_down(_tag => 'td', class => 'price'); };
		if (!$@){ unshift @prices, $p; }

		eval { $p = $obj->look_down(_tag => 'tbody', id => 'kindle_meta_binding_winner')->look_down(_tag => 'span', class => 'price'); };
		if (!$@){ unshift @prices, $p; }

		eval { $p = $obj->look_down(_tag => 'tbody', id => 'paperback_meta_binding_winner')->look_down(_tag => 'td', class => 'price'); };
		if (!$@){ unshift @prices, $p; }

		eval { $p = $obj->look_down(_tag => 'tbody', id => 'paperback_meta_binding_winner')->look_down(_tag => 'td', class => 'tmm_olpLinks'); };
		if (!$@){ unshift @prices, $p; }

		#TODO:
		#break those^ method chains into a step above and then second look_down in a for loop here
		#figure out what I was talking about in that last line and then do it

		for (@prices){ #it'll go through them (backwards, thanks to unshift), and we'll end up with the last defined price (kindle, I hope)
			$price = $_ if decode_entities($_ =~ /[\x{A3}\$]/);
		}

		$price //= 'oh no';
	} else {
		return "something done broke";
	}
	my $info = $obj->look_down(_tag => 'span', id => 'btAsinTitle');
	if ($info){
		$info = $info->as_trimmed_text;
	} else {
		$info = 'uhoh ('.length($page->content).')';
	}

	return decode_entities('Amazon - '.$rating.' || '.$price.' || '.$info);
}
sub steam {
	# http://store.steampowered.com/api/appdetails?appids=252950
	# http://jsonprettyprint.com/
	my $page = shift;
	my $id = shift;
	$id =~ s/^.+?appids=(\d+)$/$1/;

	my $src = $page->decoded_content;

    #USE A PARSER YOU FUCKER
    #any unicode in names ends up in json \u4HEX format
	$src =~ /name":"([^"]+)".+"initial":(\d+),"final":(\d+),"discount_percent":(\d+)/;
	my ($name, $oprice, $price, $disct) = ($1, $2, $3, $4);
	$price /= 100;
    $oprice /= 100;
	if ($price < $oprice){
        $price = "\$$oprice =(-$disct%)=> \$$price || ";
    } else {
        $price = "\$$price || ";
    }

	if ($price && $name ne $id){
		return $price.$name;
	} else {
		return '┐(\'～`；)┌';
	}
}

sub check_image_size {
	my ($url,$nick,$chan,$server) = @_;
	my $return;
	my $req = $ua->head($url);
	$return = 0 unless $req->is_success;
	print $req->content_type.' '.$req->content_length if $debugmode == 1;
	$return = 0 unless $req->content_type =~ /image/;

	my $webm = 0;

	#shout if it's a magic jpeg
	if ($req->content_type =~ /gif$/i){
		if ($url =~ /imgur(?!.+gif$)/i){ #404 gif is a png now
			$return = $url;
			$return =~ s/jpg$/gifv/;
			$webm = $return;
			$return .= ' ('.$meanthings[(int rand scalar @meanthings)-1].')';
		} elsif ($url =~ /imgur.+gif$/i){
			$return = $url.'v';
			$webm = $return;
		} else {
			$url !~ /\.gif/i
			? $return = 'WITCH'
			: undef $return;
		}
	}

	#now actually do our job
	if (($req->content_type !~ /gif$/ && $req->content_length > $largeimage)
	|| ($req->content_type =~ /gif$/ && $req->content_length > ($largeimage * 2))){ #gifs are big and we all know this
		my $size = $req->content_length;
		$size = sprintf "%.2fMB", ($size / 1048576);
		if ($webm){
			$return = $size.' // '.$return
		} else {
			$return = $size.'? '.$filesizecomment[(int rand scalar @filesizecomment)-1];
		}
	}
	if ($image_chan && $req->content_length){ #I guess facebook 404s are successes? so, we look for >0 length instead
		if ($chan eq $image_chan && grep $nick =~ /$_/i, (@nomirrornicks)){ return $return; }
		$server->command('msg '.$image_chan.' '.xcc($chan,$chan).': '.xcc($nick,$url).' ('.(sprintf "%.0f", ($req->content_length/1024)).'KB)');
	}
	$return ? return $return : return; #sure why not
}

sub sendresponse {
	my ($title,$target,$server,$url) = @_;
	print "=> $title" if $debugmode == 1;
	if (time - $lastsend < $spam_interval && $title eq $lasttitle){
		return;
	}
	$server->command("msg $target $title");
	if ($url && $title !~ /^Error/){
		$titlecache{$url}{'url'} = $title;
		$titlecache{$url}{'time'} = time;
	}
	($lastchan,$lasttitle,$lastsend) = ($target,$title,time);
	if (time - $lastcfgcheck > 86400){ loadconfig(); }
}

sub xcc { #xchat-alike nick coloring
		my ($source,$clr,$string,$brk) = (shift,0);
		if (@_){ $string = shift; }
		else { $string = $source; $brk++; }
        if (@_){ $brk = shift; }
		$clr += ord $_ for (split //, $source);
		$clr = sprintf "%02d", qw'19 20 22 24 25 26 27 28 29'[$clr % 9];
		if ($brk){ $string = "\x03$clr<$string>\x0F"; }
		else { $string = "\x03$clr$string\x0F"; }
		return $string;
}
