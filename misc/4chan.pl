use Modern::Perl;
use LWP;
use File::Path qw(make_path);
use Cwd qw(cwd);
use Digest::MD5;
use File::Copy qw(copy);
my $root_dir = cwd;

#perl fourchan.pl -rwfhbis -t:[minutes] -n:[name_no_spaces] [url]

#prob can't use t and n at the same time
#	#called without 'perl ' is an instant 404 :\

###########die if a thread hits the image limit (does each board have a different limit?)
#	/h/ seems to limit above 132 [4chanarchive]	#deleted pics?
#	/s/ is 127
#	/hr/ 127
###########
#automatic delete & re-download files with bad hashes	#done. does it actually work? dunno.
#
#more reliably strip invalid chars from filenames #lolwindows
#
#check the filesize on the html and override $takeyourtime if it's been idle for too long (not on /hr/)	#what?
#
#add a way to force another check instead of waiting for the sleep to finish
#	is this even possible? surely not with sleep
#
#a way to create "default settings" depending on board?		#defaults? there are THREE USEFUL SETTINGS, total.
#
#"TIME SINCE LAST IMAGE DOWNLOAD" LINE IS WONKY	#is it still?
#
#IT'S SKIPPING THE OP AGAIN		#no it isn't
#
#switch that @ARGV disaster with Opt::Imistic
#
#proxy cache support shouldn't be hardcoded on; the proxy address shouldn't be hardcoded either

my ($rename, $numtries, $thread, $numbering, $immortal, $timeout, $threadtitle, $md5filenames, $nevershorten, $takeyourtime, $imagelimit) =
  (0, 999999, 0, 1, 0, 86400, 0, 0, 0, 0, 0);
for (@ARGV) {
	if ($_ =~ s/^-//) {    #option switches
		if ($_ =~ /(.*?)r/) {
			$rename = 1 unless $1 =~ /:/;
		}                  #'r'enames files to their 'original' names	#this might as well just be the default
		if ($_ =~ /(.*?)s/) { $numtries = 1 unless $1 =~ /:/; }    #'s'ingle scrape (don't loop)
		if ($_ =~ /(.*?)i/) { $immortal = 1 unless $1 =~ /:/; }    #'i'mmortal (normally 24 hours with no activity should kill the script)
		if ($_ =~ /t:(\d+)/) {
			$timeout = $1 * 60;
		}    #'t'imeout (in minutes) before the script gives up on an inactive thread	#I'm not sure why this exists
		if ($_ =~ /n:(\w+)/) { $threadtitle  = $1 }                     #'n'ame of thread [default is thread num]
		if ($_ =~ /(.*?)b/)  { $numbering    = 0 unless $1 =~ /:/; }    #'b'are, no added numbering	#THIS MODE MUST BE USED ON /B/ #why?
		if ($_ =~ /(.*?)f/)  { $nevershorten = 1 unless $1 =~ /:/; }    #'f'ull filenames (by default a filename above 40char is shortened)
		if ($_ =~ /(.*?)h/) {                                           #'h'ashes (md5) for filenames
			unless ($1 =~ /:/) {                                        #	-enables -b
				$md5filenames = 1;
				$numbering    = 0;
			}
		}
		if ($_ =~ /(.*?)w/) { $takeyourtime = 1 unless $1 =~ /:/; }  #'w'ait. triples scrape interval and only grabs one image per 2.5 hours
	} elsif ($_ =~ /^http/) {
		$thread = $_;
	} else {
		exit print "invalid argument: $_";
	}
}

if (!$thread) {
	exit print "don't see a URL";
}

my ($count, $lastDL, $firstscrape, $offline) = (time, 1, 1, 0);
while ($numtries > 0) {
	body();    #was it really that easy!?
	$numtries--;
	$firstscrape = 0;
	unless ($numtries == 0) { say $numtries. " tries remaining"; }
	else                    { say "Done."; done(); }

	my @now = localtime();

	if ($count == 127 && $thread =~ m{/(s|hr)/}) { $imagelimit = 1; }
	if ($offline == 1) { sleep 3600; }
	elsif ((time - $lastDL) > $timeout && $lastDL != 1 && $immortal == 0) {
		say "reached timeout length without any new images posted";
		done();
	} elsif (($now[2] < 2 || $now[2] > 7) && $takeyourtime == 1) {
		sleep 1800;
	} else {
		sleep 600;
	}
}

sub body {
	chdir $root_dir;
	$offline = 0;
	my $browser = LWP::UserAgent->new;
	$browser->proxy('http', 'http://192.168.250.125:3128/');
	my $page = $browser->get($thread);
	unless ($page->is_success) {
		my $uhoh = $browser->get('http://www.4chan.com'); #I wonder how squid will affect this. hm.
		if ($uhoh->is_success) {
			say "404 at " . time;
			done();
		} else {
			say "4chan is down. Checking hourly.";
			$offline = 1;
			return;
		}
	}

	my $albumname = $thread;
	$albumname =~ s/^.+(?:org|com|net|info)\///i;
	$albumname =~ s/\/res//i;                                          #remove everything except "[boardname]/[threadnumber]"
	$albumname =~ s[/.+$][/$threadtitle] unless $threadtitle eq '0';
	say $albumname;
	make_path($albumname);
	chdir $albumname;

	my $html = $page->content;
	$html =~ s/<script.+?\/script>//gis;                               #remove the captcha and junk

	my @junk = $html =~
m{(<span class="filesize">File : .+?src=http.+?name=".+?class="filetitle">.+?class="postername".+?<span id=".+?class="quotejs">.+?</blockquote>|class="quotejs">[\dx]+</a>.+?<span class="filesize">.+?</blockquote>)}gsi
	  ;                                                                #fuckin /b/ with those Xes
	exit print "bad regex ln123 or page GET failed" unless exists $junk[0];    #exists on an array is deprecated, I believe

	#	open TEST, '>', 'test.txt';	print TEST (join "\n\n", @junk); close TEST;

	my (%realname, %filesize, @URLs, %md5, %postnum);
	$count = 0;
	for my $trash (@junk) {
		my ($link) = $trash =~ m{href="(http://\S+/src/\d+\.(?:jpe?g|gif|png))"}si;
		if ($link eq '') { exit print "regex fail 116"; }
		push @URLs, $link;
		if ($rename == 1) {                                                   #conditionally restore original names to images
			($realname{$link}) = $trash =~ m{title="([^"]+?)"}si;
			$realname{$link} =~ s/\.+/./g;
			$realname{$link} =~ s/ +|\?/_/g;
		} else {
			($realname{$link}) = $link =~ m{\S+/(\d+\.\w+)$};
		}

		($filesize{$link}) = $trash =~ m{\(\s*(\d+(?:\.\d+)?\s*[KM]?B)}si;
		($md5{$link})      = $trash =~ m{md5="(\S+)=="}si;
		($postnum{$link}) =
		  $trash =~ m{"quotejs">\d+(\d\d\d\d\d)(?:XXX)?</a}si;    #hopefully five numbers plus the filename itself can avoid collisions

		if ((length($realname{$link}) > 38 && $nevershorten == 0) || $md5filenames == 1) {    #shorten filename to md5 if it's long
			my $t = $realname{$link};
			$t =~ s/.+\.(\w+)$/.$1/;
			$realname{$link} = $md5{$link} . $t;
			$realname{$link} =~ s/\//_/g;
		}

		$count++;    #unreliable. can't handle deleted files and I've no idea how to make it so
		if ($numbering == 1) {    #prepend file number, maybe

			#			$realname{$link} = ((sprintf "%03d", $count).'_'.$realname{$link});
			$realname{$link} =
			  $postnum{$link} . '_'
			  . $realname{$link
			  };    #should keep the files in sorted order, except for cases where the ten-thousands-place rolls around to 0. hmm
		}
		printf "%50s: ", $realname{$link};
		say($md5{$link} . " :" . (sprintf "%03d", $count) . ": " . $filesize{$link});

		$html =~ s/favicon-ws/favicon/;    #I just don't like the blue clover >_>

		$html =~ s/\d+\.thumbs/images/sig;
		$html =~ s/thumb/src/sig;
		$html =~ s/(\d+)s(?=\.jpg)/$1/sig;    #convert thumbnail elements to use full-size local images
		my $noidea = $link;
		$noidea =~ s/\w{3,4}$/jpg/;
		$html   =~ s/$noidea/$link/g;
		$html   =~ s/$link/$realname{$link}/g;

		$link = '';                           #I must not understand scoping
	}

	my @files = glob "*";
	my %hashondisk;
	for my $wang (@files) {                   #find which (if any) files are already downloaded, hash them
		unless (grep $wang eq $_, (values %realname)) { next; }    #I can barely wrap my head around this - Intermediate Perl 4.1
		next if $wang =~ /html$/;
		open my $file, $wang || die "this: $!";
		binmode($file);
		my $md5 = Digest::MD5->new;
		while (<$file>) { $md5->add($_); }
		close $file;
		$hashondisk{$wang} = $md5->b64digest;
	}

	my $ugh;
	for (@URLs) {                                                  #compare hashes from local files with those of the html
		$ugh = $realname{$_};
		if (defined $hashondisk{$ugh} && $hashondisk{$ugh} ne '' && $hashondisk{$ugh} ne $md5{$_}) {

			#			say "Warning: $ugh has hash $hashondisk{$ugh} on disk but $md5{$_} according to site";
			print 'Hash mismatch: ' . $ugh;
			unlink $ugh || exit print ' error deleting ' . $ugh;
			say ' ...deleted.';
		}
	}
	my @now = localtime();
	for my $WHY (@URLs) {                                          #grab images if you haven't already
		if (grep $realname{$WHY} eq $_, @files) {
			printf("%50s -> %-42s :: Duplicate\n", $WHY, $realname{$WHY});
			next;
		}
		if (($now[2] > 7 || $now[2] < 2) && (time - $lastDL) < 3600 && ($firstscrape == 0 || $takeyourtime == 1)) { next; }
		my $what = $browser->get($WHY, ':content_file' => $realname{$WHY});
		unless ($what->is_success) { say "Warning: " . $what->status_line . " for $WHY"; }
		else                       { printf("%50s -> %-42s :: Complete\n", $WHY, $realname{$WHY}); }
		$lastDL = time;
	}

	$html =~ s{\S+(affil(?#liate)|jlist|recaptcha)\S+}{}sig;       #remove ads and captcha, poorly
	print(  "Time since last image download: "
		  . sprintf("%02d", int((time - $lastDL) / 3600)) . ':'
		  . sprintf("%02d", int((time - $lastDL) / 60) % 60) . ':'
		  . sprintf("%02d", ((time - $lastDL) % 60)) . ' :: ')
	  unless $lastDL == 1;                                         #I'm sure there's a shorthand for most of this
	if ($count != (scalar(@files) - 1)) {
		print((($count - scalar(@files)) + 2) . ' known files left to download :: ');
	}                                                              #something weird about negative numbers?
	if (@junk) { print(scalar(@junk) - (scalar(@files) - 1) . ' files left :: '); }

	#	print ('junk is '.scalar(@junk).' files is '.scalar(@files));
	say('Current Time: ' . sprintf("%02d", $now[2]) . ':' . sprintf("%02d", $now[1]));
	open my $outpage, ">:utf8", "thread.html";
	print $outpage $html;
	close $outpage;

	if (scalar(@junk) != $count) { say '$count is off again'; }
	elsif ($imagelimit == 1 && ((scalar(@files)) - 1) >= $count) { say 'image limit reached: ' . $count; done(); }
}

sub done {
	my $here;
	$here = cwd unless $root_dir eq cwd;
	my $there = $thread;
	$there =~ s{.+/(\w+)/res/(\w+)$}{$1/$2};
	$there =~ s[/.+$][/$threadtitle] unless $threadtitle eq '0';
	$here = $there;
	chdir $here;
	my @these = glob "*";
	chdir "..";
	$here  =~ s{.+/(\w+)$}{$1};
	$there =~ s{.+/(\w+)$}{$1};
	$there = '[DONE]' . $there;
	mkdir $there || die $!;
	say "\nFiles will be moved to $there";
	exit print "something is very wrong" if $there eq $root_dir;
	for my $this (@these) { rename("$here/$this", "$there/$this") || die $!; }
	rmdir $here || die $!;
	exit;
}
