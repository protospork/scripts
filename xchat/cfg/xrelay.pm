#item (show) => ["cat", ["group1", "group2"], "stitle", "blacklist", airtime]

#Sample test line:
#	/recv :TokyoTosho!~TokyoTosh@Tokyo.Tosho PRIVMSG #tokyotosho-api :Torrent367273Anime1[TMD]_Bakuman_-_10_[F7D2E973].mkvhttp://www.nyaa.eu/?page=download&tid=178017213.52MBshut up I'm testing something

#	UNICODE:
#	U+[codepoint]s from wikipedia are HEX
#	chr() is BASE-10/DECIMAL
#	ord() is BASE-10/DECIMAL
#	regex/strings use \x{HEX}

%config = (
	LonE				=>	["Music", [qw|LonE|],		undef,			[undef],		undef],
	nipponsei			=>	["Music", [qw|nipponsei|],	undef,			[undef],		undef],
	eng					=>	["Hentai", [undef],			undef,			["eng:raw"],	undef],	#english hentai on ehtracker\sukebei, hopefully
	"[BSS]"				=>	["Anime", [qw|BSS|],		undef,			["bss:.avi"],	undef],
	"THORA"				=>	["Anime", ["thora"],		undef,			[undef],		undef],
	'mayo chiki'		=>	["Anime", [qw|ayako doki|], "Chiki",		[undef],		2198],
	"mardock scramble"	=>	["Anime", [undef],			undef,			[undef],		undef],
	'gintama'			=>	["Anime", [qw|horriblesubs rumbel|],"Gintama",	[undef],		2172],
	'shippuuden'		=>	["Anime", [qw|taka|],		"Ship",			[undef],		1106],
#fall 2011 starts here
	chihayafuru			=>	["Anime", [qw|commie|], 	"Chihaya",	[undef],		2271], #25 [ntv]
	"gundam AGE"		=>	["Anime", ["sage"],			'AGE',			[undef],		2266],
	"guilty crown"		=>	["Anime", [qw'coalguys commie'],"GC",	[undef],		2259],
	horizon				=>	["Anime", [qw|commie|], 	"Horizon",		[undef],		2254], #kyoukai senjou no horizon
	"persona 4"			=>	["Anime", [qw|commie|],		"P4",			[undef],		2260],
	"fate \x{2044} zero"=>	["Anime", [qw|commie|],		"F/0",			["commie:8bit"],2277],
	"fate zero"			=>	["Anime", [qw|UTW|],		"F/0",			[undef],		2277],
	'last exile'		=>	["Anime", [qw[commie sfw]],	'Last Exile',	['sfw:^hi10p'],	2253],
	"phi brain"			=>	["Anime", [undef],			undef,			[undef],		2257],
	bakuman				=>	["Anime", [qw|TMD sage|],	"Bakuman",		['sage:^hi10p'],2295], #bakuman 2
	"tomodachi ga sukunai"=>["Anime", [qw|mazui|],		"BokuTomo", 	[undef],		2270], #boku ha/wa tomodachi ga sukunai
	"ben-to"			=>	["Anime", [qw'gg'],			"Ben-to",		[undef],		undef],#2275], Ben-to airs first on TVA, which isn't listed on syoboi
	'mirai nikki'		=>	["Anime", [qw'horriblesubs SS'],"Nikki",		[undef],		2273],
	'plastic nee-san'	=>	["Anime", ['retouched'],	undef,			[undef],		undef], # web series
	'majikoi'			=>	["Anime", ['horriblesubs'],		undef,			[undef],		2276],
	'shinasai'			=>	["Anime", ['hiryuu'],		undef,			['hiryuu:^Hi10P'],	2276],
	'shana final'		=>	["Anime", ['eclipse'],		'Shana',		[undef],		2262], 
	'carnival phantasm'	=>	["Anime", ['UTW'],			'Phantasm',		[undef],		undef],	#OVA
	'kyousogiga'		=>	["Anime", ['commie'],		undef,			[undef],		undef], #I dunno really
#winter 2011/2012
	pirates				=>	["Anime", [qw!horriblesubs commie!],'Pirates',	['horriblesubs:1080p'],		2370], #26 eps [randomc]
	basketarmy			=>  ["Anime", [undef],			'Basketarmy',	[undef],		undef], #busou chuugakusei basketarmy
	randsell			=>  ["Anime", ['horriblesubs'],		'Randoseru',	['horriblesubs:1080p'],		2363], #recorder to randoseru ##five minute show and hadena still wrecked it
	"high school dxd"	=>  ["Anime", [qw!subdesu afftw!],'DxD',		[undef],		2366],	#12 eps [randomc]
	another				=>  ["Anime", [qw!commie underwater!],'Another',[undef],		2373], #12eps [randomc]
	"rinne no lagrange"	=>  ["Anime", [qw!commie underwater!],'Lagrange',[undef],		2390],	#12 eps [randomc]
	"rock shooter"		=>  ["Anime", [qw!commie nishishi!],'BRS',		[undef],		2187], #black\x{2605}rock shooter #8 eps [randomc]
	"kill me baby"		=>  ["Anime", [qw!UTW Mazui!],	'KmB',			[undef],		2372],
	"inu x boku"		=>	["Anime", [qw!commie horriblesubs!],'InuBoku',	['horriblesubs:1080p'],		2377],
	"kikinasai"			=>	["Anime", [qw!horriblesubs rori!],'PapaKiki',	['horriblesubs:1080p'],		2383], #papa no iu no kikinasai!
	'brave 10'			=>	["Anime", ['doki'],			'Brave10',		[undef],		2382], #12eps [randomc]
	symphogear			=>	["Anime", [qw'gg commie'],	'Symphogear',	[undef],		2375], #senhime zesshou symphogear #13 eps [randomc]
	nisemonogatari		=>	["Anime", [qw!commie horriblesubs!],'Nisemono',	['horriblesubs:1080p'],		undef],#2396], #13 eps [randomc] ##horriblesubs rips and releases the simulcasts before they're done airing. TV may be a dinosaur
	matteru				=>	["Anime", [qw'commie coalguys'],'Ano Natsu',[undef],		2368], #ano natsu de matteru #12eps [randomc]
	gokujyou			=>	["Anime", [undef],			undef,			[undef],		undef], #?
	'high school boys'	=>  ["Anime", ['sage'],			'Boys',			[undef],		2386],	#daily lives of high school boys / Danshi Koukousei no Nichijou \x{7537}\x{5b50}\x{9ad8}\x{6821}\x{751f}\x{306e}\x{65e5}\x{5e38}
	'aquarion EVOL'		=>	["Anime", ['gg'],			'Aquarion',		[undef],		2378],
	'milky holmes II'	=>	["Anime", ['kiteseekers'],	'Holmes',		[undef],		2359],
	gokujo				=>	["Anime", ['CMS'],			undef,			[undef],		undef],
);
@blacklist = qw( 
remux .iso .flv .rmvb .fr PSP ipod [iP- unofficial un-official xvid ashtr 400p indonesian sunred
animesenshi aoshen LQ bindesumux lorez thai italian persian getDBKAI gameternity senshiencodes 480p 848x480
german bakugan portuguese ptbr beyblade [RU] enconde ps3 dub Shani-san reencode re-encode animejoint
rena-chan imur88 chinese narutoforreal Espa�ol spanish animephase logn animestop grohotun pokemon 
kanjouteki (Hi10) iPhone [P] [ReinWeiss] .avi [Hadena] [NemDiggers]
); #regex special characters should NOT be escaped
@moreblacklist = (	
					"one piece", "galactic heroes", "kamen rider", "hitman reborn", 
					"shin koihime musou", "shugo chara", "heartcatch precure", "pretty cure",
					"hidamari sketch", "character song", "character album", "dragon ball",
					"tinkle", "shuffle", "rainbow gate", "cardfight", "doraemon",
					"pocket monsters", "tennis"
				);
push @blacklist, @moreblacklist;

$do_hentai = 0;
$do_airtime = 0;

####colorscheme
$Cname	= "09";
$Csize	= "04";
$Curl	= "14";
$Ccomnt	= "11,01";
$Chntai	= "05,10";