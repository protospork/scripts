use Modern::Perl;
use JSON;
use LWP; #RobotUA straight up doesn't work anymore. Owns
use Data::Dumper;
use File::Slurp;
use File::Copy qw(copy);
use File::Util;
use Digest::MD5;
use Cwd 'cwd';
my $root_dir = cwd;

# <@cephalopods> done: fetch thread index, build list of files to download. todo: create folder, fetch pics, hash pics/redownload fuckups, thread watching
# <@cephalopods> that sounds like "most of the script" but really all I have to do is cram this new code into my old 4chan ripper

#haha fuck that, the old script is *bonkers*

my $debug = 1;
my $ua = LWP::UserAgent->new();
$ua->agent('protobot 20131220 contact: protospork@gmail.com');
my $fu = File::Util->new(); #functional module with a needlessly OO interface? check
$|++;

my %pics;
my %thread;

sub make_api_link {
	# https://boards.4chan.org/gif/res/6016093 -> http(s)://a.4cdn.org/board/res/threadnumber.json
	(my ($board,$hash) = ($_[0] =~ m{boards\.4chan\.org/([^/]+)/res/(\d+)}))
		|| return 'ERROR: That isn\'t a link to a thread.';
	my $url = 'https://a.4cdn.org/'.$board.'/res/'.$hash.'.json';
	say $url if $debug;
	
	$thread{'board'} = $board;
	$thread{'num'} = $hash;

	return $url;
}
sub pull_index { #this needs to support X-If-Modified-Since (or something)
	my $url = check(make_api_link($_[0]));
	my $req = $ua->get($url);
	if ($req->is_error){ return 'ERROR ('.$req->code.'): Could not retrieve thread.'; }

	if ($debug){
		say 'HTTP '.$req->code;
		say ((length $req->content).'B');
	}
	return $req->decoded_content;
}
sub json_to_list {
	my $json = decode_json $_[0];
	# write_file('4chan'.time.'.txt', Dumper $json) if $debug;

	if (! $json->{'posts'}){
		return 'ERROR: lol JSON.pm';
	}

	for (@{$json->{'posts'}}){ #TODO: see if the pic is deleted
		if (! $_->{'tim'}){
			# say 'No image in '.$_->{'no'} if $debug;
			next;
		}

		$pics{$_->{'tim'}} = {
			'name'	=> $_->{'filename'}, # original filename, not 4chan's rename
			'ext'	=> $_->{'ext'}, 
			'size'	=> $_->{'fsize'}, 
			'md5'	=> $_->{'md5'},
			'num'	=> $_->{'no'},
		};
	}
	
	$thread{'title'} = $json->{'posts'}[0]{'sub'} 
		|| $json->{'posts'}[0]{'no'}
		|| die 'something terrible has happened.';
	$thread{'title'} = $fu->escape_filename($thread{'title'});

	say 'Thread title is '.$thread{'title'};
}
sub grab_images { 
	create_dir($thread{'title'});
	my @dir = glob "*.*"; #don't glob on every iteration, idiot

	for (keys %pics){
		rewrite_filename($_);

		if (file_check($_, @dir)){ #make sure it doesn't exist
			next;
		} else {
			sleep 2; #moot says no more than 1 req/sec so I'll be nice
		}
		my $url = 'https://i.4cdn.org/'.$thread{'board'}.'/src/'.$_.$pics{$_}{'ext'};

		print "$url --> ";

		my $resp = $ua->get($url, ':content_file' => $pics{$_}{'fixed_name'});
		if ($resp->is_error){
			say $resp->code;
			#TODO: look for partial file and delete it; maybe retry
		} else {
			say $pics{$_}{'fixed_name'};
		}
	}
}
sub rewrite_filename { 
	# ~~~~~ note that this takes the %pics key, not the name ~~~~~~~
	# prefixes filename w/post # to prevent dupe names overwriting each other
	my $name = $fu->escape_filename($pics{$_[0]}{'name'});

	# but if the filename is all digits (*chan repost), fuck it.
	if ($name =~ /^\d+$|^tumblr_/){
		$name = $_;
	}

	$name = $pics{$_[0]}{'num'}.'_'.$name;
	$name .= $pics{$_[0]}{'ext'};
	$name =~ s/\s+|%20/_/g;

	$pics{$_[0]}{'fixed_name'} = $name;

	return $name;
}
sub file_check { #glob for file & md5 it. later.
	my ($fi, @dir) = @_;

	if (grep $pics{$fi}{'fixed_name'} eq $_, @dir){
		#TODO: actually look at the existing file
		return 1;
	}
	return 0;
}
sub create_dir {
	my $albumname = $_[0];

	say 'Saving to: '.$albumname if $debug;
	
	# originally used File::Path's make_path; 
	# switched to File::Util since I'm using it for escape_filename anyway
	$fu->make_dir($albumname, undef, '--if-not-exists'); 
	chdir $albumname;
}
sub check {
	$_[0] =~ /^ERROR/ 
	? die $_[0]
	: return $_[0];
}

check(json_to_list(pull_index($ARGV[0])));
grab_images();

