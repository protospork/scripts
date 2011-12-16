use Irssi;
use Irssi::Irc;
use LWP::UserAgent;
use HTML::Entities;	#?
use JSON;
use URI;
use strict;
#use warnings; #there are a lot of ininitialized value warnings I can't be bothered fixing
use utf8;	#?
use feature 'switch';
#try declaring everything in gettitle.pm with 'our' and killing most of this line?
use vars qw( @ignoresites @offchans @mirrorchans @nomirrornicks @defaulttitles @junkfiletypes @meanthings @cutthesephrases @neweggreplace
@filesizecomment $largeimage $maxlength $spam_interval $mirrorfile $imgurkey $debugmode $controlchan %censorchans $ver $VERSION %IRSSI);

$VERSION = "1.7";
%IRSSI = (
    authors => 'protospork',
    contact => 'protospork\@gmail.com',
    name => 'url thingy',
    description => 'grabs page titles'
);


my %titlecache; my %lastlink; my %mirrored;
my ($lasttitle, $lastchan, $lastcfgcheck, $lastsend) = (' ', ' ', ' ', (time-5));
my $cfgurl = 'http://dl.dropbox.com/u/48390/GIT/scripts/irssi/cfg/gettitle.pm';

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
	
	if (grep $target eq $_, (@offchans)){ return; }	#check channel blacklist
	if ($nick =~ m{(?:Bot|Serv)$|c8h10n4o2}i || $mask =~ /bots\.adelais/i || $target =~ /tokyotosho|lurk/){ return; }	#quit talking to strange bots
	
	return unless $data =~ m{(?:^|\s)((?:https?://)?([^/@\s>.]+\.([a-z]{2,4}))[^\s>]*|http://images\.4chan\.org.+(?:jpe?g|gif|png))}ix;	#shit's fucked
	my $url = $1;
	
	print $target.': '.$url if $debugmode == 1;
	
#load the link as a URI entity and just request the key you need, if possible. 
#	canonizing it should simplify the regexes either way
#	canonizing doesn't change the text so the :c8 commands still work, but they shouldn't be hardcoded to c8h10n4o2
	$url = URI->new($url)->canonical;
	
	#todo: given/when this shit up dawg
	if ($url eq ':c8h10n4o2.reload.config' && $target =~ $controlchan){	#remotely trigger a config reload (duh?)
		$server->command("msg $controlchan reloading");
		loadconfig() || return;
		$server->command("msg $controlchan $ver complete.");
		return;
	} elsif ($url eq ':c8h10n4o2.mirror.log' && $target =~ $controlchan){	#send log of mirrored images
		$server->command("msg $controlchan preparing log.");
		sendmirror($nick,$server) || return;
		$server->command("msg $controlchan done.");
	} elsif ($url =~ m|twitter\.com/.*status/(\d+)$|i){	#I can't be fucked to remember if there's a proper place to put these filters
		$url = 'http://api.twitter.com/1/statuses/show/'.$1.'.json?include_entities=1';
		print $url if $debugmode == 1;
	} elsif ($url =~ m[(?:www\.)?youtu(?:\.be/|be\.com/watch\S+v=)([\w-]{11})]i){
		$url = 'http://gdata.youtube.com/feeds/api/videos/'.$1.'?alt=jsonc&v=2';
#	} elsif ($url =~ m!newegg\.com/Product/Product\S+Item=([^&]+)(?:&|$)!){
#		$url = 'http://www.ows.newegg.com/Products.egg/'.$1.'/';
	} elsif ($url->can('host') && $url->host eq 'www.newegg.com'){ #can is necessary b/c that url regex on line 60 sucks
		my %que = $url->query_form;
		$url->host('www.ows.newegg.com');
		$url->path('/Products.egg/'.$que{'Item'}.'/');
		$url->query_form(undef);
	}
	
	if ($url =~ /pfordee.*jpe?g/i){
		sendresponse('that\'s probably goatse',$target,$server);
		return;
	}
	return if grep $url =~ /\Q$_\E/i, (@ignoresites);	#leave somethingawful alone
	
	if($url !~ /^http/ && $url !~ m|/|) {	# try to avoid tracking site names simply used in conversation
		return;
	} elsif ($url !~ /^http/){
		$url = 'http://' . $url;
	}	
	return if $data =~ /[\[<] *\S+ ?[\]>] *\w+/i;	# ignore copypasta
	
	if (exists $lastlink{$nick}){
		if ($url eq $lastlink{$nick} && $target eq $lastchan){ return; }	#spam protection
	}
	$lastlink{$nick} = $url;
	
	for my $extrx (@junkfiletypes){	
		return if $url =~ /$extrx$/i;
	}
	
	my $title = '0';
	$title = shenaniganry($url,$nick,$target,$data,$server);
	if (! $title || ($title && $title eq '0')){ 
		$title = get_title($url);
	} else { 
		sendresponse($title,$target,$server); 
		return; 
	}
	
	#if gettitle failed harder than should be possible
	if (! defined($title) || ! $title){ return; }
	
	#if the URL has the title in it
	if ($url =~ /\w+(?:-|\%20|_|\+)(\w+)(?:-|\%20|_|\+)(\w+)/i && $title =~ /$1.*$2/i && $title !~ /deviantart\.com/){ return; }	#there is a better way to do this. there has to be :(
	
	#if someone's a spammer
	if ($title eq $lasttitle && $target eq $lastchan){ return; }
	
	#error fallback titles, index pages, etc
	return if grep $title =~ $_, (@defaulttitles);	
	
	$title = moreshenanigans($title,$nick,$target,$url);
	if (defined $title && $title ne '1'){ sendresponse($title,$target,$server,$url); }	#I have no idea what is doing the 1 thing dear christ I am a terrible coder
}

sub shenaniganry {	#reformats the URLs or perhaps bitches about them
	my ($url,$nick,$chan,$data,$server) = @_; my $return = 0;
	my $insult = $meanthings[(int rand scalar @meanthings)-1];
	
	if ($url =~ /\.(?:jpe?g|gif|png)\s*(?:$|\?.+)/i){
		if ($url =~ /4chan\.org.+(?:jpe?g|png|gif)/i || $url =~ /s3\.amazonaws\.com/i){ $return = imgur($url,$chan,$data,$server,$nick); return $return; }
		my $this = check_image_size($url);
		if ($this && $this ne '0'){ return $this; }
	}
		
	if ($url =~ m{^http://(i\.)?imgur\.com/\w{5,6}(?:\?full)?$}i && $url !~ /(?:jpe?g|gif|png)$/i){
		$url .= '.jpg';
		$return = "$url ($insult)" unless $url =~ m{/a(?:lbums?)?/|gallery};
	} elsif ($url =~ /imagebin\.ca\/view/){
		$url =~ s/view/img/i; $url =~ s/html/jpg/i;
		$return = "$url ($insult)";
	} elsif ($url =~ /(twitpic|tweetphoto)/i && int(rand(100)) > 75){ $return = lc($1).' sucks.';
	} elsif ($url =~ m{(?:bash\.org|qdb\.us)/\??(\d+)}i){ if (($1 % 11) > 8){ $return = "that's not funny :|" }
	} elsif ($url =~ s{youtube\.com/watch#!}{youtube.com/watch?}i || $url =~ s{m\.youtube\.com/\S+v=([^?&=]{11})}{youtu.be/$1}i){ $return = $url." ($insult)";
	} elsif ($url =~ m/ytmnd\.com/i){ $return = 'No.';
	} elsif ($url =~ s{(?:www\.)?(?:(?<!ca\.)(kotaku|lifehacker|gawker|io9|gizmodo|deadspin|jezebel|jalopnik))\.com/(?:#!)?(\d+)/(\S+)}{ca.$1.com/$2/$3-also-$nick-sucks}i){ int rand 5 >= 4 ? return 'gross' : return 0;
	} elsif ($url =~ s{https://secure\.wikimedia\.org/wikipedia/([a-z]+?)/wiki/(\S+)}{http://$1.wikipedia.org/wiki/$2}i){ $return = $url; 
#	} elsif ($url =~ m{battlelog\.battlefield\.com}){ int rand 10 >= 4 ? $return = 'stop linking that shit' : $return = 'fuck you'; 
	}
	
	
	
	return $return;
}

sub moreshenanigans {	#now, play around with the titles themselves
	my ($title,$ass,$target,$url) = @_;
	
	if ($title =~ /let me google that for you/i){ $title = 'FUCK YOU '.uc($ass); }
	$title =~ s/High Impact Halo Forum and Fansite/HIH: /i;
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
	
	#this chunk shouldn't actually be in use <_<
#	$title =~ s/[(\x{2000}-\x{200F})]|[(\x{2028}-\x{202F})]//g if $title =~ /^youtube/i;
#	$title =~ s/^YouTube/\00301,00You\00300,04Tube\017/i;
	
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
	
	given ($url){
		when (m!yfrog\.com/(?:[zi]/)?\w+/?$!m){
			return $1 if $page->decoded_content =~ $page->decoded_content =~ m|<meta property="og:image" content="([^"]+)" />|i;
		}
		when (m!tinypic.com/(?:r/|view\.php)!){
			if  ($page->decoded_content =~ m|<link rel="image_src" href="(http://i\d+.tinypic.com/\S+_th.jpg)"/>|i){
				my $title = $1;
				$title =~ s/_th//;
				return $title;
			}
		}
		when (/api\.twitter\.com/){ return twitter($page); }
		when (/gdata\.youtube\.com.+alt=jsonc/){ return youtube($page); }
		when (m{deviantart\.com/art/}){ return deviantart($page); }
		when (m!newegg\S+Product!){ return newegg($page); }
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
	unless ($junk = JSON->new->utf8->decode($page->decoded_content)){ return $page->status_line.' (twitter\'s api is broken again)'; } #should I really be decoding decoded_content?

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
	
	return decode_entities('Newegg - '.$rating.'/5 Eggs || '.$price.' || '.$info);
}

sub check_image_size {
	my ($url) = @_;
	return '0' if $url =~ /gif(?:\?.+)?$/i;	#maybe this should be configurable, but it's a fair bet a gif is going to be large
	my $req = $ua->head($url); 
	return 0 unless $req->is_success;	#?
	print $req->content_type.' '.$req->content_length if $debugmode == 1;
	return 0 unless $req->content_type =~ /image/; 
	if ($req->content_type =~ /gif$/i){
		if ($url =~ /imgur/i){
			$req->content_length == 669 
			? return '404' 
			: return 'WITCH';
		} else {
			return 'WITCH';
		}
	} elsif ($req->content_length > $largeimage){
		return $filesizecomment[(int rand scalar @filesizecomment)-1];
	}
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
		return check_image_size($url);	
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
		my ($person,$clr) = ($_[0],0); 
		$clr += ord $_ for (split //, $person); 
		$clr = sprintf "%02d", qw'19 20 22 24 25 26 27 28 29'[$clr % 9];
		$person = "\x03$clr<$person>\x0F";
		return $person;
}
loadconfig();
