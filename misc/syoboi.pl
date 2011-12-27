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