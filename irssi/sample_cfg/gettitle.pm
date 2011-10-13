#config file for title retrieval script
$maxlength = 100;	#number of chars before the title is cut off +-5 for word boundaries
$controlchan = '#wat';	#primarily for the :botnick.reload.config thing
$mirrorfile = '/home/proto/mirror.txt';
$imgurkey = ''; #imgur free/anon API key
$spam_interval = 2;	#timeout (in seconds) between lines, to stop amsg kills (damnit GV)
$debugmode = 1; #set this to 0 and nothing will be printed to the serverwindow

#These channels won't be watched
@offchans = ('#boring');
#And these ones will have 4chan/tumblr image link mirroring enabled.
@mirrorchans = ('#wat', '#testchannelgoaway');


#If a site just uses one stock title for every page, drop it here.
#Don't bother escaping any special characters.
@ignoresites = qw(	
	google.com/search dropbox.com/gallery wiki drop.io macrochan wallbase 5z8.info explosm fukung
	smbc-comics wimp.com b3ta facebook questionablecontent amazon.com boo.by botto.ms zor.de boards\.4chan
	rapidshare megaupload last.fm pastebin moonbuggy javascript:void sankaku tinychat miscpix somethingawful
	diamondbackonline portal2sounds rei-ayanami.com/rei/imgboard fatpita.net suicidegirls.com exocomics
	woot.com wolframalpha.com nedroid.com motherless.com
);
#Error fallbacks, default responses, etc.
#These ones are checked as regexes please be reasonable.
@defaulttitles = (
	'Newegg(?:\.com)? - Computer Parts',
	'Broadcast Yourself', 'Pancarkan Dirimu', 
	'^The Something Awful Forums$', '4\d\d', '[nN]ot [fF]ound', 
	'Log ?[IOio]n', 'Index [oO]f', '^Twitter$'
);
#Sometimes you only want to cut out part of a title.
#Also checked as regex
@cutthesephrases = (
	'NyaaTorrents >> Torrent Info >>', 'Anime, manga, and music - Just say the word', ' on vimeo',
	'(?:wordpress|tumblr|blogspot)\.com', '( - )?View Single Post( - )?', '( \| Comment is free)? \| The Guardian',
	'Bungie\.net : ', ' - The Something Awful Forums', ' ?-> Check if your website is up or down\?',
	'(?:Halo:|Off Topic:) (?=The Flood :|Reach Forum :)', 'Baseball Video Highlights & Clips \| '
);


##this is still a ridiculous way to look for bad filetypes
#these will be checked as regexes but please keep them readable it's a list for a reason
@junkfiletypes = qw(
	webm mkv mp?4a? mpe?g wm[av] avi flv swf mov og[gmv] mp3 aif[fc]? wav
	(?:doc|ppt|xls)x? txt rtf pdf mobi epub lit sgf
	[tr]ar [gb]z2? zip 7z
	js css torrent
);

#Images larger than this size will get warnings
$largeimage = 2937856; #1256448 bytes is roughly 1.2MB.
@filesizecomment = (
	'that image is not large enough', 'NEEDS MORE MEGABYTES', 'that image is fairly large',
	'why do you hate australians so much'
);

@meanthings = qw(
	asshat twat ass
	douche dick cunt
);

#The Imgur API only allows 50 uploads from a given API key per day,
#so some idiots may need to be excluded
@nomirrornicks = qw[
	hal900\d meowcakes spaghettio twitch catwumman
];

$ver = '2011.10.12-02:32';