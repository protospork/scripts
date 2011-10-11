#config file for protobot's title retrieval script	#:c8h10n4o2.reload.config
$maxlength = 100;	#number of chars before the title is cut off +-5 for word boundaries
$controlchan = '#wat';	#primarily for the :c8h10n4o2.reload.config thing
$mirrorfile = '/home/proto/mirror.txt';
$imgurkey = 'c9358aa89d28f6bbde0984e09b990b1f'; #imgur free/anon API key
$spam_interval = 2;	#timeout (in seconds) between lines, to stop amsg kills (damnit GV)
$debugmode = 1;

#I'm treating ignoresites as plaintext strings and regex-escaping them
@ignoresites = qw(	
	google.com/search dropbox.com/gallery wiki drop.io macrochan wallbase 5z8.info explosm fukung
	smbc-comics wimp.com b3ta facebook questionablecontent amazon.com boo.by botto.ms zor.de boards\.4chan
	rapidshare megaupload last.fm pastebin moonbuggy javascript:void sankaku tinychat miscpix somethingawful
	diamondbackonline portal2sounds rei-ayanami.com/rei/imgboard fatpita.net suicidegirls.com exocomics
	woot.com wolframalpha.com nedroid.com motherless.com
);	#for the love of god do not remove javascript:void ##even though it doesn't seem to match the url regex

%shocksites = (
	'http://pfordee.com/cow/pics/hahha.jpg' => 'goatse'
);

@offchans = ('#honobono', '#tokyotosho', '#tokyotosho-api', '#lurk');

#error fallbacks, default responses, etc.
#checked as regexes please be reasonable
@defaulttitles = (
	'Newegg(?:\.com)? - Computer Parts',
	'Broadcast Yourself', 'Pancarkan Dirimu', 
	'^The Something Awful Forums$', '4\d\d', '[nN]ot [fF]ound', 
	'Log ?[IOio]n', 'Index [oO]f', '^Twitter$'
);

##this is still a ridiculous way to look for bad filetypes
#these will be checked as regexes but please keep them readable it's a list for a reason
@junkfiletypes = qw(
	webm mkv mp?4a? mpe?g wm[av] avi flv swf mov og[gmv] mp3 aif[fc]? wav
	(?:doc|ppt|xls)x? txt rtf pdf mobi epub lit sgf
	[tr]ar [gb]z2? zip 7z
	js css torrent
);	#jpe?g gif a?png tiff?

@cutthesephrases = (
	'NyaaTorrents >> Torrent Info >>', 'Anime, manga, and music - Just say the word', ' on vimeo',
	'(?:wordpress|tumblr|blogspot)\.com', '( - )?View Single Post( - )?', '( \| Comment is free)? \| The Guardian',
	'Bungie\.net : ', ' - The Something Awful Forums', ' ?-> Check if your website is up or down\?',
	'(?:Halo:|Off Topic:) (?=The Flood :|Reach Forum :)', 'Baseball Video Highlights & Clips \| '
);

@meanthings = qw(
	asshat twat ass
	douche dick cunt
);

$largeimage = 2937856; #1256448 bytes is roughly 1.2MB.
@filesizecomment = (
	'that image is not large enough', 'NEEDS MORE MEGABYTES', 'that image is fairly large',
	'why do you hate australians so much'
);

@mirrorchans = (
	'#wat', '#18+', '#fridge', '#anime', '#testchannelgoaway', '#bungienet', '#metal', '#hih', '#tds'
);
@nomirrornicks = qw[
	hal900\d meowcakes djstan spaghettio twitch catwumman
];

$ver = '2011.08.16-02:32';