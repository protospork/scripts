use Irssi;
use Irssi::Irc;
use LWP::UserAgent;
use HTML::Entities;
use HTML::TreeBuilder;
use HTML::ExtractMeta;
use URI::Escape;
use File::Path qw'make_path';
use Tie::YAML;
use JSON;
use URI;
use Modern::Perl;
use File::Slurp;
#use warnings; #there are a lot of ininitialized value warnings I can't be bothered fixing
no warnings qw'uninitialized';
use utf8;

use vars qw(
	@ignoresites @offchans @mirrorchans @offtwitter @nomirrornicks @defaulttitles @junkfiletypes
	@meanthings @cutthesephrases @neweggreplace @yield_to $image_chan @norelaynicks @ignorenicks
	@filesizecomment $largeimage $maxlength $spam_interval $mirrorfile $imgurkey  %shocksites
	$debugmode $controlchan %censorchans @dont_unshorten $url_shorteners $ver
	@notruncate $VERSION %IRSSI
);

#<alfalfa> obviously c8h10n4o2 should be programmed to look for .au in hostmasks and then return all requests in upsidedown text

$VERSION = "0.2.0";
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
my $cfgurl = 'http://dl.dropbox.com/u/48390/GIT/scripts/irssi/cfg/gettitle.pm';

Irssi::signal_add_last('message public', 'pubmsg');
Irssi::signal_add_last('message irc action', 'pubmsg');
Irssi::signal_add_last('message private', 'pubmsg');
Irssi::command_bind('gettitle_conf_reload', \&loadconfig);

my $ua = LWP::UserAgent->new(
	agent => 'Mozilla/5.0 (X11; U; Linux; i686; en-US; rv:1.9.0.13) Gecko/2009073022 Firefox/3.0.13',
	max_size => 500000,
	timeout => 13,
	protocols_allowed => ['http', 'https'],
	'Accept-Encoding' => 'gzip,deflate',
	'Accept-Language' => 'en-us,en;q=0.5',
);

sub loadconfig {
	my $req = $ua->get($cfgurl, ':content_file' => $ENV{HOME}."/.irssi/scripts/cfg/gettitle.pm");
		unless ($req->is_success){ #this is actually pretty unnecessary; it'll keep using the old config no prob
			print $req->status_line;
			$tries++;
			loadconfig() unless $tries > 2;
		}

	$tries = 0;
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
	return unless $data =~ m{(?:^|\s)((?:https?://)?([^/@\s>.]+\.([a-z]{2,4}))[^\s>]*|https?://(?:boards|images)\.4chan\.org.+(?:jpe?g|gif|png)?)}ix;	#shit's fucked
	my $url = $1;

	print $target.': '.$url if $debugmode;

	#load the link as a URI entity and just request the key you need, if possible.
	#	canonizing it should simplify the regexes either way
	#	canonizing doesn't change the text so the :c8 commands still work, but they shouldn't be hardcoded to c8h10n4o2
	$url = URI->new($url)->canonical;

	if ($url eq ':c8h10n4o2.reload.config' && $target =~ $controlchan){	#remotely trigger a config reload (duh?)
		$server->command("msg $controlchan reloading");
		loadconfig() || return;
		$server->command("msg $controlchan $ver complete.");
		return;
	} elsif ($url =~ m=^https?://$url_shorteners=){ #this CANNOT be part of the upcoming elsif chain
		$url = unwrap_shortener($url); #TODO: stop maintaining a list of shorteners
		return if $url eq '=\\';
		if (! grep lc $target eq lc $_, @dont_unshorten){
			$server->command("msg $target $url");
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
	($title,$url) = shenaniganry($url,$nick,$target,$data,$server);
	if (! $title || ($title && $title eq '0')){
		$title = get_title($url);
	} else {
		sendresponse($title,$target,$server) unless $notitle;
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

	#send the pic if you rehosted it
	if ($title =~ /i\.imgur\.com/ && grep $target eq $_, (@mirrorchans)){
		$notitle = 0;
	} elsif ($url =~ /twitter\.com/){
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
		if ($url =~ /4chan\.org.+(?:jpe?g|png|gif)/i){
			$return = imgur($url,$chan,$data,$server,$nick);
			return ($return,$url);
		}
		my $this = check_image_size($url,$nick,$chan,$server);
		if ($this && $this ne '0'){
			return ($this,$url);
		}
	}

	# API transforms
	if ($url =~ m|twitter\.com/.*status(?:es)?/(\d+)\D*\S*$|i){
		# $url = 'http://api.twitter.com/1/statuses/show/'.$1.'.json?include_entities=1';
		if (grep $chan eq $_, (@offtwitter)){ return; }
	} elsif ($url =~ m[(?:www\.)?(?:youtu(?:\.be/|be\.com|listenonrepeat\.com)/(?:watch\S+v=|embed/))([\w-]{11})]i){
		#youtube API v2 (current stable, doesn't offer any degree of resolution info)
		$url = 'http://gdata.youtube.com/feeds/api/videos/'.$1.'?alt=jsonc&v=2';

		# $url = 'http://gdata.youtube.com/feeds/api/videos/'.$1
			# .'?alt=json&fields=title,yt:hd,media:group(media:content(@duration))';
	} elsif ($url->can('host') && $url->host eq 'www.newegg.com'){ #URI's more trouble than it's worth really
		my %que = $url->query_form;
		return unless $url =~ /item=\S+/i;
		$url->host('www.ows.newegg.com');
		$url->path('/Products.egg/'.$que{'Item'}.'/');
		$url->query_form(undef);
	} elsif ($url =~ m{https?://(?:www\.)?amazon\.(\S{2,5})/(?:[a-zA-Z0-9-]+)?/[dg]p(?:/product)?/([A-Z0-9]{10})}){
		$url = 'http://www.amazon.'.$1.'/dp/'.$2;
	} elsif ($url =~ m{boards\.4chan\.org/([^/]+/res/\d+)(?:#\S+?)?$}){
		$url = 'http://api.4chan.org/'.$1.'.json';
	}

	# miscellany
	if ($url =~ m{(?:bash\.org|qdb\.us)/\??(\d+)}i){ if (($1 % 11) > 8){ $return = "that's not funny :|" }
	} elsif ($url =~ m/ytmnd\.com/i){ $return = 'No.';
	} elsif ($url =~ s{https://secure\.wikimedia\.org/wikipedia/([a-z]+?)/wiki/(\S+)}{http://$1.wikipedia.org/wiki/$2}i){ $return = $url;
	} elsif ($url->can('host') && $url->host eq 'yfrog.com'){
		my $sec = $url->path;
		$sec =~ s!^/z!!; #/z/hash pages seem to crash the script
		$url->path($sec);
		undef $sec;
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

	#truncate
	if (
		length($title) > $maxlength &&
		$title !~ /^http/ && #don't clip URLs
		! grep $url =~ /$_/, @notruncate
	){
		my $maxless = $maxlength - 10;
		$title =~ s/(.{$maxless,$maxlength}) .*/$1/;	# looks for a space so no words are broken
		$title .= "..."; # \x{2026} makes a single-width ellipsis
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
	if(defined $titlecache{$url}{'url'} && $url !~ /isup\.me|downforeveryoneorjustme|isitup|4chan\S+res/i){
		unless (time - $titlecache{$url}{'time'} > 28800){ #is eight hours a sane expiry? I have no idea!
			print '(cached)' if $debugmode;
			return $titlecache{$url}{'url'};
		}
	}

	my $page = $ua->get($url);
	if (! $page->is_success){
		print 'Error '.$page->status_line if $debugmode;
		return "shit's broke";
	}

	return "shit's broke" if $page->content_type =~ /image/; #fuck if I know
	my $meta = HTML::ExtractMeta->new(html => $page->decoded_content);

	#now, anything that requires digging in source/APIs for a better link or more info
	given ($url){
		when (m!photobucket!){
			# return "stop linking photobucket, you cunt";
			return $meta->get_image_url();
			#will be rehosted in &moreshenanigans
		}
		when (m!yfrog\.com/(?:[zi]/)?\w+/?$!m){
			#return $1 if $page->decoded_content =~ m|<meta property="og:image" content="([^"]+)" />|i;
			return $meta->get_image_url();
		}
		when (m!tinypic.com/(?:r/|view\.php)!){
			if  ($page->decoded_content =~ m|<link rel="image_src" href="(http://i\d+.tinypic.com/\S+_th.jpg)"/>|i){
				my $title = $1;
				$title =~ s/_th//;
				return $title;
			}
		}
		when (/twitter\.com/){ return twitter($page, $url); }
		when (/gdata\.youtube\.com.+alt=jsonc/){ return youtube($page); }
		when (m{deviantart\.com/art/}){ return deviantart($page); }
		when (m!newegg\S+Product!){ return newegg($page); }
		when (m!amazon\S+[dg]p!){ return amazon($page); }
		when (m!store\.steampowered\.com/app!){ return steam($page); }
		when (m!4chan\S+/res/!){ return fourchan($page); }
		when (/instagram\.com/){
			# if ($page->decoded_content =~ m{class="photo" src="(https?://distilleryimage\d+\.instagram\.com/\S+\.jpg)"}){
			# 	print $1 if $debugmode;
			# 	return $1;
			# }
			return $meta->get_image_url();
		}
		default {
			my $out;
			if ($meta->get_title()){
				$out = $meta->get_title();
			} elsif ($page->decoded_content =~ m|<title>([^<]*)</title>|i){
				print "%3THIS SHOULDN'T BE HAPPENING";
				$out = $1;
			}
			decode_entities($out);

			$out =~ s/\s+/ /g;
			$out =~ s/^\s|\s$//;

			return $out;
		}
	}
}
sub twitter {
	my $page = shift;
	my $url = shift;
	my $junk;
	# API RETIRED, GO FUCK YOURSELF WITH AN OUTH CERTIFICATE
	# eval { $junk = JSON->new->utf8->decode($page->decoded_content); }; #never done this before
	# if ($@){ return $page->status_line.' (twitter\'s api is broken again)'.' '.$page->content_type; }

	# my $text = $junk->{'text'};
	# $text =~ s/\n/ /g;
	# #expand t.co links.
	# for (@{$junk->{'entities'}{'urls'}}){
	# 	my ($old,$new) = ($_->{'url'},$_->{'expanded_url'});
	# 	$new = $old unless $new;

	# 	#unwrap urls for real
	# 	if ($new =~ $url_shorteners){
	# 		$new = unwrap_shortener($new);
	# 	}

	# 	$text =~ s/$old/$new/gi;
	# }

	# my $person = xcc($junk->{'user'}{'screen_name'});

	# my $title = $person.' '.$text;
	# $title = '<protected account>' if $title eq '<> ';
	# return decode_entities($title);

	# write_file($ENV{HOME}.'/.irssi/twitterwtf.txt', {binmode => ':utf8'}, $page->decoded_content);

	eval { $junk = HTML::TreeBuilder->new_from_content($page->decoded_content); };
	if ($@ || ! $junk || ! ref $junk || ! $junk->can('look_down')){ return 'Twitter is extra broken today ('.$page->status_line.' '.$page->content_type.' '.length($page->content).')'; }

	my ($text,$name);
	eval { $text = $junk->look_down(_tag => 'p', class => qr/tweet-text/); };
	if ($@ || ! $text){ return $page->code.' How Would I Know'; }

	$text = $text->as_trimmed_text;
	$text =~ s/\n|<br(?: \/)?>/ /g;
	$text =~ s/\xA0//g;

	$text =~ s&\bpic\.twitter&http://pic.twitter&g;
	$text =~ s&(http\S+)&unwrap_shortener($1)&gie;

	$name = $url;
	$name =~ s{^.+\.com/|/status.+$}{}g;

	return decode_entities(xcc($name).' '.$text);
}
sub youtube {
	my $page = shift;
	my $junk;
	eval { $junk = JSON->new->utf8->decode($page->decoded_content); }; #->{'entry'}; };
	if ($@){ return 'YouTube - uh-oh ('.$page->status_line.')'.' '.$page->content_type; }

	my $title = "\00301,00You\00300,04Tube\017 - ";
	if ($junk->{'data'}{'title'}){
		$title .= $junk->{'data'}{'title'};
	# if ($junk->{"title"}{'$t'}){
	# 	$title .= $junk->{"title"}{'$t'};
	} else {
		$title .= filler_title();
	}
	my ($length, $rawlen);
	eval { $rawlen = $junk->{'data'}{'duration'}; };
	# eval { $rawlen = $junk->{'media$group'}{'media$content'}[0]{'duration'}; };
	if ($@){ return '[screams internally]'; }

	if ($rawlen){
		$length .=
		(sprintf "%02d", ($rawlen / 3600)).':'. #h
		(sprintf "%02d", (($rawlen / 60) % 60)).':'. #m
		(sprintf "%02d", ($rawlen % 60)); #s
	} else {
		$length = 'Live';
	}
	$length =~ s/^(00:)//;
	$length =~ s/(.+)/ [$1]/;

	my $hd = '';
	eval { $hd = '[HD]' if exists $junk->{'yt$hd'}; };
	if ($@){ return '[screams internally]'; }

	return (decode_entities($title)).$length.$hd;
}
sub deviantart {
	my $page = shift;
	my $title;
	$page->decoded_content =~ m{id="download-button" href="([^"]+)"|src="([^"]+)"\s+width="\d+"\s+height="\d+"\s+alt="[^"]*"\s+class="fullview}s;
	$title = $1 || $2 || 'Deviantart is broken.';
	return $title unless $title =~ /\.swf$/; #hawk doesn't want videos spoiled or something
}
sub newegg {
	my $page = shift;
	my $obj;
	eval { $obj = JSON->new->utf8->decode($page->decoded_content); };
	if ($@){ return 'newegg: '.$page->status_line.' '.$page->content_type; }

	my $rating = $obj->{"ReviewSummary"}{"Rating"} || 'no rating';

	my $info = $obj->{"Title"} || 'no info';

	$info =~ s/$_->[0]/$_->[1]/g for @neweggreplace;

	my $price = $obj->{"FinalPrice"} || 'no price';

	$rating eq 'no rating'
	? return decode_entities('Newegg - '.$price.' || '.$info)
	: return decode_entities('Newegg - '.$rating.'/5 Eggs || '.$price.' || '.$info);
}
sub fourchan {
	my $page = shift;
	my $thread;
	eval { $thread = JSON->new->utf8->decode($page->decoded_content); };
	if ($@){ return '4chan - oops ('.$page->status_line.')'.' '.$page->content_type; }

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

		$price //= 'free';
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
	my $page = shift;
	my $obj;
	eval { $obj = HTML::TreeBuilder->new_from_content($page->decoded_content); };
	if ($@ || ! $obj){ return 'steam: '.$page->status_line.' '.$page->content_type.' '.length($page->content); }

	my $gated = $obj->look_down(_tag => 'div', 'id' => 'agegate_box');
	if ($gated){
		#fallback
		my $title = $obj->look_down(_tag => 'title')->as_trimmed_text;
		$title =~ s/ on Steam//;
		return decode_entities($title);
	} else {
		my $discount = $obj->look_down(_tag => 'div', 'class' => 'discount_pct');
		if ($discount){
			eval { $discount = decode_entities($obj->look_down(_tag => 'div', class => 'game_purchase_action')
				->look_down(_tag => 'div', 'class' => 'discount_original_price')->as_trimmed_text.' '
				.$discount->as_trimmed_text.' => '); };
			if ($@ || !$discount){
				$discount = '';
			}
		} else {
			$discount = '';
		}
		my $price = $obj->look_down(_tag => 'div', 'itemprop' => 'price');
		if ($price){
			$price = decode_entities($price->as_trimmed_text.' || ');
		} else {
			$price = '$UHOH || ';
		}
		my $title = $obj->look_down(_tag => 'div', 'class' => 'apphub_AppName');
		if ($title){
			$title = decode_entities($title->as_trimmed_text);
		} else {
			$title = 'Something Has Gone Wrong';
		}
		return $discount.$price.$title;
	}
}

sub check_image_size {
	my ($url,$nick,$chan,$server) = @_;
	my $return;
	my $req = $ua->head($url);
	$return = 0 unless $req->is_success;
	print $req->content_type.' '.$req->content_length if $debugmode == 1;
	$return = 0 unless $req->content_type =~ /image/;

	#shout if it's a magic jpeg
	if ($req->content_type =~ /gif$/i){
		if ($url =~ /imgur(?!.+gif$)/i){ #404 gif is a png now
			$return = 'WITCH';
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
		$return = $filesizecomment[(int rand scalar @filesizecomment)-1].' ('.$size.')';
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

sub imgur {
	my ($url,$chan,$msg,$server,$nick) = (@_);

	#convert thumb URL to normal one
	$url =~ s/\d+\.thumbs/images/;
	$url =~ s{thumb/(\d+)s\.}{src/$1.};
	$url =~ /^.+\.(\w{3,4})$/;
	$url = URI->new($url);


	#make sure it's okay to do this here
	my ($stop,$go) = (0,0);
	if (grep $nick =~ /$_/i, (@nomirrornicks)){
		$stop = 1;

		#on second thought, pb is annoying for everybody
		if ($url =~ /photobucket/){
			$stop = 0;
		}
	}
	if (grep $chan =~ /$_/i, (@mirrorchans)){
		$go = 1;
	}
	if ($stop == 1 || $go == 0){
		print $chan.' isn\'t in mirrorchans, switching to check size' if $debugmode == 1;
		return check_image_size($url,$nick,$chan,$server);
	}

	$msg = ' '.$msg; #??

	#OH GOD YOU FORGOT TO CHECK FOR DUPES
	if ($url =~ /photobucket/ && defined $mirrored{$url}){	#there has to be a more graceful way to do this
		$mirrored{$url}->[5]++; #repost counter

		$msg =~ s/$url\S*/$mirrored{$url}->[-1]/g;
		$server->command("msg $controlchan ".xcc($nick).$msg) unless $chan eq $controlchan;
		$server->command("msg $controlchan $chan || $url || \00304Reposted $mirrored{$url}->[5] times.\017");

		return $mirrored{$url}->[-1].' || '.(sprintf "%.0f", ($mirrored{$url}->[3]/1024))."KB || \00304Stop using photobucket, you cunt.\017";
	} elsif (defined $mirrored{$url}){
		$mirrored{$url}->[5]++;

		$msg =~ s/$url\S*/$mirrored{$url}->[-1]/g;
		$server->command("msg $controlchan ".xcc($nick).$msg) unless $chan eq $controlchan;
		$server->command("msg $controlchan $chan || $url || \00304Reposted $mirrored{$url}->[5] times.\017");

		return $mirrored{$url}->[-1].' || '.(sprintf "%.0f", ($mirrored{$url}->[3]/1024))."KB || \00304Posted ".$mirrored{$url}->[5]." times.\017";
	}

	#now ...actually do it
	if ($imgurkey eq 'replaceme'){
		print "c8_imgur_key not set";
		return;
	}
	my $resp = $ua->post('http://api.imgur.com/2/upload.json', ['key' => $imgurkey, 'image' => $url, 'caption' => $url])
	|| print "I can't work out why it would die here";
	#okay what broke
	unless ($resp->is_success){ print 'imgur: '.$resp->status_line; return; }
	#nothing broke? weird.

	my $hash;
	eval { $hash = decode_json($resp->content) };
	if ($@){ print 'OH NO THERE ISNT ANY CONTENT'; }

	my ($imgurlink, $delete, $size) = ($hash->{'upload'}->{'links'}->{'original'}, $hash->{'upload'}->{'links'}->{'delete_page'}, $hash->{'upload'}->{'image'}->{'size'});
	#push all this junk into %mirrored
	$mirrored{$url} = [$nick, $chan, time, $size, $delete, 1, $imgurlink];
	tied(%mirrored)->save;
	print	$mirrored{$url}->[0].', '.$mirrored{$url}->[1].', '.$mirrored{$url}->[2].', '.$mirrored{$url}->[3].', '.
			$mirrored{$url}->[4].', '.$mirrored{$url}->[5].', '.$mirrored{$url}->[6] || print 'empty mirror return values';

	#return some shit
	$msg =~ s/$url\S*/$mirrored{$url}->[-1]/g;
	$server->command("msg $controlchan ".xcc($nick).$msg) unless $chan eq $controlchan;
	$server->command("msg $controlchan $chan || $url || ".$mirrored{$url}->[4]);

	$server->command('msg '.$image_chan.' '.xcc($chan,$chan).': '.xcc($nick,$mirrored{$url}[-1]).' ('.(sprintf "%.0f", ($mirrored{$url}->[3]/1024)).'KB)') if $image_chan;

	my $return = $mirrored{$url}->[-1].' || '.(sprintf "%.0f", ($mirrored{$url}->[3]/1024)).'KB';
	if ($url =~ /photobucket/){
		$return .= " || \00304Stop using photobucket, you cunt.\017";
	}

	return $return;
}
sub filler_title {
	my $req = $ua->get('http://www.jocchan.com/stuff/IGeNerator/');
	return ' uhoh' unless $req->is_success;
	my $line = $req->content;
	$line =~ s{^.+data-text="(.+) #IGeNerator.+$}{$1}s || return ' Oh No!';
	return ' '.$line;
}
sub xcc { #xchat-alike nick coloring
		my ($source,$clr,$string,$brk) = (shift,0);
		if (@_){ $string = shift; }
		else { $string = $source; $brk++; }
		$clr += ord $_ for (split //, $source);
		$clr = sprintf "%02d", qw'19 20 22 24 25 26 27 28 29'[$clr % 9];
		if ($brk){ $string = "\x03$clr<$string>\x0F"; }
		else { $string = "\x03$clr$string\x0F"; }
		return $string;
}
