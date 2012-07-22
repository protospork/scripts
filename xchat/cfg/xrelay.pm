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
	'mayo chiki'		=>	["Anime", [qw|ayako doki|], "Chiki",		[undef],		undef], #2198],
	'gintama'			=>	["Anime", [qw|horriblesubs rumbel|],"Gintama",	[undef],	undef], #2172],
	'shippuuden'		=>	["Anime", [qw|taka|],		"N2",			[undef],		undef], #1106],
#fall 2011 starts here
	"gundam AGE"		=>	["Anime", ["sage"],			'AGE',			[undef],		2266],
	"guilty crown"		=>	["Anime", [qw'coalguys commie'],"GC",		[undef],		undef], #2259],
#	horizon				=>	["Anime", [undef], 			"Horizon",		[undef],		undef], #2605], #kyoukai senjou no horizon
	"fate \x{2044} zero"=>	["Anime", [qw|commie|],		"F/0",			["commie:8bit"],undef], #2277],
	"fate zero"			=>	["Anime", [qw|UTW|],		"F/0",			[undef],		undef], #2277],
	"phi brain"			=>	["Anime", [undef],			undef,			[undef],		undef], #2257],
	bakuman				=>	["Anime", [qw|TMD sage|],	"Bakuman",		['sage:^hi10p'],undef], #2295], #bakuman 2
	"tomodachi ga sukunai"=>["Anime", [qw|mazui|],		"BokuTomo", 	[undef],		undef], #2270], #boku ha/wa tomodachi ga sukunai
	"ben-to"			=>	["Anime", [qw'gg'],			"Ben-to",		[undef],		undef],#2275], Ben-to airs first on TVA, which isn't listed on syoboi
	'plastic nee-san'	=>	["Anime", ['retouched'],	undef,			[undef],		undef], # web series
	'kyousogiga'		=>	["Anime", ['commie'],		undef,			[undef],		undef], #I dunno really
#winter 2011/2012
	pirates				=>	["Anime", [qw!horriblesubs commie!],'Pirates',	[undef],	undef], #2370], #26 eps [randomc]
	'basket army'		=>  ["Anime", [undef],			'Basketarmy',	[undef],		undef], #busou chuugakusei basketarmy
	"high school dxd"	=>  ["Anime", [qw!subdesu afftw!],'DxD',		[undef],		undef], #2366],	#12 eps [randomc]
#	"rinne no lagrange"	=>  ["Anime", [qw!commie underwater!],'Lagrange',[undef],		2390],	#12 eps [randomc]
	nisemonogatari		=>	["Anime", [qw!commie horriblesubs!],'Nisemono',	[undef],	undef],#2396], #13 eps [randomc] ##horriblesubs rips and releases the simulcasts before they're done airing. TV may be a dinosaur
	matteru				=>	["Anime", [qw'commie coalguys'],'Ano Natsu',[undef],		undef], #2368], #ano natsu de matteru #12eps [randomc]
	'high school boys'	=>  ["Anime", ['sage'],			'Boys',			[undef],		undef], #2386],	#daily lives of high school boys / Danshi Koukousei no Nichijou \x{7537}\x{5b50}\x{9ad8}\x{6821}\x{751f}\x{306e}\x{65e5}\x{5e38}
	'aquarion EVOL'		=>	["Anime", ['gg'],			'Aquarion',		[undef],		undef], #2378],
#spring 2012
	upotte				=>	["Anime", ['commie'],		'Upotte',		[undef],		undef], #Upotte!! ##commie
	"tasogare otome"	=>	["Anime", ['utw', 'underwater', 'commie'],'Amnesia',[undef],undef], #Tasogare OtomexAmnesia
	"dusk maiden"		=>	["Anime", ['horriblesubs'],	'Amnesia',		[undef],		undef],
	Hyouka				=>	["Anime", [qw'commie mazui gg'],'Hyouka',	[undef],		undef],
	Jormungand			=>	["Anime", ['gg'],			'Jormungand',	[undef],		undef],
	"Shining Hearts"	=>	["Anime", [undef],			'Bread',		[undef],		undef], #hiryuu
	Sankarea			=>	["Anime", [qw'commie sfw doki'],'Sankarea',	[undef],		undef],
	"Natsuiro Kiseki"	=>	["Anime", [qw'warui rori'],	'NatsuKise',	[undef],		undef],		
	"Medaka Box"		=>	["Anime", [qw'whynot horriblesubs'],'Medaka',[undef],		undef], #whynot, HS, darksoul
	Zetman				=>	["Anime", [qw'doki whynot warui'],'Zetman',	[undef],		undef], #doki, whynot, warui
	Tsuritama			=>	["Anime", [undef],			'Tsuritama',	[undef],		undef],
	Yurumates			=>	["Anime", [undef],			'Yurumates',	[undef],		undef],
	"Accel World"		=>	["Anime", [qw'commie utw'],	'Accel',		[undef],		undef],
	"Girlfriend X"		=>	["Anime", [undef],			'Girlfriend',	[undef],		undef], #Nazo no Kanojo X / Mysterious Girlfriend X ##HS
	"Achiga-hen"		=>	["Anime", ['underwater'],	'Saki',			[undef],		undef], #Saki: Achiga-hen episode of side-A ##underwater
	"Episode of Side A" =>	["Anime", ['horriblesubs'],	'Saki',			[undef],		undef],
	"Koi-Ken"			=>	["Anime", [undef],			'Koi-Ken',		[undef],		undef], #Koi-Ken!
	"Eureka Seven: AO"	=>	["Anime", [undef],			'E7',			[undef],		undef], #ugh
	"furusato saisei"	=>	["Anime", [undef],			undef,			[undef],		undef], #dunno. shokotan op/ed though ##it's folktales from japan
	'folktales from japan'=>["Anime", ['horrible'],		undef,			[undef],		undef],
	"Lupin III"			=>	["Anime", [qw'sage gg'],	'Lupin',		[undef],		undef], #Lupin III - Mine Fujiko to Iu Onna ##sage
	"Lupin the Third"	=>	["Anime", [qw'sage'],		'Lupin',		[undef],		undef],
	"to Iu Onna"		=>	["Anime", [qw'sage commie gg'],'Lupin',		[undef],		undef],
	"Acchi Kocchi"		=>	["Anime", ['commie'],		'Kocchi',		[undef],		undef],
	"Nyarlko"			=>	["Anime", [qw'rori commie'],'Nyarlko',		[undef],		undef],
	"polar bear cafe"	=>	["Anime", ['horriblesubs'],	'Shirokuma',	[undef],		undef],
	'inuko-san'			=>	["Anime", ['migoto'],		'inuko',		[undef],		undef],
	'space brothers'	=>	["Anime", [qw'horriblesubs commie'],'Bros',	[undef],		undef],
#summer 2012
	'lagrange'			=>	["Anime", [undef],			'Lagrange',		[undef],		2574],
	'tari tari'			=>	["Anime", [qw'commie horrible'],'Tari',		[undef],		2593], #hs, doki
	'famiglia'			=>	["Anime", [qw'commie horrible doki'],'Arcana',[undef],		2594], #commie, HS
	'Jinrui wa Suitai Shimashita'=>["Anime",[undef],	'Fairies',		[undef],		2587], #hs, commie
	'chitose get you!'	=>	["Anime", [undef],			'Chitose',		[undef],		2576], #cms, hs[480p]
	'total eclipse'		=>	["Anime", [undef],			'MuvLuv',		[undef],		2586], #commie, HS
	'Yuruyuri'			=>	["Anime", [qw'horrible'],	'Yuruyuri',		[undef],		2567], #hs
	'yuru yuri'			=>	["Anime", [qw'commie fff shin-gx'],	"Yuruyuri",	[undef],	2567], #commie, fff, shin-gx
	'binbougami'		=>	["Anime", [undef],			'Binbougami',	[undef],		2589], #gg
	'moyashimon'		=>	["Anime", [qw'commie horrible gotwoot'],'Moya2',[undef],	2602], #gg, gotwoot
	'Koi to Senkyo to Chocolate'=>["Anime",[qw'pomf doki subdesu', 'm.3.3.w'],'KoiChoco',[undef],2577], #"pomf"(fff/rori), m33w, doki, subdesu
	'imouto ga iru'		=>	["Anime", [qw'UTW doki'],	'NakaImo',		[undef],		2592], #doki, utw
	'joshiraku'			=>	["Anime", [undef],			'Joshiraku',	[undef],		2590], #gg
	'estetica'			=>	["Anime", [undef],			'Estetica',		[undef],		2584], #subdesu
	'h ga dekinai'		=>	["Anime", [qw'subdesu gotyuu fff'],	'BokuH',[undef],		2575], #subdesu, "gotyuu"(gotwoot/hiryuu), fff
	'campione'			=>	["Anime", [qw'commie fff horrible'],'Campione',	[undef],	2571], #HS, fff, commie
	'driland'			=>	["Anime", [qw'sage'],		'Driland',		[undef],		2596],
	'dog days'			=>	["Anime", [undef],			'Dogs',			[undef],		2595], #"fbi"(fff/IB), hiryuu
	'sword art online'	=>	["Anime", [qw'horrible commie utw'],	'SAO',	[undef],	2588], #hs, commie, "utwoots"(utw/gotwoot)
	'kokoro connect'	=>	["Anime", [qw'horrible rori commie'],	'Kokoro',	[undef],2585], #rori, hs, commie
	'Oda Nobuna no Yabou'=>	["Anime", [undef],			'Nobuna',		[undef],		2572],
	'horizon'			=>	["Anime", [undef],			'Horizon',		[undef],		2605],
	'ebiten'			=>	["Anime", [undef],			'Ebiten',		[undef],		undef],
	'computer kakumei'	=>	["Anime", [undef],			undef,			[undef],		undef],
);

@blacklist = qw( 
remux .iso .flv .rmvb .fr PSP ipod [iP- unofficial un-official xvid ashtr 400p indonesian sunred sheline AnimeTL
animesenshi aoshen LQ bindesumux lorez thai italian persian getDBKAI gameternity senshiencodes 480p 848x480 peeps
german bakugan portuguese ptbr beyblade [RU] enconde ps3 dub Shani-san reencode re-encode animejoint anime-DDL
rena-chan imur88 chinese narutoforreal Espa�ol spanish animephase logn animestop grohotun pokemon youshikibi ohys
kanjouteki (Hi10) iPhone [P] [ReinWeiss] .avi [Hadena] [NemDiggers] [Hi10] CherryBoyz narutoverse asaadas deadfish
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