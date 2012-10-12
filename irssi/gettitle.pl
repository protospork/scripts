use Irssi;
use Irssi::Irc;
use LWP::UserAgent;
use HTML::Entities;	#?
use URI::Escape;
use JSON;
use URI;
use strict;
#use warnings; #there are a lot of ininitialized value warnings I can't be bothered fixing
use utf8;	#?
use feature 'switch';
#try declaring everything in gettitle.pm with 'our' and killing most of this line?
use vars qw(	
	@ignoresites @offchans @mirrorchans @offtwitter @nomirrornicks @defaulttitles @junkfiletypes 
	@meanthings @cutthesephrases @neweggreplace @yield_to $image_chan
	@filesizecomment $largeimage $maxlength $spam_interval $mirrorfile $imgurkey 
	$debugmode $controlchan %censorchans @dont_unshorten $url_shorteners $ver $VERSION %IRSSI
);

#<alfalfa> obviously c8h10n4o2 should be programmed to look for .au in hostmasks and then return all requests in upsidedown text

#<@cephalopods> looks like it tried to parse an HTTP 500 as JSON and was so surprised when it didn't work, it died

$VERSION = "0.1.10";
%IRSSI = (
    authors => 'protospork',
    contact => 'protospork\@gmail.com',
    name => 'url thingy',
    description => 'grabs page titles'
);


my %titlecache; my %lastlink; my %mirrored;
my ($lasttitle, $lastchan, $lastcfgcheck, $lastsend) = (' ', ' ', ' ', (time-5));
my $cfgurl = 'http://dl.dropbox.com/u/48390/GIT/scripts/irssi/cfg/gettitle.pm';

#what are these for, again? <_<
Irssi::signal_add_last('message public', 'pubmsg');
Irssi::signal_add_last('message irc action', 'pubmsg');
Irssi::signal_add_last('message private', 'pubmsg');
Irssi::command_bind('gettitle_conf_reload', \&loadconfig);

my $ua = LWP::UserAgent->new(
	agent => 'Mozilla/5.0 (X11; U; Linux; i686; en-US; rv:1.9.0.13) Gecko/2009073022 Firefox/3.0.13',
	max_size => 60000,
	timeout => 13,
	protocols_allowed => ['http', 'https'],
	'Accept-Encoding' => 'gzip,deflate',
	'Accept-Language' => 'en-us,en;q=0.5',
);	

sub loadconfig {
	my $req = $ua->get($cfgurl, ':content_file' => "/home/proto/.irssi/scripts/cfg/gettitle.pm");	#you have to manually create ~/.irssi/scripts/cfg
	unless ($req->is_success){ print $req->status_line; return; }

	do '/home/proto/.irssi/scripts/cfg/gettitle.pm';
	unless ($maxlength){ print "error loading variables from cfg: $@" }

	print "gettitle: config $ver successfully loaded";
	$lastcfgcheck = time;
}

sub pubmsg {
	my ($server, $data, $nick, $mask, $target) = @_;
	unless (defined($target)){ $target = $nick; }
	
	my $notitle = 0;
	if (grep $target eq $_, (@offchans)){ $notitle++; }	#check channel blacklist
	if ($nick =~ m{(?:Bot|Serv)$|c8h10n4o2}i || $mask =~ /bots\.adelais/i || $target =~ /tokyotosho|lurk/){ $notitle++; }	#quit talking to strange bots
	
	return unless $data =~ m{(?:^|\s)((?:https?://)?([^/@\s>.]+\.([a-z]{2,4}))[^\s>]*|https?://images\.4chan\.org.+(?:jpe?g|gif|png))}ix;	#shit's fucked
	my $url = $1;

	print $target.': '.$url if $debugmode == 1;
	
#load the link as a URI entity and just request the key you need, if possible. 
#	canonizing it should simplify the regexes either way
#	canonizing doesn't change the text so the :c8 commands still work, but they shouldn't be hardcoded to c8h10n4o2
	$url = URI->new($url)->canonical;
	
	if ($url eq ':c8h10n4o2.reload.config' && $target =~ $controlchan){	#remotely trigger a config reload (duh?)
		$server->command("msg $controlchan reloading");
		loadconfig() || return;
		$server->command("msg $controlchan $ver complete.");
		return;
	} elsif ($url eq ':c8h10n4o2.mirror.log' && $target =~ $controlchan){	#send log of mirrored images
		$server->command("msg $controlchan preparing log.");
		sendmirror($nick,$server) || return;
		$server->command("msg $controlchan done.");
	} elsif ($url =~ m=^https?://$url_shorteners=){ #this CANNOT be part of the upcoming elsif chain
		$url = unwrap_shortener($url); #TODO: find a better way than maintaining a list of shorteners
		return if $url eq '=\\';
		if (! grep lc $target eq lc $_, @dont_unshorten){
			$server->command("msg $target $url");
		}
	}
	
	#ANYTHING THAT CHANGES THE URL BEFORE PARSING IT (APIs)
	if ($url =~ m|twitter\.com/.*status(?:es)?/(\d+)\D*\S*$|i){
		$url = 'http://api.twitter.com/1/statuses/show/'.$1.'.json?include_entities=1';
		if (grep $target eq $_, (@offtwitter)){ return; }
		print $url if $debugmode == 1;
	} elsif ($url =~ m[(?:www\.)?youtu(?:\.be/|be\.com/(?:watch\S+v=|embed/))([\w-]{11})]i){
		$url = 'http://gdata.youtube.com/feeds/api/videos/'.$1.'?alt=jsonc&v=2';
	} elsif ($url->can('host') && $url->host eq 'yfrog.com'){
		my $sec = $url->path;
		$sec =~ s!^/z!!; #/z/hash pages seem to crash the script
		$url->path($sec);
		undef $sec;
	} elsif ($url->can('host') && $url->host eq 'www.newegg.com'){ #can is necessary b/c that url regex on line 60 sucks
		my %que = $url->query_form;
#		return unless $que{'Item'};
		return unless $url =~ /item=\S+/i;
		$url->host('www.ows.newegg.com');
		$url->path('/Products.egg/'.$que{'Item'}.'/');
		$url->query_form(undef);
	}
	
	if ($url =~ /pfordee.*jpe?g/i){
		sendresponse('that\'s probably goatse',$target,$server);
		return;
	}
	return if grep $url =~ /\Q$_\E/i, (@ignoresites);	#leave somethingawful alone
	
	if($url !~ /^http/ && $url !~ m|/|) {	# try to avoid tracking site names simply used in conversation #is this still working after the canonization?
		return;
	} elsif ($url !~ /^http/){
		$url = 'http://' . $url;
	}	
	return if $data =~ /[\[<] *\S+ ?[\]>] *\w+/i;	# ignore copypasta
	
	if (exists $lastlink{$nick}){
		if ($url eq $lastlink{$nick} && $target eq $lastchan){ return; }	#spam protection
	}
	$lastlink{$nick} = $url;
	
	#why are we checking file extensions? this is what mimetypes are for
	for my $extrx (@junkfiletypes){	
		return if $url =~ /$extrx$/i;
	}
	
	my $title = '0';
	$title = shenaniganry($url,$nick,$target,$data,$server);
	if (! $title || ($title && $title eq '0')){ 
		$title = get_title($url);
	} else { 
		sendresponse($title,$target,$server) unless $notitle; 
		return; 
	}
	
	#if gettitle failed harder than should be possible
	if (! defined($title) || ! $title){ return; }
	
	#if the URL has the title in it
	if ($url =~ /\w+(?:-|\%20|_|\+)(\w+)(?:-|\%20|_|\+)(\w+)/i && $title =~ /$1.*$2/i && $title !~ /deviantart\.com/){ return; }	#there is a better way to do this. there has to be :(
	
	#if someone's a spammer
	if ($title eq $lasttitle && $target eq $lastchan && time - $lastsend < 120){ return; }
	
	#error fallback titles, index pages, etc
	return if grep $title =~ $_, (@defaulttitles);	
	
	$title = moreshenanigans($title,$nick,$target,$url);
	if (defined $title && $title ne '1' && ! $notitle){ sendresponse($title,$target,$server,$url); }	#I have no idea what is doing the 1 thing dear christ I am a terrible coder
}

sub shenaniganry {	#reformats the URLs or perhaps bitches about them
	my ($url,$nick,$chan,$data,$server) = @_; my $return = 0;
	my $insult = $meanthings[(int rand scalar @meanthings)-1];
	
	if ($url =~ m{^https?://(i\.)?imgur\S+?\w{5,6}(?:\?full)?$}i && $url !~ /(?:jpe?g|gif|png)$/i){
		if ($url =~ m{/a(?:lbums?)?/|gallery|,}){
			$server->command('msg '.$image_chan.' '.xcc($chan,$chan).': '.xcc($nick,$url));
		} else {
			$url .= '.jpg';
			$return = "$url ($insult)";
		}
	} elsif ($url =~ /imagebin\.ca\/view/){
		$url =~ s/view/img/i; $url =~ s/html/jpg/i;
		$return = $url;
	}
	
	if ($url =~ /\.(?:jpe?g|gif|png)\s*(?:$|\?.+)|puu\.sh\/[a-z]+/i){
		if ($url =~ /4chan\.org.+(?:jpe?g|png|gif)/i || $url =~ /s3\.amazonaws\.com/i){ $return = imgur($url,$chan,$data,$server,$nick); return $return; }
		my $this = check_image_size($url,$nick,$chan,$server);
		if ($this && $this ne '0'){ return $this; }
	}		

	if ($url =~ m{(?:bash\.org|qdb\.us)/\??(\d+)}i){ if (($1 % 11) > 8){ $return = "that's not funny :|" }
	} elsif ($url =~ s{youtube\.com/watch#!}{youtube.com/watch?}i || $url =~ s{m\.youtube\.com/\S+v=([^?&=]{11})}{youtu.be/$1}i){ $return = $url." ($insult)";
	} elsif ($url =~ m/ytmnd\.com/i){ $return = 'No.';
	} elsif ($url =~ s{https://secure\.wikimedia\.org/wikipedia/([a-z]+?)/wiki/(\S+)}{http://$1.wikipedia.org/wiki/$2}i){ $return = $url; 
	}	
	
	return $return;
}

#edit titles in ways I can't do with the config file
sub moreshenanigans {
	my ($title,$ass,$target,$url) = @_;
	
	if ($title =~ /let me google that for you/i){ $title = 'FUCK YOU '.uc($ass); }
	$title =~ s/\bwww\.//;
	
	for my $rx (@cutthesephrases){
		$title =~ s/$rx\s*//i;
	}
	
	for (keys %{$censorchans{$target}}){
		my $repl = $censorchans{$target}->{$_};
		if ($title =~ ucfirst $_){ #this block could be replaced by one big regex, but this has to run on 5.10. Also I'm scared.
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
	if(length($title) > $maxlength && $title !~ /^http/ && $url !~ /twitter\.com/){
		my $maxless = $maxlength - 10;
		$title =~ s/(.{$maxless,$maxlength}) .*/$1/;	# looks for a space so no words are broken
		$title .= "..."; # \x{2026} makes a single-width ellipsis
	}
	
	$title;
}
sub unwrap_shortener { # http://expandurl.appspot.com/#api
	my ($url) = @_;
	#valid, but why rely on another service
	# my $head = $ua->get('http://expandurl.appspot.com/expand?url='.uri_escape($url));
	# if (! $head->is_success){ 
		# print 'Error '.$head->status_line if $debugmode; 
		# return '=\\';
	# }
# 
	# my $return = URI->new(JSON->new->utf8->decode($head->content)->{'urls'}->[-1]) || '';
	
	my $req = $ua->head($url);
	if (!$req->is_success){
		print 'Error '.$req->status_line if $debugmode; 
		return '=\\';	
	}
	my $orig_url;
	for ($req->redirects){ #iterate over the redirect chain, but only keep the final one
		if ($_->header('Location') =~ m[nytimes.com/glogin]i){ 
			#NYT paywall redirects you according to some arcane logic that changes every week.
			#Upshot: the final hop is worthless and extremely long.
			last;
		} else {
			$orig_url = $_->header('Location');
		}
	}
	if (! $orig_url){
		$orig_url = $url;
	}
	
	print $url.' => '.$orig_url if $debugmode;
	
	$orig_url = URI->new($orig_url)->canonical;
	if (length $orig_url < 200){
		return $orig_url;
	} elsif (length($orig_url)-length($orig_url->query) < 200){
		$orig_url->query(undef);
		return $orig_url;
	} else { 
		return $orig_url->host;
	}
}

sub get_title {
	my ($url) = @_;	
	if(defined $titlecache{$url}{'url'} && $url !~ /isup\.me|downforeveryoneorjustme/i){ 
		unless (time - $titlecache{$url}{'time'} > 28800){ #is eight hours a sane expiry? I have no idea!
			print '(cached)' if $debugmode == 1;
			return $titlecache{$url}{'url'};
		}
	}
	
	my $page = $ua->get($url);
	if ($debugmode && ! $page->is_success){ print 'Error '.$page->status_line; }
	
#now, anything that requires digging in source/APIs for a better link or more info
	given ($url){
		when (m!yfrog\.com/(?:[zi]/)?\w+/?$!m){
			return $1 if $page->decoded_content =~ m|<meta property="og:image" content="([^"]+)" />|i;
		}
		when (m!tinypic.com/(?:r/|view\.php)!){
			if  ($page->decoded_content =~ m|<link rel="image_src" href="(http://i\d+.tinypic.com/\S+_th.jpg)"/>|i){
				my $title = $1;
				$title =~ s/_th//;
				return $title;
			}
		}
#TODO: BEFORE LETTING JSON.PM TOUCH ANYTHING, VERIFY THAT IT IS application/json
		when (/api\.twitter\.com/){ return twitter($page); }
		when (/gdata\.youtube\.com.+alt=jsonc/){ return youtube($page); }
		when (m{deviantart\.com/art/}){ return deviantart($page); }
		when (m!newegg\S+Product!){ return newegg($page); }
		when (/instagram\.com/){ 
			if ($page->decoded_content =~ m{class="photo" src="(https?://distilleryimage\d+\.instagram\.com/\S+\.jpg)"}){
				print $1 if $debugmode; 
				return $1;
			} 
		}
		default {
			if ($page->decoded_content =~ m|<title>([^<]*)</title>|i){
				my $title = $1;		
				decode_entities($title);
				
				$title =~ s/\s+/ /g;
				$title =~ s/^\s|\s$//;
				
				return $title;
			} else { 
				return "shit\'s broke" unless $page !~ /<title>/; 
			}
		}
	}
}
sub twitter {
	my $page = shift;
	my $junk;
	eval { $junk = JSON->new->utf8->decode($page->decoded_content); }; #never done this before
	if ($@){ return $page->status_line.' (twitter\'s api is broken again)'; } 

	my $text = $junk->{'text'};	#expand t.co links.
	for (@{$junk->{'entities'}{'urls'}}){
		my ($old,$new) = ($_->{'url'},$_->{'expanded_url'});
		$new = $old unless $new;
		$text =~ s/$old/$new/gi;
	}

	my $person = xcc($junk->{'user'}{'screen_name'});

	my $title = $person.' '.$text;
	$title = '<protected account>' if $title eq '<> ';
	return decode_entities($title);
}
sub youtube {
	my $page = shift;
	my $junk = JSON->new->utf8->decode($page->decoded_content) || return 'YouTube - uh-oh ('.$page->status_line.')';
	
	my $title;
	if ($junk->{'data'}{'title'}){
		$title = "\00301,00You\00300,04Tube\017 - ".$junk->{'data'}{'title'};
	} else {
		$title = "\00301,00You\00300,04Tube\017 -".filler_title(); #does this actually work?
	}
	return decode_entities($title);
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
	my $obj = JSON->new->utf8->decode($page->decoded_content) || return 'newegg: '.$page->status_line;
	
	my $rating = $obj->{"ReviewSummary"}{"Rating"} || 'no rating';
	
	my $info = $obj->{"Title"} || 'no info';

	$info =~ s/$_->[0]/$_->[1]/g for @neweggreplace;
	
	my $price = $obj->{"FinalPrice"} || 'no price';
	
	$rating eq 'no rating' 
	? return decode_entities('Newegg - '.$price.' || '.$info) 
	: return decode_entities('Newegg - '.$rating.'/5 Eggs || '.$price.' || '.$info);
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
		if ($url =~ /imgur(?!.+gif$)/i){
			$req->content_length == 669 
			? $return = '404' 
			: $return = 'WITCH';
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
		$server->command('msg '.$image_chan.' '.xcc($chan,$chan).': '.xcc($nick,$url).' ('.(sprintf "%.0f", ($req->content_length/1024)).'KB)');
	}
	$return ? return $return : return; #sure why not
}

sub sendresponse {
	my ($title,$target,$server,$url) = @_;
	print "=> $title" if $debugmode == 1;
	if (time - $lastsend < $spam_interval && $title eq $lasttitle){
#		Irssi::timeout_add_once(($spam_interval * 1000), sendresponse(@_), @_);
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

sub sendmirror {
	my ($nick,$server) = @_;
	
	#build the log from %mirrored
	my $text = "\n"; my $count = 1;	
	for (keys %mirrored){
		my %e;	#what why did I do this
		($e{'nick'},$e{'chan'},$e{'time'},$e{'size'},$e{'delhash'},$e{'count'},$e{'link'}) = @{$mirrored{$_}};
		my $layout =	$e{'time'}.' |1| '.$e{'link'}.' || '.$_.' || http://api.imgur.com/2/delete/'.$e{'delhash'}."\n".
						
						$e{'time'}.' |2| '.(sprintf "%15s", $e{'nick'}).'/'.(sprintf "%-12s", $e{'chan'}).' || '.
						(sprintf "%.0f KB", ($e{'size'}/1024)).' || Posted '.$e{'count'}.'x || '.(sprintf "%03g", $count).' total images.';
		$text .= $layout."\n";
		$count++;
	}
	
	#save it to disk
#	unlink $mirrorfile || $server->command("msg $controlchan can't delete old mirrorfile: $!");
	open my $thing, '>>', $mirrorfile || $server->command("msg $controlchan unable to open logfile for write: $!");
	print $thing $text; close $thing;
	
	#now try to send it
	$server->command("dcc send $nick $mirrorfile");
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
	$stop = 1 if grep $nick =~ /$_/i, (@nomirrornicks);
	for (@mirrorchans){
		$go = 1 if $chan =~ /$_/i;
	}
	if ($stop == 1 || $go == 0){
		print $chan.' isn\'t in mirrorchans so I\'m switching to check size' if $debugmode == 1;
		return check_image_size($url,$nick,$chan,$server);	
	}
	
	my $urlqueries = $url->clone( );
	$url->query(undef);
	
	$msg = ' '.$msg;
	
	#OH GOD YOU FORGOT TO CHECK FOR DUPES
	if ($url =~ /s3\.amazonaws\S+\?\S+/ && defined $mirrored{$url}){	#there has to be a more graceful way to do this
		$mirrored{$url}->[5]++;
		$msg =~ s/$url\S*/$mirrored{$url}->[-1]/g;
		$server->command("msg $controlchan ".xcc($nick).$msg) unless $chan eq $controlchan;
		$server->command("msg $controlchan $chan || $url || \00304Reposted $mirrored{$url}->[5] times.\017");
		return $mirrored{$url}->[-1].' || '.(sprintf "%.0f", ($mirrored{$url}->[3]/1024))."KB || \00304Posted ".$mirrored{$url}->[5]." times.\017"; 
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
	my $resp = $ua->post('http://api.imgur.com/2/upload.json', ['key' => $imgurkey, 'image' => ($url || $urlqueries)]) || print "I can't work out why it would die here";
	#okay what broke
	unless ($resp->is_success){ print 'imgur: '.$resp->status_line; return; }
	#nothing broke? weird.
	my $hash = decode_json($resp->content) || print 'OH NO THERE ISNT ANY CONTENT';
	my ($imgurlink, $delete, $size) = ($hash->{'upload'}->{'links'}->{'original'}, $hash->{'upload'}->{'links'}->{'delete_page'}, $hash->{'upload'}->{'image'}->{'size'});
	#push all this junk into %mirrored
	$mirrored{$url} = [$nick, $chan, time, $size, $delete, 1, $imgurlink];
	$mirrored{$urlqueries} = [$nick, $chan, time, $size, $delete, 1, $imgurlink];
	print	$mirrored{$url}->[0].', '.$mirrored{$url}->[1].', '.$mirrored{$url}->[2].', '.$mirrored{$url}->[3].', '.
			$mirrored{$url}->[4].', '.$mirrored{$url}->[5].', '.$mirrored{$url}->[6] || print 'empty mirror return values';
	
	#return some shit
	$msg =~ s/$url\S*/$mirrored{$url}->[-1]/g;
	$server->command("msg $controlchan ".xcc($nick).$msg) unless $chan eq $controlchan;
	$server->command("msg $controlchan $chan || $url || ".$mirrored{$url}->[4]);
	$server->command('msg '.$image_chan.' '.xcc($chan,$chan).': '.xcc($nick,$mirrored{$url}[-1]).' ('.(sprintf "%.0f", ($mirrored{$url}->[3]/1024)).'KB)') if $image_chan;
	return $mirrored{$url}->[-1].' || '.(sprintf "%.0f", ($mirrored{$url}->[3]/1024)).'KB'; 	
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
loadconfig();
