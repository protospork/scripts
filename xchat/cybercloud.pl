use Modern::Perl;
use Xchat qw( :all );
my $ver = 0.3;
register('clouds and skeletons', $ver, "who even cares", \&unload);
hook_print("Channel Message", \&magic_happens, {priority => PRI_LOWEST});

sub magic_happens {
	my ($nick, $msg) = ($_[0][0], $_[0][1]);
	my ($chan,$srvr) = (get_info('channel'),get_info('server'));
	
	$msg =~ s/(?<=a)n? SJW/ skeleton/ig;
	$msg =~ s/SJW/skeleton/ig;
	$msg =~ s/skeleton (?=[A-Z])/Skeleton /g;
	
	$msg =~ s/The Cloud/My Butt/g;
	$msg =~ s/the cloud/my butt/g;
	
	$msg =~ s/Cyber/Wizard/g;
	$msg =~ s/cyber/wizard/g;
	
	$msg =~ s/mill?enn?ials/snake people/g;
	$msg =~ s/Mill?enn?ials/Snake People/g;
	
	$msg =~ s/mill?enn?ial/snake person/g;
	$msg =~ s/Mill?enn?ial/Snake Person/g;
	
	emit_print('Channel Message', $nick, $msg, $_[2], $_[3]);
	return EAT_ALL;
}

sub unload {
	prnt "oh bye";
}
prnt "uh hey hi";