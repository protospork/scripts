use Irssi;
use Irssi::Irc;
use URI;
use Modern::Perl;
use utf8;
use vars qw'$VERSION %IRSSI';

$VERSION = "0.0.4";
%IRSSI = (
    authors => 'protospork',
    contact => 'protospork\@gmail.com',
    name => 'reloader',
    description => 'reloads gettitle'
);

my ($server, $ctrl) = ('irc.adelais.net', '#wontfix'); #hardcode these while we prove it works
my $ttl = 0;

sub loadgettitle {
	Irssi::command('script load gettitle.pl');
    $server->command('msg '.$ctrl.' gettitle reloaded');
	return 3;
}
sub yell {
    $server->command('msg '.$ctrl." something\x{07}died?");
    return 3;
}
sub checkscript {
    if (grep 'gettitle' =~ /$_/i, (keys %Irssi::Script::)){
        print 'still loaded';
    } else {
        yell();
    }
    return 2;
}
sub printscripts {
    my @things;
    for (sort grep '::', (keys %Irssi::Script::)){
        push @things, $_;
    }
    print $_ for @things;
    return;
}
sub tick {
    $server = $_[0];
    $ttl++;
    if ($ttl % 25 == 0){
        checkscript();
    }
    return 1;
}
#Irssi::signal_add_last('module unloaded', 'yell'); #doesn't work
Irssi::signal_add_last('message public', \&tick);
Irssi::command_bind('show_loaded', \&printscripts);
