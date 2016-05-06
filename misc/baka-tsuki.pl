use Modern::Perl;
use File::Slurp;
use File::Path qw'make_path remove_tree';
use LWP;
use URI;
use Cwd;
use utf8;

my $root = cwd;
my $ua = LWP::UserAgent->new( );
my $outfile;
$outfile = $ARGV[1] || 'index.xhtml';

#todo:
#	-switch to parsing the printable version?
#	-output with EBook::EPUB?
#	-strip the ul/li stuff from around the images in the beginning

say "Downloading text.";
my $req = $ua->get($ARGV[0].'&printable=yes'); #grab the 'FULL VOLUME' PAGE
if (! $req->is_success){ die "Error downloading page: $req->code"; }
else { say "Success."; }
my $text = $req->decoded_content;
my $stylesheet = 'stylesheet.css' || die "can't find stylesheet.css";

my @images = ($text =~ m{<a href="(?:[^"]+)" class="image"><img(?: [^>]+)* src="(\S*?/thumb/\w/\w\w/[^/]+/\d+px-[^"]+)"(?: [^>]+)* /></a>|<img(?: [^>]+)* src="(/project/images/\w/\w\w/[^"]+)"(?: [^>]+)* />}g);

make_path('images');
for (@images){
	next unless $_;
	# say $_;
	chdir 'images';
	
	my $orig = $_;
	
	s{/images/thumb(/\w/\w\w/)[^/]+/\d+px-}{/images$1}; #convert thumbnail url to fullsize image url
	
	#OLD $text =~ s{<a href="(?:[^"]+)" class="image"><img(?: [^>]+)* src="$orig"(?: [^>]+)* /></a>}{<img src=".$_" />}; #replace thumbnail with fullsize path in the text
	$text =~ s{src="/project/images/thumb/}{src="/project/images/}g;
	$text =~ s{src="/project(/images/./../[^/]+)/.+\.(?:png|jpg)"}{src="$1"}g;
	
	my $url = URI->new('http://www.baka-tsuki.org'.$_)->canonical;
	# say $url;
	my ($dirpath,$filename) = ($url->path,$url->path);# x 2;
	
	#save the fullsize image in a path resembling the thumbnail one
	$dirpath =~ s{^.+?/((\w)/\2\w/).+?$}{$1};
	if (! -e $dirpath){
		say "Making path: $dirpath";
		make_path($dirpath) || die $!;
	}
	chdir $dirpath;
	
	$filename =~ s{^\S+/([^/]+)$}{$1}; #trim the extra from the filename
	
	if (! -e $filename){
		say "Requesting $url";
		my $resp = $ua->mirror($url, $filename);
		if (! $resp->is_success && $resp->code ne '304'){ die $resp->code; } #uhoh detector
		say "Saved as ".cwd."/$filename";
	} else {
		say cwd."/$filename already exists";
	}
	chdir $root;
	say "";
}

#OLD $text =~ s{<h3><span class="editsection">[<a href="\S*/project/\S+" title="[^"]+">edit</a>]</span> <span class="mw-headline" (id="[^"]+")>([^<]+)</span></h3>}
#OLD           {<h2><span class="mw-headline" $1>$2</span></h2>}gs; #remove [edit] links and move chapter headings up a level so calibre can find them



#probably none of these take effect anymore but fuck it
$text =~ s{\.?/project}{.}g; #fix a few paths we might have missed
$text =~ s{href="./index.php?title=File:}{href="}g; #fix image links, possibly?

$text =~ s{(?<=</title>).+?(?=</head>)|<!-- tagline -->.+?<!-- /jumpto -->}{}sg; #strip all of the needless stuff from the top
$text =~ s{</head>}{<link rel="stylesheet" href="$stylesheet" type="text/css" media="all" /></head>};
$text =~ s{<div id="footer".+?<li id="footer-info-lastmod"> (This page was last modified on [^<]+)</li>.+?(?=</body>)}{}gs; #and the bottom
my $last_modified = $1;

utf8::encode($text); #stupid fucking wide character warnings
write_file($outfile, $text);
print $last_modified;
