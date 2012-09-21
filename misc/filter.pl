use Modern::Perl;
use File::Slurp;
use File::Path qw'make_path';
use File::MMagic;
# use autodie;
use LWP;
use Cwd;
use URI;

#todo:
#	move config writes INTO the for loops, so crashes don't wreck much
#	errorlog needs to actually be checked JUST SLURP IT LIKE @fourohfours
#
#	gettitle doesn't put puushes in #wat, not that any of them are worth it
#	when gettitle corrects an imgur link, it doesn't go to #wat
#		presumably when he unwraps a tinyurl too?
#
#	rebuild the scheduler?
#		something like 4chan.pl- don't stop between 7-2, but scale back traffic to ~1rq/30min
#			no. that was only to check on threads 404ing
#	switch to LWP::RobotUA
#	make the 4chan timeout a bit more forgiving
#	head everything and push the huge ones back? ##if so, make it a switch. two extra hops is crazy talk
#		-rewrite imgur gallery links to direct img

my $here = cwd;
my $debug = 0;
my $debug_skips = 0;
my $debug_mimes = 1;
my $debug_albums = 0;
my $awful = 0; #enable downloading from sites in $awfulregex
my $sched = 0; #enable (shitty) scheduler
my $awfulregex = qr!.*meme.*|kym-cdn|qkme\.me|lolzbook|collegehumor|ch(ee)?z(comixed|memebase|derp)|pornsfw|shizno_2007!i;

my $checkexts = 1;
my $fixexts = 1;

if ($ARGV[0] && $ARGV[0] eq '-f'){ $sched--; }

# perl -e "sleep 3600*12; system 'copylogs2.bat'; do 'filter.pl';"
# is better than this line:
sleep 5.5*3600 if $sched; #rudimentary scheduler
my $ua = LWP::UserAgent->new(
	show_progress => 1, 
	env_proxy => 0, 
	timeout => 150, 
	agent => 'Mozilla/5.0 (compatible; MSIE 6.0; Windows NT 5.1)' #ie6 on XP
); 
my %links;
my %fourchan;
my %albums;
my @now = localtime; my @mth = (qw'Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec');
my $nowstamp = uc($mth[$now[4]].' '.(sprintf "%02d", $now[3]));

my @fourohfours = read_file('.4chan-404', err_mode => 'quiet');
my @oops = read_file('.errors', err_mode => 'quiet');

#pull old url info from disc
my %where;
open my $text, "<", ".img-old";
while (<$text>){
	chomp;
	s/^\s*|\s*$//g;
	m{^(\S+?) (\w+)$} || die 'broken'; #http://url chan.txt
	$where{$1} = $2;
}
close $text;


#scan #wat for URLs
my @lines = read_file('wat.txt');
#if (glob "wat.2.txt"){ push @lines, read_file('wat.2.txt'); }
say ('channel: wat '.(scalar @lines)) if $debug;
for (@lines){
	s/^(\w+ \d+) \d\d:\d\d:\d\d// || next;
	my $datestamp = uc $1;
	
	s{https?://imgur\.com/gallery/(\w{5})}{http://i.imgur.com/$1.jpg (99KB)}g; #99KB is to fool the next regex
	
	if (! /#(\S+?)\+?(?:\x0F)?: (?:<\S+> |\x03\d\d)?(http\S+)(?:\x0F)? \((\d+)KB\)$/){
		if (/#(\S+?)\+?(?:\x0F)?: (?:<\S+> |\x03\d\d)?(http\S+imgur\S+)(?:\x0F)?$/){
			if (/#(\S+?)\+?(?:\x0F)?: (?:<\S+> |\x03\d\d)?http\S+imgur\.com\/([a-z0-9,]+)(?:\x0F)?$/i){ #comma list pseudoalbums
				my ($chan,$blob) = ($1,$2);
				say $blob if $debug;
				for (split /,/, $blob){
					my $url = "http://i.imgur.com/".$_.".jpg";
					push @{$links{$url}}, $chan;
					say $url if $debug;
				}
				next;
			} else {
				$albums{$2} = $1;
				say "adding $2 to \%albums" if $debug;
				next;
			}
		} else { 
			next;
		}
	}
	my ($chan,$link,$size) = ($1,$2,$3);
	$link .= '.png' if $link =~ /puu\.sh/; #turns out puush ignores any extension on requests
	
	# next unless $link =~ /gif$/;
	
	
	#4chan is rare enough in #wat that I don't have to care how inconsistent this is
	if ($link =~ /4chan\.org/ || $size > 1600){ #get the smaller files out of the way first
		push @{$fourchan{$link}}, $chan;
	} else {
		push @{$links{$link}}, $chan; 
	}
}
#scan the other channels
for (<*.txt>){
	next if $_ eq 'wat.txt';
	next if $_ eq 'wat.2.txt';
	my $name = $_;
	$name =~ s/\.txt$//;
	my @file = read_file($_);
	say ('channel: '.$name.' '.(scalar @file)) if $debug;
	for my $line (@file){
		
		#4chan links #this skips anything linked in the title :(
		$line =~ s/^(\w+ \d+) \d\d:\d\d:\d\d// || next;
		my $datestamp = uc $1;		
		
		for (split /\s+/, $line){
			s{https?://imgur\.com/gallery/(\w{5})}{http://i.imgur.com/$1.jpg}g;
			next unless /(http\S+\.(?:j?pe?n)?g(?:if)?(?=\?|$)|http\S{3}puu\.sh\/\S{4}|imgur.com)/i;
			my $url = $1;
			if ($url =~ /imgur|puu\.sh/ && $url !~ /\.\w{3,4}$/){
				if ($url =~ m{/a/}){
					$albums{$url} = $name;
					say "adding $url to \%albums" if $debug;
					next;
				} elsif ($url =~ /imgur\.com\/([a-z0-9]+,[a-z0-9,]+)/i){ #comma split non-albums
					my ($chan,$blob) = ($1,$2);
					say $blob if $debug;
					for (split /,/, $blob){
						my $url = "http://i.imgur.com/".$_.".jpg";
						push @{$links{$url}}, $chan;
						say $url if $debug;
					}
					next;
				} else {
					$url .= '.png';
				}
			}
			
			next unless $url =~ /maidlab|4chan|gif$/; #I'm sick of weeding through screenshots and shit from 40 channels
			
			if ($url =~ m!4chan\.org|boons\.maidlab|puu\.sh!){ #big shit, shit that's probably a 404
				if ($nowstamp eq $datestamp || $url !~ m!4chan\.org/[abgv]/!){ #can swing a few days for slow boards
					push @{$fourchan{$url}}, $name;
				}
			} else {
				push @{$links{$url}}, $name; 
			}
		}
	}
}

#set up the counter
my @logged = keys %where;
for (keys %links){
	if (@logged ~~ /\Q$_\E/ 
	|| @oops ~~ /\Q$_\E/ 
	|| (!$awful && $_ =~ /$awfulregex|speedtest\.net/)){ 
		say 'skipping '.$_ if $debug_skips;
		delete $links{$_}; 
	}
}
for (keys %fourchan){
	if (@logged ~~ /\Q$_\E/ 
	|| @fourohfours ~~ /\Q$_\E/ 
	|| @oops ~~ /\Q$_\E/ 
	|| (!$awful && $_ =~ /$awfulregex|speedtest\.net/)){ 
		say 'skipping(4) '.$_ if $debug_skips;
		delete $fourchan{$_}; 
	}
}
my $left = ((scalar keys %links)+(scalar keys %fourchan));

open my $outtext, ">>", ".img-old";

for (sort keys %links){ #sort makes it pretty ^_^

	my $name = prepare_file($_,$_,$links{$_}[0]);
	next if $name eq 'xDUPEx';
	
	my $resp = $ua->mirror($_, $links{$_}[0].'/'.$name);
	
	if ($checkexts && $resp->is_success){ #I should be a function!
		my $webmime = $resp->header('Content-Type');
		my $diskmime = File::MMagic->new->checktype_filename($links{$_}[0].'/'.$name);
		
		if ($diskmime ne $webmime && $debug_mimes){
			say 'unmatched mimetypes: '.$name.' expected: '.$webmime.' received: '.$diskmime;
		}
		if ($diskmime !~ /image/ && $debug_mimes){
			say 'not an image: '.$name;
		}
		
		my $newext = $diskmime;
		$newext =~ s{image/jpeg}{.jpg} 
		|| $newext =~ s{image/png}{.png} 
		|| $newext =~ s{image/gif}{.gif} 
		|| $newext =~ s{(^|/)}{.}g; #should filename-safe any erroneous mimetypes
				
		my $newname = $name;
		$newname =~ s/(\.(jpe?g|gif|png))?$//;
		$newname .= $newext; #if I'd put $newext in the regex and failed a match, it'd be gone--rather have double exts
		$newname =~ s/\.JPE?G\.jpg/.jpg/i;
		
		if ($fixexts && $name ne $newname){ #reminder: this slightly breaks the "don't download something twice" checks
			rename $links{$_}[0].'/'.$name, $links{$_}[0].'/'.$newname 
			|| unlink $links{$_}[0].'/File'
			|| say 'rename failed.';
			if ($debug_mimes){ say $name.' => '.$newname; }
		}
	}

	if (! $resp->is_success && $resp->code < 500){ #the 500 errors are usually temporary
		open my $errors, '>>', '.errors';
		say $errors time.' '.$_.' '.$resp->status_line;
		next;
	}
	$where{$_} = $links{$_}[0];
	say $outtext $_.' '.$where{$_};
}

my @plain = (sort keys %fourchan); #what? why?
my @shuffled = ();
while (scalar @plain > 2){ 
	push @shuffled, shift @plain; 
	push @shuffled, pop @plain; 
} 
if (@plain){ 
	push @shuffled, $plain[0]; 
}

for (@shuffled){ #dont sort these, I'm afraid 4chan will decide I'm a scrapebot if I request too many 404s in a row
	
	my $name = prepare_file($_,$_,$fourchan{$_}[0]);
	next if $name eq 'xDUPEx';
	
	my $resp = $ua->mirror($_, $fourchan{$_}[0].'/'.$name);
	
	if ($checkexts && $resp->is_success){
		my $webmime = $resp->header('Content-Type');
		my $diskmime = File::MMagic->new->checktype_filename($fourchan{$_}[0].'/'.$name);
		
		if ($diskmime ne $webmime && $debug_mimes){
			say 'unmatched mimetypes: '.$name.' expected: '.$webmime.' recieved: '.$diskmime;
		} 
		if ($diskmime !~ /image/ && $debug_mimes){
			say 'not an image: '.$name;
		}
		
		my $newext = $diskmime;
		$newext =~ s{image/jpeg}{.jpg} 
		|| $newext =~ s{image/png}{.png} 
		|| $newext =~ s{image/gif}{.gif} 
		|| $newext =~ s{(^|/)}{.}g; #should filename-safe any erroneous mimetypes
				
		my $newname = $name;
		$newname =~ s/(\.(jpe?g|gif|png))?$//;
		$newname .= $newext; #if I'd put $newext in the regex and failed a match, it'd be gone--rather have double exts

		if ($fixexts && $name ne $newname){ #reminder: this slightly breaks the "don't download something twice" checks
			rename $fourchan{$_}[0].'/'.$name, $fourchan{$_}[0].'/'.$newname
			|| unlink $fourchan{$_}[0].'/File'
			|| say 'rename failed';
			if ($debug_mimes){ say $name.' => '.$newname; }
		}
	}
		

	if (! $resp->is_success && $_ !~ /4chan/ && $resp->code < 500){
		open my $errors, '>>', '.errors';
		say $errors time.' '.$_.' '.$resp->status_line;
		next;
	} elsif ($resp->code == 403 && $_ =~ /4chan/){
		push @fourohfours, $_;
		next;
	} elsif (! $resp->is_success){ #don't permanently rule out urls for temp errors
		next;
	}
	$where{$_} = $fourchan{$_}[0];
	say $outtext $_.' '.$fourchan{$_}[0];
}
for (keys %albums){ #ADD DUPE DETECTION
	say "grabbing $_" if $debug_albums;
	
	if ($where{$_}){
		say $_." already exists in ".$where{$_} if $debug_albums;
		next;
	}
	
	if (! glob "$albums{$_}"){
		make_path $albums{$_};
	}
	chdir $albums{$_};
	my $name = $_;
	$name =~ s{^\S+?/a/(\w+)$}{$1};
	
	# if (glob "$name"){ #who cares if it exists? the other script can handle the situation better anyway
		# say "album $name already exists" if $debug;
		# $where{$_} = $albums{$_};
		# say $outtext $_.' '.$albums{$_};
		# next;
	# }
	
	system "imgur $name $_";
	$where{$_} = $albums{$_}; #I'm not sure why I'm updating %where, it's only used at startup
	say $outtext $_.' '.$albums{$_};
	chdir $here;
}

#write remaining new entries
chdir $here;
endit(3);
sub endit {
	# open my $outtext, ">", ".img-old";
	# for (keys %where){
		# say $outtext $_.' '.$where{$_};
	# }
	# close $outtext;
	$/ = "\r\n";
	$" = "\r\n"; #irrelevant but let's stick it here anyway
	write_file('.4chan-404', @fourohfours) if $_[0] >= 2; #broken: doesn't add linebreaks at all
	say ('done '.(sprintf "%02d", (localtime)[2]).':'.(sprintf "%02d", (localtime)[1]));
	exit;
}
sub prepare_file {
	my ($url,$name,$dir) = @_;
	$name =~ s{^.+/([^/]+)$}{$1};
	
	if ($name =~ /^(original|\w{1,3})\.\w{3,4}$/){ #really short/common names 
		$name = ((URI->new($url)->host).'-'.$name);
	}
	$name =~ s/\?\S+$//; #queries
	
	#why am I scraping the dir before every download?
	my @already = read_dir($dir, err_mode => 'quiet');
	push @already, keys %where; #why was this commented?
	if (@already ~~ /\Q$name\E$/){ #dupe detection I hope
		if ($where{$url}){
			say $url.' already exists ('.$where{$url}.')' if $debug_skips;
		} else {
			say $url.' already exists' if $debug_skips;
			$where{$url} = $dir; #wooo lying is fun
		}
		return 'xDUPEx';
	}
	
	say $left.' '.$dir; #countdown
	$left--;
	
	make_path($dir);
	return $name;
}