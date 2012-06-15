use Modern::Perl;
use File::Slurp;
use File::Path qw'make_path';
use autodie;
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
#	switch to LWP::RobotUA
#	make the 4chan timeout a bit more forgiving
#	head everything and push the huge ones back? ##if so, make it a switch. two extra hops is crazy talk
#	scrape for imgur albums and grab those too
#		-rewrite imgur gallery links to direct img

my $here = cwd;
my $debug = 0;
my $awful = 0;
my $sched = 0;
my $awfulregex = qr!.*meme.*|kym-cdn|qkme\.me|ch(ee)?z(comixed|memebase|derp)|pornsfw|shizno_2007!i;

if ($ARGV[0] && $ARGV[0] eq '-f'){ $sched--; }

# perl -e "sleep 3600*12; system 'copylogs2.bat'; do 'filter.pl';"
# is better than this line:
# sleep 23400; #rudimentary scheduler

my $ua = LWP::UserAgent->new(show_progress => 1, env_proxy => 1, timeout => 150);
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
			$albums{$2} = $1;
			say "adding $2 to \%albums" if $debug;
			next;
		} else { 
			next;
		}
	}
	my ($chan,$link,$size) = ($1,$2,$3);
	
	# if ($link =~ /$awfulregex/ && !$awful){ next; }
	
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
			if ($url =~ /imgur/ && $url !~ /\.\w{3,4}$/){
				if ($url =~ m{/a/}){
					$albums{$url} = $name;
					say "adding $url to \%albums" if $debug;
					next;
				} else {
					$url .= '.jpg';
				}
			}
			# if ($url =~ /$awfulregex/ && !$awful){ next; } 
			
			if ($url =~ m!4chan\.org|boons\.maidlab|puu\.sh!){ #boon's shit is slow lately <_< ##puushes are often huge
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
		say 'skipping '.$_ if $debug;
		delete $links{$_}; 
	}
}
for (keys %fourchan){
	if (@logged ~~ /\Q$_\E/ 
	|| @fourohfours ~~ /\Q$_\E/ 
	|| @oops ~~ /\Q$_\E/ 
	|| (!$awful && $_ =~ /$awfulregex|speedtest\.net/)){ 
		say 'skipping(4) '.$_ if $debug;
		delete $fourchan{$_}; 
	}
}
my $left = ((scalar keys %links)+(scalar keys %fourchan));

open my $outtext, ">>", ".img-old";

for (sort keys %links){ #sort makes it pretty ^_^
	
	my $now = [localtime(time)]; #rudimentary scheduler, act 2
	if ($now->[2] > 6 && $sched){ endit(1); }
	
	my $name = $_;
	$name =~ s{^.+/([^/]+)$}{$1};
	
	if ($name =~ /^(original|\w{1,3})\.\w{3,4}$/){ #really short/common names 
		my $newname = $_;
		$newname =~ s/^.+?(\S{10})$/lc $1/e;
		$name = ((URI->new($_)->host).'-'.$newname);
	}
	
	#why am I scraping the dir before every download?
	my @already = read_dir($links{$_}[0], err_mode => 'quiet');
	push @already, keys %where; #why was this commented?
	if (@already ~~ /\Q$name\E$/){ #dupe detection I hope
		if ($where{$_}){
			say $_.' already exists ('.$where{$_}.')' if $debug;
		} else {
			say $_.' already exists' if $debug;
			$where{$_} = $links{$_}[0]; #wooo lying is fun
		}
		next;
	}
	
	say $left.' '.$links{$_}[0]; #countdown
	$left--;
	
	make_path($links{$_}[0]);
	
	my $resp = $ua->get($_, ':content_file' => $links{$_}[0].'/'.$name);

	if (! $resp->is_success && $resp->code < 500){ #the 500 errors are usually temporary
		open my $errors, '>>', '.errors';
		say $errors time.' '.$_.' '.$resp->status_line;
		next;
	}
	$where{$_} = $links{$_}[0];
	say $outtext $_.' '.$where{$_};
}

#write new entries now so if I have to kill it next stage I'll recover something
# open my $outtext, ">", ".img-old"; #in ovrewrite mode, because we already slurped it into %where
# for (keys %where){
	# say $outtext $_.' '.$where{$_};
# }
# close $outtext;

my @plain = (sort keys %fourchan);
my @shuffled = ();
while (scalar @plain > 2){ 
	push @shuffled, shift @plain; 
	push @shuffled, pop @plain; 
} 
if (@plain){ 
	push @shuffled, $plain[0]; 
}

for (@shuffled){ #dont sort these, I'm afraid 4chan will decide I'm a scrapebot if I request too many 404s in a row
	
	my $now = [localtime(time)]; #rudimentary scheduler, act 2
	if ($now->[2] > 6 && $sched){ endit(2); }
	
	my $name = $_;
	$name =~ s{^.+/([^/]+)$}{$1};
	# $name .= '.jpg' unless $name =~ /\.\w{3,4}/; #puu.sh
	
	if ($name =~ /^(original|\w{1,3})\.\w{3,4}$/){ #really short/common names 
		my $newname = $_;
		$newname =~ s/^.+?(\S{10})$/lc $1/e;
		$name = ((URI->new($_)->host).'-'.$newname);
	}
		
	my @already = read_dir($fourchan{$_}[0], err_mode => 'quiet'); #not necessary, but nice insurance
	# push @already, keys %where;
	
	if (@already ~~ /$name$/){ #dupe detection I hope
		if ($where{$_}){
			say $name.' already exists ('.$where{$_}.')' if $debug;
		} else {
			say $name.' already exists' if $debug;
			$where{$_} = $fourchan{$_}[0];
		}
		next;
	} elsif (@fourohfours ~~ /$_/){
		say $_.' 404ed before last run' if $debug;
		next;
	}
	
	say $left.' '.$fourchan{$_}[0]; #countdown
	$left--;
	
	make_path($fourchan{$_}[0]);
	
	my $resp = $ua->get($_, ':content_file' => $fourchan{$_}[0].'/'.$name);#$ua->mirror($_, $fourchan{$_}[0].'/'.$name);
	
	unless ($name =~ /\.\w{3,4}/){ #this sort of defeats the build-@already-from-disk thing, so probably add a switch
		my $type = $resp->header('Content-Type') || 'image/jpeg'; #also of note: $resp->filename
		if ($type =~ s{image/(jpe?g|png|gif)}{lc $1}e){
			$type =~ s/jpeg/jpg/;
		} else { #looks like puush carries swf or something
			$type = 'jpg';
		}
		rename $fourchan{$_}[0].'/'.$name, $fourchan{$_}[0].'/'.$name.'.'.$type;
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
	say "grabbing $_" if $debug;
	
	if ($where{$_}){
		say $_." already exists in ".$where{$_} if $debug;
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
