#fuck it, I'll write a sysinfo script
#kinda
use Modern::Perl;
use Xchat ':all';
use DateTime;
use DateTime::Format::Duration;

my $ver = '0.11';
register('proto-sys', $ver, 'another fucking sysinfo thing', \&unload);
my $debug = 0;


prnt("sysinfo $ver loaded");
sub unload { prnt "sysinfo $ver unloaded"; }

hook_command('pro_uptime', \&get_uptime);

#find boot time once, save it in memory so it never runs that cmd command again
my $sys_boot = 0;


#there's a way to just get the elapsed system runtime in seconds or something,
# and that would be worlds better than using datetime math
sub get_uptime {
	my $boot;
	if ($sys_boot){
		$boot = $sys_boot;
	} else {
		$boot = `net statistics workstation | find "since"`;
		$sys_boot = $boot;
	}
	$boot =~ s/^.+since //;
	my @abs_boot = (split /[\/\s:]/, $boot, 6);
	if ($debug){
		prnt "$abs_boot[0] / $abs_boot[1] / $abs_boot[2]";
		prnt "$abs_boot[3] : $abs_boot[4] : $abs_boot[5]";
	}
	my $then = DateTime->new(
		year	=> $abs_boot[2],
		month	=> $abs_boot[0],
		day		=> $abs_boot[1],
		hour	=> $abs_boot[3],
		minute	=> $abs_boot[4],
		second	=> $abs_boot[5]
	);
	my $now = DateTime->now();
	my $uptime = $now->subtract_datetime($then);
	
	my $formatter = DateTime::Format::Duration->new(
		pattern => '%Y years %m months %e days %H hours %M minutes %S seconds'
	);
	
	my $out = $formatter->format_duration($uptime);
	$out =~ s/^(0 years )?(00? months )?(0 days )?(00? hours )?(0 minutes )?(0 seconds)?//;
	
	#hour/minutes seem to be slightly broken?
	if ($out =~ /(\d+) minutes/){
		if ($1 > 59){
			my $hour = int($1 / 60);
			my $min = $1 % 60;
			$out =~ s/00? hours/$hour hours/;
			$out =~ s/\d+ minutes/$min minutes/;
		}
	}
	#also months
	$out =~ s/0?(\d+? months)/$1/;
	command('say '."\x{02}\x{03}07uptime\x{0F}[Current: ".$out.']');
}