use Modern::Perl;
no warnings 'utf8';
use JSON;
use LWP; #RobotUA straight up doesn't work anymore. Owns
use Data::Dumper;
use Tie::YAML;
use File::Slurp;
use File::Copy qw(copy);
use File::Util;
use Digest::MD5;
use Cwd 'cwd';
my $root_dir = cwd;


#verify() should run immediately after a file downloads, instead of on the second pass

#on first run in existing folder w/o logfile, immediately increments $empty_tries.
# deleting a pic only fixes it sometimes  DO IT BETWEEN RUNS


binmode STDOUT, ":utf8"; 

my $debug = 1;
my $ua = LWP::UserAgent->new();
$ua->agent('protobot 20131220 contact: protospork@gmail.com');
my $fu = File::Util->new(); #functional module with a needlessly OO interface? check
$|++;

my %pics;
my %thread;

# if (-e $root_dir.'\4chan-log.po'){
	# tie my %pics, 'Tie::YAML', $root_dir.'\4chan-log.po' or die $!;
# } else {
	# say "this is a new thread" if $debug;
# }

my $empty_tries = 0; #number of times we've checked the thread and found no updates
my $last_check = 1111111111; #unix time the thread index was last downloaded
my $last_size = 1;
my $cycles = 0;

sub make_api_link {
	# https://boards.4chan.org/gif/res/6016093 -> http(s)://a.4cdn.org/board/res/6016093.json
	(my ($board,$hash) = ($_[0] =~ m{boards\.4chan\.org/([^/]+)/thread/(\d+)}))
		|| die 'ERROR: That isn\'t a link to a thread.';
	my $url = 'https://a.4cdn.org/'.$board.'/res/'.$hash.'.json';
	say $url if $debug;
	
	$thread{'board'} = $board;
	$thread{'num'} = $hash;

	return $url;
}
sub pull_index { 
	my $thread = shift;

	my $url = check(make_api_link($thread));
	
	my $req = $ua->get($url, {'If-Modified-Since' => $last_check});
	if ($req->is_error){ die 'ERROR ('.$req->code.'): Could not retrieve thread.'; }
	if ($req->code == 304){ 
		# it doesn't work; 4chan just returns http 200
		$cycles++;
		say "no updates (header)" if $debug;
		return 'No updates since '.$last_check; 
	} elsif (length $req->content == $last_size){
		$cycles++;
		say "size unchanged" if $debug;
		return 'JSON size unchanged since '.$last_check;
	}
	$last_size = length $req->content;
	
	if ($debug){
		say 'HTTP '.$req->code;
		say ((length $req->content).'B');
	}
	$cycles++;
	return $req->decoded_content;
}
sub json_to_list {
	if ($_[0] =~ /^No updates|^JSON size unchanged/){ return $_[0]; }
	my $json = decode_json $_[0];
	# write_file('4chan'.time.'.txt', Dumper $json) if $debug;

	if (! $json->{'posts'}){
		return 'ERROR: lol JSON.pm';
	}

	for (@{$json->{'posts'}}){
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
		} || say "WHY";
	}
	
	$thread{'title'} = $json->{'posts'}[0]{'sub'} 
		|| $json->{'posts'}[0]{'no'}
		|| die 'something terrible has happened.';
	$thread{'title'} = $fu->escape_filename($thread{'title'});

	say 'Thread title is '.$thread{'title'};
	return time;
}
sub grab_images { 
	create_dir($thread{'title'}) unless cwd =~ $thread{'title'};
	my @dir = glob "*.*"; #don't glob on every iteration, idiot

	my $rval = 0; # this gets flipped if a file is grabbed, used to keep the 'watch thread' thing from going insane 

	for (sort keys %pics){
		rewrite_filename($_);

		if (file_check($_, @dir) =~ /^STOP|^DO NOT/){ #make sure it doesn't exist
			next;
		} else {
			sleep 1; #moot says no more than 1 req/sec so I'll be nice
		}
		my $url = 'https://i.4cdn.org/'.$thread{'board'}.'/src/'.$_.$pics{$_}{'ext'};

		print "$url --> ";

		my $resp = $ua->get($url, ':content_file' => $pics{$_}{'fixed_name'});
		if ($resp->is_error){
			say $resp->code;
		} else {
			say $pics{$_}{'fixed_name'};
			$rval++;
			file_check($_, @dir);
		}
	}
	if ($rval == 0){
		$empty_tries++;
	} else {
		$empty_tries = 0;
	}
	recheck_thread();
}
sub rewrite_filename { 
	# ~~~~~ note that this takes the %pics key, not the name ~~~~~~~
	# prefixes filename w/post # to prevent dupe names overwriting each other
	my $name = $fu->escape_filename($pics{$_[0]}{'name'});
	$name =~ s/[^[:ascii:]]/U/g;

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
sub file_check { #glob for file & md5 it.
	my ($fi, @dir) = @_;

	if (grep quotemeta $pics{$fi}{'fixed_name'} =~ quotemeta $_, @dir){ #quotemeta should be unnecessary
		my $src_hash = $pics{$fi}{'md5'};
		$src_hash =~ s/==$//;
		
		# print "$_ exists as ".$pics{$fi}{'fixed_name'};		

		my $ok = verify($fi);
		
		if ($ok){
			return 'DO NOT DOWNLOAD THIS AGAIN';
		} else {
			# print " but is broken.\n";
			say "$_ is broken.";
			unlink $fi;
			return 0;
		}
	} elsif (exists $pics{$fi}{'ondisk'} && $pics{$fi}{'ondisk'} =~ /^\d+$/){ # don't redownload a deleted file
		return 'STOP';
	}
	return 0;
}
sub create_dir {
	my $albumname = $thread{'board'}.'/'.$_[0];

	say 'Saving to: '.$albumname if $debug;
	
	# originally used File::Path's make_path; 
	# switched to File::Util since I'm using it for escape_filename anyway
	$fu->make_dir($albumname, undef, '--if-not-exists'); 
	chdir $albumname;
	tie %pics, 'Tie::YAML', '4chan-log.po' or die $!;
}
sub check { #I don't remember why I did this
	$_[0] =~ /^ERROR/ 
	? die $_[0]
	: return $_[0];
}
sub record_success {
	my $fi = $_[0];
	$pics{$fi}{'ondisk'} = time;
	tied(%pics)->save;
	return $pics{$fi}{'ondisk'};
}
sub verify {
	my $fi = $_[0];

	if ($pics{$fi}{'ondisk'} =~ /^\d+$/){ #seriously, DO NOT REDOWNLOAD A DELETED FILE
		return 1;
	}
	
	$pics{$fi}{'md5'} =~ s/==$//;

	open my $file, '<', $pics{$fi}{'fixed_name'} || die $!;
	binmode($file);

	my $md5 = Digest::MD5->new;
	$md5->addfile($file);
	my $hash = $md5->b64digest;

	close $file;
	
	if ($hash eq $pics{$fi}{'md5'}){
		record_success($fi);
		return 1;
	} else {
		return 0;
	}
}
sub recheck_thread {
	my $wait = 2**($empty_tries);
	$wait = 64 if $wait > 64; #exponential hops are cool but let's not go crazy here

	#workaround for bug where new threads immediately wait 2min
	$wait = 0 if $cycles == 1;

	say '$empty_tries count: '.$empty_tries;

	my $tstamp = [localtime];
	$tstamp = sprintf "%02d:%02d:", $tstamp->[2], $tstamp->[1];
	say "$tstamp Sleeping $wait minutes.";
	sleep $wait * 60;

	$last_check = check(json_to_list(pull_index($ARGV[0])));
	grab_images();
}

$last_check = check(json_to_list(pull_index($ARGV[0])));
grab_images();
