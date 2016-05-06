#lol bing rewards

use Modern::Perl;
use File::Slurp;
use URI::Escape;
use CGI;
use CGI::Carp 'fatalsToBrowser';
no warnings qw'uninitialized';

$CGI::DISABLE_UPLOADS = 1;

my $o = CGI->new;
print $o->header('text/html','200 Fine');


my $dict = "/home/proto/tehgoogles";

my $count = 20;
if ($o->param('count')){
	$count = $o->param('count') - 1;
}
print '<head>';
unless ($count == 0){
	print '<meta http-equiv="refresh" content="'.((int rand 15)+5).'; url=https://butt.academy/cgi/bingit_2.pl?count='.($count).'">';
}
print '</head><body>';

print '<h6>'.$count.' requests remain.</h6>';

my @lines;
my @queries;

@lines = read_file($dict);

if ($#lines > 0){
	print "<p>".$#lines." lines in dict.</p><p>";
} else {
	print "<p>oh shit</p>";
	exit;
}

do_a_thing($lines[int rand $#lines]);
# while ($count){
# 	$count--;
# 	my $out;
# 	my $string = $lines[int rand $#lines];
	
# 	if (length $out == 30 || ! $string){
# 		$count++;
# 	} else {
# 		do_a_thing($string);
# 		# sleep((int rand 5)+5); #should I really be waiting in a cgi process? doubt it.
# 	}
# }
# push @queries, "</p>";

# print $_ for @queries;

sub do_a_thing {
	#ideally: open an iframe, give it 5-10 (random) seconds, do the next one
	my $in = $_[0];
	$in =~ s/\x{0D}|\x{0A}//g;
	$in =~ s/\s+/%20/g;
	print "<p>$in</p>";
	$in = "https://www.bing.com/search?q=".$in;

	my $string = "http://www.httpreferer.net/no?encode=1&url=".(uri_escape $in);
	print qq(<iframe src=$string  width="90%" height="80%">$in</iframe>);
	# style="display: none;"
}