$botnick = 'testbot';
$botpass = 'password'; #bot's nickserv password
$owner = 'me'; #owner's nick, I have no idea what uses this
$animulistloc = ''; #the URL to the list for .anime
$maxdicedisplayed = 7;
@offchans = ( #channels in which to ignore triggers
	'#channel'
);
@animuchans = ( #I don't remember why this is specifically opt-in
	'#anime', '#spam'
);
@dunno = ( #things for the bot to say when he is confused
	'wat', 'dunno lol', 'try again', 'derp'
);
#or angry
@meanthings = qw( 
	asshat twat ass
	douche dick cunt
);
@repeat = ( #or annoyed
	'this is getting old', 'STOP IT', 'also cocks', 'can we do something else?', 'quit it'
);
#.when
%timers = ( #http://www.epochconverter.com/
	skyrim => '1320969600',
	christmas => '1324771200'
);
$debug = 1; #enables extra error messages
$cfgver = '2011.10.12-SAMPLE';