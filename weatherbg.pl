use Modern::Perl;
use Xchat qw(:all);
use threads;
use threads::shared;
use LWP;
use XML::Simple;
 
register('Forecast Backgrounds', '0.0.1', 'changes background image according to weather forecast', sub{prnt 'WeatherBG unloaded.';});
#adapted directly from LifeIsPain's http://xchatdata.net/Scripting/PerlNonBlockingExecution
 
my @result_commands = ();
share(@result_commands);
my $active = 0;
share($active);
my ($zip,$base_path) = (48412,'X:\My Dropbox\Public\pictures\wallpapers\WDK\\');
 
prnt 'WeatherBG loaded.';
#command('timer -repeat 0 7200 WeatherBG'); #update every two hours
hook_command('WeatherBG', sub {
		deal_with();
        return EAT_XCHAT;
});
 
# called by threads->create, this is where any commands should be done that
# would otherwise block XChat
# $_[0] will be the context to run the output in
# $_[1] will be the string to deal with
sub thread_command {
        my $weather = LWP::UserAgent->new->get('http://api.wunderground.com/auto/wui/geo/ForecastXML/index.xml?query='.$zip);
		$weather->is_success or return;
		my $obj = XMLin($weather->content);
		my $cond = $obj->{txt_forecast}{forecastday}[0]{icon};
		
		undef $obj; #oh god all my ram is gone
		
		my $night;
		$night = 1 if $cond =~ s/^nt_//; #I don't think I'll be able to find enough day walls for this distinction :\
		
		if ($cond =~ /^(chance)?(rain|sleet|tstorms?)$/){
			$cond = 'rain';
		} elsif ($cond =~ /^(fog|hazy|partlysunny|(mostly)?cloudy)$/){
			$cond = 'clouds';
		} elsif ($cond =~ /^(chance)?(flurries|snow)$/){
			$cond = 'snow';
		} else { #(partly)?cloudy|clear|(mostly)?sunny
			$cond = 'clear';
		}
		
		#choose a randomized new wall
		my $wall = [];
		opendir my $folder, $base_path.$cond || prnt ':(';
		while(readdir $folder){
			if ($_ =~ /\.(jpe?g|png)$/ && $_[1] !~ /$_$/){
				push @{$wall}, $base_path.$cond.'\\'.$_;
			}
		}
		$wall = $wall->[(int rand scalar @{$wall})-1];
		closedir $folder;
 
        # For simplicity, keep track of the context and input, as thread_command
        # takes two parameters
        my ($context) = @_;
 
        # shared is straight forward in Perl 5.10.1, but this method works in 5.10
        my $result = [];
        share($result);
        $result->[0] = $context;
        # Normally, something more interesting than just 'say' could be done to
        # modify the input, some command could be run and the result used, but
        # a demonstration is a demonstration
        $result->[1] = 'set -quiet text_background '.$wall;
 
        # add the results and where to send them to the results list
        push(@result_commands, $result);
		my $apply = []; #I guess anon refs aren't cool
		share($apply);
		($apply->[0],$apply->[1]) = ($context,'gui apply'); 
		push(@result_commands, $apply);
 
        # Now done with this thread, decrement so hook_timer may stop if need be
        $active--;
}
 
sub deal_with {
        # only really need to start up a thread if $active was 0
        # dealing with it outside of the thread due to the checking against 1 later
        $active++;
 
        # create a thread which will do the provided command, but context
        # is used for where the result should be added
        threads->create(\&thread_command, get_context(), get_prefs('text_background'));
 
        # if $active is 1, start a hook_timer to deal with the results, as one
        # wouldn't be running
        if ($active == 1) {
                # start a timer at .1 seconds
                hook_timer( 100,
                        sub {
                                # is there any thing waiting in @commands?
                                while (scalar @result_commands) {
                                        # remove first result, set context to it, and run command
                                        my $command = shift @result_commands;
                                        set_context($command->[0]);
                                        command($command->[1]);
                                }
                                # do we keep it or remove? if $active 0, we aren't expecting any
                                # more data, so we can remove it, otherwise, keep
                                if ($active == 0) {
                                        return REMOVE;
                                }
                                else {
                                        return KEEP;
                                }
                        }
                ); 
        }
}
