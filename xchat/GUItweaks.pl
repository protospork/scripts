#GUItweaks:
#drop any code that changes the behavior of the display itself in here. WB probably belongs here, actually
use strict;
use Xchat qw  (:all);

register('GUItweaks', 1, 'random shit to change/fix xchats general behavior', \&unload);
prnt('GUItweaks loaded');
sub unload { prnt 'GUItweaks unloaded'; }

#activity in the specified channels shouldnt make the tab red
hook_print($_, \&color_change) foreach('Channel Message', 'Channel Action');
my @chan = qw(#idlerpg #tokyotosho-api #anidb-spam);
sub color_change {
        command('gui color 1') if (grep(lc get_info('channel') eq $_, @chan));
        return EAT_NONE;
}