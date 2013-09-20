use Modern::Perl;
use LWP::Simple;
use File::Path qw(make_path);
use HTML::TreeBuilder;
use Text::Unidecode;
use File::Slurp;

#protip: echo perl thisscript.pl %* > imgur.bat

#todo:	can't trigger pages past 1
#		can't into named albums
#		doesn't do anything about bad downloads
#	# - merge w/visxp
#		# - add xhamster

#todo: use content_length to check whether you've grabbed the whole file and retry if not

my $wingit = $#ARGV; #if you launch the script with -q (or -anythingelse <_<) it won't prompt for album names
my $album = $ARGV[-1] || die "give it a URL";
#hardcoding proxies baaaad
my $ua = LWP::UserAgent->new();
#$ua->proxy('http', 'http://192.168.250.125:3128/');
#$ua->env_proxy;
# $ua->agent('Mozilla/5.0 (X11; U; Linux; i686; en-US; '.
	# 'rv:1.9.0.13; does anyone ever read this string?) '.
	# 'Gecko/2009073022 Firefox/3.0.13'
# );
# $ua->agent('Mozilla/5.0 (compatible; MSIE 6.0; Windows NT 5.1)'); #ie6 on xp
$ua->agent('Mozilla/5.0 (X11; U; Linux; i686; en-US; rv:1.9.0.13) Gecko/2009073022 Firefox/3.0.13');

#"properly" $album should be a URI object
if ($album =~ m{/a/}){
#	$album =~ s{/\d$|#\w*$}{};	#remove anchors to get down to the root of the album
#	$album .= "/all" unless $album =~ m{/all$}i;	#now go back to the index page
	$album =~ s![/#](\d$|all)!!;
	$album .= '/noscript' unless $album =~ /noscript$/; #noscript (IE-compatible) page doesn't do the fancy JS next-page loading
} else {
#	die 'the named albums\' `browse` buttons point to a conventional url';
	my $temp = $ua->get($album);
	die unless $temp->is_success;
	$album = HTML::TreeBuilder->new_from_content($temp->decoded_content)->look_down(_tag => 'a', class => 'browse')->attr('href');
	$album =~ s!^//(.+?)/all$!http://$1/noscript!;
#	<a href="//imgur.com/a/1u5Wg/all" class="browse">
}

say $album;
my $page = $ua->get($album) or die "$!";
die $page->status_line unless $page->is_success; ##todo: dump headers and see wtf is making imgur 403 LWP

my $albumname = HTML::TreeBuilder->new_from_content($page->decoded_content)->look_down(_tag => 'title')->as_text;
$albumname =~ s/^\s*(.+?) - Imgur.*$/$1/;

#if the album name blows, fix it
if ($wingit){
	if ($ARGV[0] =~ /^-/){
		if ($albumname =~ /^((?:Photo )?Albums?)$/){
			$albumname = $album;
			$albumname =~ s{^.+com/(?:a/)?([^\s/]+)(?:/all|/noscript)?}{$1}i;
		}
	} else {
		$albumname = $ARGV[0];
	}
}
$albumname =~ s!([\p{Hiragana}\p{Katakana}\p{Han}])!unidecode($1)!ge; #romanize moonrunes. why am I romanizing moonrunes? unicode bug?

#if it's still got a shit name, force user to notice
if ($albumname =~ /^(Photo Albums?|Album)$/){
	say "Please name this album.";
	$albumname = <STDIN>;
	$albumname =~ s/\n$//;
}
# this line is for the JS-enabled pages, put it back in if /noscript disappears
#my @imagehashes = ($page->decoded_content =~ /<div id="([a-zA-Z0-9]{5})" class="post">/ig);
my @imagehashes = ($page->decoded_content =~ /<div class="image" id="([[:alnum:]]{5,8})">/ig); #7 may not be enough 2013/1/18
print ((1 + $#imagehashes).' images ');
length $albumname > 120 ? die 'broken albumname parse' : say $albumname;
downloadalbum();
dump_to_txt($albumname, @imagehashes);

sub downloadalbum {
	#for some reason mkdir doesn't work.
	make_path($albumname);

	chdir($albumname);
	my @files = glob "*";	#dupe detection database
	my ($counter, $dupe) = (0, 0);
	for (@imagehashes){
		$counter += 1;
		my $newfilename = ((sprintf "%03d", $counter) . "_" . $_ . ".jpg");
		for(@files){
			next if $_ ne $newfilename;
			$dupe = 1;
		}
		if ($dupe == 1){ print("$_ :: Duplicate\n"); $dupe = 0; next; }
		my $img = $ua->mirror("http://i.imgur.com/" . $_ . ".jpg", $newfilename);

		say($_.' :: '.$newfilename.' :: '.$img->code.' :: '.(sprintf "%.02d", ($img->content_length / 1024)).' kB');
	}
}
sub dump_to_txt { #todo: dump real album url in here regardless of custom names
    my ($albumname, @urls) = @_;

    @urls = map { $_ = 'http://i.imgur.com/'.$_.'.jpg' } @urls;

    # make_path($albumname);
    # chdir($albumname);

    write_file('files.txt', (join "\n", @urls))
    || die $!;

    return $albumname;
}
say $albumname;
