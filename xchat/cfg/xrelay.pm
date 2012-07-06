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
	'gintama'			=>	["Anime", [qw|horriblesubs rumbel|],"Gintama",	[undef],	2172],
	'shippuuden'		=>	["Anime", [qw|taka|],		"N2",			[undef],		1106],
#fall 2011 starts here
	chihayafuru			=>	["Anime", [qw|commie|], 	"Chihaya",	[undef],		2271], #25 [ntv]
	"gundam AGE"		=>	["Anime", ["sage"],			'AGE',			[undef],		2266],
	"guilty crown"		=>	["Anime", [qw'coalguys commie'],"GC",	[undef],		2259],
	horizon				=>	["Anime", [undef], 	"Horizon",		[undef],		2605], #kyoukai senjou no horizon
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
	pirates				=>	["Anime", [qw!horriblesubs commie!],'Pirates',	[undef],		2370], #26 eps [randomc]
	'basket army'		=>  ["Anime", [undef],			'Basketarmy',	[undef],		undef], #busou chuugakusei basketarmy
	"high school dxd"	=>  ["Anime", [qw!subdesu afftw!],'DxD',		[undef],		2366],	#12 eps [randomc]
	"rinne no lagrange"	=>  ["Anime", [qw!commie underwater!],'Lagrange',[undef],		2390],	#12 eps [randomc]
	"kill me baby"		=>  ["Anime", [qw!UTW Mazui!],	'KmB',			[undef],		2372],
	"inu x boku"		=>	["Anime", [qw!commie horriblesubs!],'InuBoku',	[undef],		2377],
	"kikinasai"			=>	["Anime", [qw!horriblesubs rori!],'PapaKiki',	[undef],		2383], #papa no iu no kikinasai!
	symphogear			=>	["Anime", [qw'gg commie'],	'Symphogear',	[undef],		2375], #senhime zesshou symphogear #13 eps [randomc]
	nisemonogatari		=>	["Anime", [qw!commie horriblesubs!],'Nisemono',	[undef],		undef],#2396], #13 eps [randomc] ##horriblesubs rips and releases the simulcasts before they're done airing. TV may be a dinosaur
	matteru				=>	["Anime", [qw'commie coalguys'],'Ano Natsu',[undef],		2368], #ano natsu de matteru #12eps [randomc]
	'high school boys'	=>  ["Anime", ['sage'],			'Boys',			[undef],		2386],	#daily lives of high school boys / Danshi Koukousei no Nichijou \x{7537}\x{5b50}\x{9ad8}\x{6821}\x{751f}\x{306e}\x{65e5}\x{5e38}
	'aquarion EVOL'		=>	["Anime", ['gg'],			'Aquarion',		[undef],		2378],
	'milky holmes'	=>	["Anime", ['kiteseekers', 'nicorip'],'Holmes',	[undef],		2359], #[Nicorip] Tantei Opera Milky Holmes Dai 2 Maku – 11 [1280x720][4B94F808].mp4
	gokujo				=>	["Anime", ['CMS'],			undef,			[undef],		undef],
	ozma				=>	["Anime", [qw'horriblesubs underwater'],	'Ozma',	[undef],		2455],
	ozuma				=>	["Anime", [qw'SFW'],		'Ozma',			[undef],		2455],
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
	'tari tari'			=>	["Anime", [undef],			'Tari',			[undef],		2593], #hs
	'famiglia'			=>	["Anime", [undef],			'Arcana',		[undef],		2594], #commie, HS
	'Jinrui wa Suitai Shimashita'=>["Anime",[undef],	'Fairies',		[undef],		2587], #hs, commie
	'chitose get you!'	=>	["Anime", [undef],			'Chitose',		[undef],		2576], #cms, hs[480p]
	'total eclipse'		=>	["Anime", [undef],			'MuvLuv',		[undef],		2586],
	'Yuruyuri'			=>	["Anime", [undef],			'Yuruyuri',		[undef],		2567], #hs
	'yuru yuri'			=>	["Anime", [undef],			"Yuruyuri",		[undef],		2567], #commie, fff
	'binbougami'		=>	["Anime", [undef],			'Binbougami',	[undef],		2589],
	'moyashimon'		=>	["Anime", [undef],			'Moyashimon',	[undef],		2602],
	'Koi to Senkyo to Chocolate'=>["Anime",	[undef],	'KoiChoco',		[undef],		2577],
	'imouto ga iru'		=>	["Anime", [undef],			'NakaImo',		[undef],		2592],
	'joshiraku'			=>	["Anime", [undef],			'Joshiraku',	[undef],		2590],
	'estetica'			=>	["Anime", [undef],			'Estetica',		[undef],		2584],
	'h ga dekinai'		=>	["Anime", [undef],			'BokuH',		[undef],		2575],
	'campione'			=>	["Anime", [undef],			'Campione',		[undef],		2571],
	'driland'			=>	["Anime", [undef],			'Driland',		[undef],		2596],
	'dog days'			=>	["Anime", [undef],			'Dogs',			[undef],		2595],
	'sword art online'	=>	["Anime", [undef],			'SAO',			[undef],		2588],
	'kokoro connect'	=>	["Anime", [undef],			'Kokoro',		[undef],		2585],
	'Oda Nobuna no Yabou'=>	["Anime", [undef],			'Nobuna',		[undef],		2572],
	'ebiten'			=>	["Anime", [undef],			'Ebiten',		[undef],		undef],
	'computer kakumei'	=>	["Anime", [undef],			undef,			[undef],		undef],
);

@blacklist = qw( 
remux .iso .flv .rmvb .fr PSP ipod [iP- unofficial un-official xvid ashtr 400p indonesian sunred sheline AnimeTL
animesenshi aoshen LQ bindesumux lorez thai italian persian getDBKAI gameternity senshiencodes 480p 848x480
german bakugan portuguese ptbr beyblade [RU] enconde ps3 dub Shani-san reencode re-encode animejoint anime-DDL
rena-chan imur88 chinese narutoforreal Español spanish animephase logn animestop grohotun pokemon youshikibi
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