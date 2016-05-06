use HTML::Query 'Query';
use LWP;
use Modern::Perl;
use File::Util;
use File::Path qw'remove_tree';
use Win32::Unicode::File;
use Data::Dumper;
use Cwd;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
$|++;


# gonna scrape http://www.mangapanda.com/aiyoku-no-eustia/1 for practice

#maybe turn this into a cgi script later

my $fu = File::Util->new();
my $ua = LWP::UserAgent->new(agent => 'Mozilla/5.0 (Windows NT 6.1; WOW64; rv:17.0) Gecko/20100101 Firefox/17.0');

my %already_here;

my $page_one = $ua->get($ARGV[0]);
if ($page_one->is_error){
	die $page_one->code;
}
$page_one = $page_one->decoded_content;

my $q = Query(text => $page_one) || die $!;

create_dir();
my @queue = find_pages();

say "Fetching images.";

for (@queue){
	obtain_image($_);
}

say "Wrapping up.";
zip_folder();

sub create_dir {
	my @list = $q->query('h2.c2 a[title]')->get_elements();
	my $albumname = $list[0]{'title'};
	$albumname =~ s{\s+Manga}{} || die '!!!'.$albumname;

	say 'Saving to: '.$albumname;
	
	# originally used File::Path's make_path; 
	# switched to File::Util since I'm using it for escape_filename anyway
	$fu->make_dir($albumname, undef, '--if-not-exists'); 
	chdir $albumname;

	for (glob "*.*"){
		$already_here{$_} = file_size $_;
	}
	return;
}
sub find_pages {
	my @pages = $q->query('select#pageMenu option[value]')->get_elements();
	map { $_ = 'http://www.mangapanda.com'.$_->{'value'} } @pages;

	say "Loading every page.";

	my $ct = 0; #build a new, sane page number
	map { $ct++; $_ = get_image_path($_, $ct) } @pages;

	return @pages;
}
sub get_image_path {
	my $pg;
	my $count = $_[1];
	if ($_[0] !~ m{/\d+/\d+$}){ #it's page one
		$pg = $q;
	} else {
		my $req = $ua->get($_[0]);
		if ($req->is_error){
			die $req->code;
		}
		$pg = Query(text => $req->decoded_content) || die $!;
	}
	my @list = $pg->query('img#img')->get_elements();
	my $path = $list[0]{'src'} || die Dumper(@list);

	my $name = $path;
	$name =~ s{^.+/([^/]+)$}{$1};
	$name =~ s/(\w+?)-(\d+)\./sprintf "$1-%03d_$2.", $count/e;

	return [$path,$name];
}
sub obtain_image {
	my ($url, $file) = @{$_[0]};

	if (exists $already_here{$file}){
		my $my_size = $already_here{$file};

		my $check = $ua->head($url);
		if ($check->is_error){
			die $check->code;
		}
		my $their_size = $check->header('content-length');
		warn "$file exists. $my_size ondisk / $their_size onsite\n"; #just a notice for now
	} else {
		my $then = time;
		my $req = $ua->get($url, ':content_file' => $file);
		if ($req->is_error){
			warn "$file - ".$req->code."\n";
		}
		say "$file: ".(time - $then)."secs";
	}
}
sub zip_folder {
	my $src = cwd;
	my $chapnum = $ARGV[0];
	$chapnum =~ s{^.+?/(\d+)$}{sprintf "%02d", $1}e;

	my $zip_name = $src;
	$zip_name =~ s{^.+/([^/]+)$}{$1};
	$zip_name =~ s/\s+/_/g;
	$zip_name =~ s=[\\/:"*?<>|]+=-=g; #invalid windows filename chars. probably impossible.
	$zip_name .= '_'.$chapnum.'.zip';

	my $zip = Archive::Zip->new();

	$zip->addTree($src);

	if ($zip->writeToFileNamed("../$zip_name") == AZ_OK){
		chdir "..";
		remove_tree $src;
	} else {
		warn "zip file didn't write";
	}
}