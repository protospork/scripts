use Modern::Perl;
use JSON;
use LWP;
use URI;
use Opt::Imistic (usage => 'jesus I have no idea');
use Data::Dumper;

#try to knock out a halfway-decent interface for cal.syoboi.jp before I forget what I've figured out
my $syoboi = URI->new('http://cal.syoboi.jp/json.php');
my %query;
my %titles;

binmode STDOUT, ":utf8";

my $dbg;
$dbg = 1 if $ARGV{'d'};

if ($ARGV{'t'}){
	die 'that is not a valid TID' unless $ARGV{'t'} =~ /^\d+$/;
	$query{'TID'} = $ARGV{'t'};
	$query{'Req'} = 'TitleLarge';
}
if ($ARGV{'e'}){
	say 'you want to look up a specific episode' if $dbg;
	die 'you need also specify a TID with -t' unless $ARGV{'t'};
	$query{'Count'} = sprintf "%02d", $ARGV{'e'}; #no support for >99 episodes. watch something better
	$query{'Req'} = 'ProgramByCount';
}
if ($ARGV{'h'} || (! $ARGV{'t'} &&! $ARGV{'e'})){
	say 'script.pl -t [syoboi TID]'."\n".
		'looks up the full title and some other junk'."\n\n".
		'script.pl -e [epnum] -t [TID]'."\n".
		'looks up the episode specified'."\n\n".
		'EXAMPLE: '."\n".
		'script.pl -t 2274 -e 4'."\n".
		'lists airtimes for the fourth episode of C3/cubedxcursedxcurious';
	exit;
}

$query{'Req'} eq 'ProgramByCount' ? get_sched(\%query) : get_titles(\%query, 1);

sub get_sched {
	$syoboi->query_form(%{$_[0]});
	say $syoboi if $dbg;

	my $req = LWP::UserAgent->new()->get($syoboi);
	die $req->status_line unless $req->is_success;

	#if ($dbg){
	#	say $req->status_line;
	#	open my $raw, '>', 'raw_'.time.'.txt' || die $!;
	#	print $raw $req->content;
	#	close $raw;
	#	say 'raw response printed to file.';
	#}

	my $json = JSON->new->pretty(1)->utf8(1)->decode($req->content)->{'Programs'} || die $!;

	if ($dbg){
		say ("Keys:\n\t".(join "\n\t", sort keys %{$json}));
		my $data = Data::Dumper->new([$json]);
		open my $dump, '>', 'data_dump_'.time.'.txt' || die $!;
		print $dump $data->Dump;
		close $dump;
		say 'object stuff printed to another file.';
	}

	my $out;
	for (sort keys %{$json}){
		my $ttls = get_titles($json->{$_}{'TID'});

		#let's make the epoch time a little more useful
		my $done = [gmtime $json->{$_}{'EdTime'}];
		$done = ((sprintf "%02d", $done->[2]).':'.(sprintf "%02d", $done->[1]).' GMT '.(1900 + $done->[5]).'-'.(sprintf "%02d", 1 + $done->[4]).'-'.(sprintf "%02d", $done->[3]));

		$out .= $ttls->[1].' ('.$ttls->[0].') episode '.$json->{$_}{'Count'}.' ends at '.$done.' on '.$json->{$_}{'ChName'}."\n";
	}
	if ($dbg){
		open my $sched, '>:utf8', 'airtimes_'.time.'.txt' || die $!;
		print $sched $out;
		close $sched;
		say 'schedule summary printed.';
	}
	say $out;
}
sub get_titles {
	if ($titles{$_[0]}){
		say 'title '.$_[0].' already cached.' if $dbg;
	} else {
		$syoboi->query_form({TID => $_[0], Req => 'TitleLarge'});
		say $syoboi if $dbg;

		my $req = LWP::UserAgent->new()->get($syoboi);
		die $req->status_line unless $req->is_success;

		my $json = JSON->new->pretty(1)->utf8(1)->decode($req->content)->{'Titles'}{$_[0]} || die $!;

		if ($dbg){
			say ("Keys:\n\t".(join "\n\t", sort keys %{$json}));
			my $data = Data::Dumper->new([$json]);
			open my $dump, '>', 'data_dump_'.time.'.txt' || die $!;
			print $dump $data->Dump;
			close $dump;
			say 'object stuff printed to another file.';
		}

		die 'TID mismatch' unless $_[0] eq $json->{'TID'};

		$titles{$json->{'TID'}} = [$json->{'TitleEN'}, $json->{'Title'}];
	}

	if ($_[1]){
		say 'TID '.$_[0].' is '.$titles{$_[0]}[1].' ('.$titles{$_[0]}[0].')';
		exit;
	} else {
		return $titles{$_[0]};
	}
}
#save and reload titles from disk to avoid doing o9k calls on the same shit
sub reload_titles {
#later.
}
sub save_titles {
#later.
}

__END__
=head1 working code from xrelay
=encoding utf8
=item 1:
sub set_airtimes {
	set_context($anime, $destsrvr);
	my ($cfg,$topic) = ($_[0], get_info('topic'));

	#build a list of unique TIDs to request
	my $TIDs = {};
	for (values %{$cfg}){
		my $ntr = $_;
		#my ($tid, $stitle) = ($_->[4], $_->[2]);
		if ($ntr->[4] && $ntr->[2]){
			unless (grep 'horrible' =~ /$_/i, $ntr->[1]){ #no sense announcing ends of simulcasted shows (was this already fixed elsewhere?)
				$TIDs->{$ntr->[4]} = $ntr->[2];
			}
		}
	}
	#I could probably combine these two loops but :effort:
	for (keys %{$TIDs}){
		my $short = $TIDs->{$_};
		my $epno;
		if ($topic =~ /$short +(\d+)/i){ # this method will probably announce anything in the config file even if it's old as shit
			$epno = $1; $epno++;
		# } else { #what the hell was I thinking? this just spams a whole bunch of destined-to-fail requests and locks xchat for a year
			# $epno = 1;
		}

		my $info = get_airtime($_, $epno);
		if ($info =~ /^ERROR/){
			prnt($info, $ctrlchan, $destsrvr);
			next;
		} elsif ($info =~ /^EXCEPTION/){
			prnt($info, $ctrlchan, $destsrvr);
			undef $info;
			$info = get_airtime($_, ++$epno);
			if ($info =~ /^ERROR|EXCEPTION/){ #I'm fucking retarded
				prnt($info, $ctrlchan, $destsrvr);
				next;
			}
		}

		my $neat_time = [localtime $info->[1]];
		$neat_time = ((sprintf "%02d", $neat_time->[2]).':'.(sprintf "%02d", $neat_time->[1]).' '.(1900 + $neat_time->[5]).'-'.(sprintf "%02d", 1 + $neat_time->[4]).'-'.(sprintf "%02d", $neat_time->[3]));

		my $timer = hook_timer($info->[0], sub{ place_timer($info, $epno, $_); return REMOVE; });
		prnt('Timer '.$timer.' added for '.$info->[2].'/'.$info->[3].'/'.$_.' episode '.$info->[5].' at '.$neat_time, $ctrlchan, $destsrvr);

		$timers{$timer} = $short.' '.$epno;
	}
	$airtimes_set = 1; #why is this first instead of last? I'm moving it
}

sub place_timer {
	my ($info, $epno, $tid) = @_;
	command('bs say '.$anime.' '.$info->[3].' ('.$info->[2].') episode '.$epno.' just finished airing on '.$info->[4], $ctrlchan, $destsrvr);
}
sub dump_timers {
	for (keys %timers){
		prnt('Unhooking '.$_, $ctrlchan, $destsrvr);
		unhook $_;
	}

	%timers = ( );
	$airtimes_set = 0;
}
sub list_timers {
	for (keys %timers){
		prnt $_.' :: '.$timers{$_};
	}
}

sub get_airtime { #there needs to be a pretty-print return option for the inevitable trigger
	my $tid = shift;
	my $ep = shift;
	my $url = URI->new('http://cal.syoboi.jp/json.php');
	$url->query_form({TID => $tid, Req => 'ProgramByCount', Count => $ep});

	my $req = LWP::UserAgent->new()->get($url);
	return 'ERROR '.$req->status_code unless $req->is_success;

	my $json = JSON->new->pretty(1)->utf8(1)->decode($req->content)->{'Programs'} || return 'ERROR: Invalid JSON';
	my $timeout;
	for (sort keys %{$json}){ #should only need the first item from this loop ##incorrect, first is not always earliest
		my $ttls = get_titles($json->{$_}{'TID'});

		if (! $ttls->[0]){ #section should be valid for both hiragana and katakana. still stumped for kanji
			$ttls->[0] = unidecode($ttls->[1]);
			$ttls->[0] =~ s![\x{3063}\x{30c3}](.)!my $ch = $1; if(unidecode($ch) =~ /([kstcp])/){ $1.$ch; } else { 'UHOH'; }!e; #sokuon
			if ($ttls->[1] =~ /[\x{3083}\x{3085}\x{3087}\x{30e3}\x{30e5}\x{30e7}]/){ #yoon
				$ttls->[0] =~ s/(?<=[knhmrgbp])i(?=y[aou])//g;
				$ttls->[0] =~ s/siy(?=[aou])/sh/g;
				$ttls->[0] =~ s/tiy(?=[aou])/ch/g;
				$ttls->[0] =~ s/ziy(?=[aou])/j/g;
			}
			$ttls->[0] =~ s/si/shi/g;
			$ttls->[0] =~ s/tu/tsu/g;
			$ttls->[0] =~ s/ti/chi/g;
			$ttls->[0] =~ s/(?<=[aeiou])hu|^hu/fu/g;
			$ttls->[0] =~ s/zi/ji/g;
			$ttls->[0] =~ s/du/zu/g; #tsu with dakuten. rare
		}

		if (time > $json->{$_}{'EdTime'}){
			return 'EXCEPTION: '.$ttls->[0].'/'.$ttls->[1].' '.$json->{$_}{'Count'}.' already aired.';
		}
		$timeout = $json->{$_}{'EdTime'} - time;
		$timeout *= 1000; #we need milliseconds for hook_timer
		return [$timeout, $json->{$_}{'EdTime'}, $ttls->[0], $ttls->[1], $json->{$_}{'ChName'}, $json->{$_}{'Count'}];
	}
}

sub get_titles {
	if ($titles{$_[0]}){
		return $titles{$_[0]};
	} else {
		my $syoboi = URI->new('http://cal.syoboi.jp/json.php');
		$syoboi->query_form({TID => $_[0], Req => 'TitleLarge'});

		my $req = LWP::UserAgent->new()->get($syoboi);
		return 'ERROR: '.$req->status_code unless $req->is_success;

		my $json = JSON->new->pretty(1)->utf8(1)->decode($req->content)->{'Titles'}{$_[0]} || die $!;

		return 'ERROR: TID mismatch' unless $_[0] eq $json->{'TID'};

		$titles{$json->{'TID'}} = [$json->{'TitleEN'}, $json->{'Title'}];

		return $titles{$_[0]};
	}
}
