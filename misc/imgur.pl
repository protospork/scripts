use Modern::Perl;
use LWP::Simple;
use File::Path qw(make_path);
use HTML::TreeBuilder;

#todo: can't trigger pages past 1

my $wingit = $#ARGV; #if you launch the script with -q (or -anythingelse <_<) it won't prompt for album names
my $album = $ARGV[-1] || die "give it a URL";
#hardcoding proxies baaaad
my $ua = LWP::UserAgent->new();
$ua->proxy('http', 'http://192.168.250.125:3128/');
# $ua->show_progress(1); #dear god that's ugly

#"properly" $album should be a URI object
if ($album =~ m{/a/}){
	$album =~ s{/\d$|#\w+$}{};	#remove anchors to get down to the root of the album
	$album .= "/all" unless $album =~ m{/all$}i;	#now go back to the index page
}
say $album;
my $page = $ua->get($album) or die "$!";
die $page->status_line unless $page->is_success;

#why did I use treebuilder for so little?
my $albumname = HTML::TreeBuilder->new_from_content($page->decoded_content)->look_down(_tag => 'title')->as_text;
$albumname =~ s/^\s*(.+?) - Imgur.*$/$1/;

if ($albumname =~ /^(Photo Albums?|Album)$/){
	if ($wingit){
		$albumname = $album;
		$albumname =~ s{^.+com/(?:a/)?([^\s/]+)(?:/all)?}{$1}i;	
	} else {
		say "Please name this album.";
		$albumname = <STDIN>;
		$albumname =~ s/\n$//;
	}
}
my @imagehashes = ($page->decoded_content =~ /<div id="([a-zA-Z0-9]{5})" class="post">/ig);
say ((1 + $#imagehashes).' images');
length $albumname > 120 ? die 'broken albumname parse' : say $albumname;
downloadalbum();

sub downloadalbum {
	#for some reason mkdir doesn't work.
	make_path("imgur/".$albumname);	
	
	chdir("imgur/".$albumname);
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
		
		say($_.' :: '.$newfilename.' :: '.$img->code.' :: '.$img->content_length.' bytes');
	}
}
print $albumname;