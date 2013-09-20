
#airtime entry is useless now; blacklist entry may have never worked
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
	"fate \x{2044} zero"=>	["Anime", [qw|commie|],		"F/0",			["commie:8bit"],undef], #2277],
	"fate zero"			=>	["Anime", [qw|UTW|],		"F/0",			[undef],		undef], #2277],
	"phi brain"			=>	["Anime", [undef],			undef,			[undef],		undef], #2257],
	"tomodachi ga sukunai"=>["Anime", [qw|mazui|],		"Haganai",	 	[undef],		undef], #2270], #boku ha/wa tomodachi ga sukunai
	"ben-to"			=>	["Anime", [qw'gg'],			"Ben-to",		[undef],		undef],#2275], Ben-to airs first on TVA, which isn't listed on syoboi
	'plastic nee-san'	=>	["Anime", ['retouched'],	undef,			[undef],		undef], # web series
	'kyousogiga'		=>	["Anime", ['commie'],		undef,			[undef],		undef], #I dunno really
#winter 2011/2012
	pirates				=>	["Anime", [qw!horriblesubs commie!],'Pirates',	[undef],	undef], #2370], #26 eps [randomc]
	'basket army'		=>  ["Anime", [undef],			'Basketarmy',	[undef],		undef], #busou chuugakusei basketarmy
	"high school dxd"	=>  ["Anime", [undef],			'DxD',			[undef],		undef], #2366],	#12 eps [randomc]
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
	"Girlfriend X"	=>	["Anime", [undef],			'Girlfriend',	[undef],		undef], #Nazo no Kanojo X / Mysterious Girlfriend X ##HS
	"Achiga-hen"		=>	["Anime", ['underwater'],	'Saki',			[undef],		undef], #Saki: Achiga-hen episode of side-A ##underwater
	"Episode of Side A" =>	["Anime", ['horriblesubs'],	'Saki',			[undef],		undef],
	"Koi-Ken"			=>	["Anime", [undef],			'Koi-Ken',		[undef],		undef], #Koi-Ken!
	"Eureka Seven: AO"=>	["Anime", [undef],			'E7',			[undef],		undef], #ugh
	"furusato saisei"	=>	["Anime", [undef],			undef,			[undef],		undef], #dunno. shokotan op/ed though ##it's folktales from japan
	'folktales from japan'=>["Anime", ['horrible'],		undef,			[undef],		undef],
	"Lupin III"		=>	["Anime", [qw'sage gg'],	'Lupin',		[undef],		undef], #Lupin III - Mine Fujiko to Iu Onna ##sage
	"Lupin the Third"	=>	["Anime", [qw'sage'],		'Lupin',		[undef],		undef],
	"to Iu Onna"		=>	["Anime", [qw'sage commie gg'],'Lupin',		[undef],		undef],
	"Acchi Kocchi"	=>	["Anime", ['commie'],		'Kocchi',		[undef],		undef],
	"Nyarlko"			=>	["Anime", [qw'rori commie'],'Nyarlko',		[undef],		undef],
	"polar bear cafe"	=>	["Anime", ['horriblesubs'],	'Shirokuma',	[undef],		undef],
	'inuko-san'			=>	["Anime", ['migoto'],		'inuko',		[undef],		undef],
	'space brothers'	=>	["Anime", [qw'horriblesubs commie'],'Bros',	[undef],		undef],
#summer 2012
	'lagrange'			=>	["Anime", [undef],			'Lagrange',		[undef],		2574],
	'tari tari'			=>	["Anime", [qw'commie horrible'],'Tari',		[undef],		2593], #hs, doki
	'famiglia'			=>	["Anime", [qw'commie horrible doki'],'Arcana',[undef],		2594], #commie, HS
	'Jinrui wa Suitai Shimashita'=>["Anime",[qw'commie horrible'],'Fairies',[undef],	2587], #hs, commie
	'chitose get you!'	=>	["Anime", [undef],			'Chitose',		[undef],		2576], #cms, hs[480p]
	'total eclipse'		=>	["Anime", [qw'commie horrible'],'MuvLuv',	[undef],		2586], #commie, HS
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
	'dog days'			=>	["Anime", [qw'fbi hiryuu horrible'],'Dogs',	[undef],		2595], #"fbi"(fff/IB), hiryuu
	'sword art online'	=>	["Anime", [qw'horrible commie utw'],	'SAO',	[undef],	2588], #hs, commie, "utwoots"(utw/gotwoot)
	'kokoro connect'	=>	["Anime", [qw'horrible rori commie'],	'Kokoro',	[undef],2585], #rori, hs, commie
	'Oda Nobuna no Yabou'=>	["Anime", [qw'commie horrible'],'Nobuna',	[undef],		2572],
	'horizon'			=>	["Anime", [undef],			'Horizon',		[undef],		2605],
	'ebiten'			=>	["Anime", [undef],			'Ebiten',		[undef],		undef],
	'computer kakumei'	=>	["Anime", [undef],			undef,			[undef],		undef],
#fall 2012
	'sekai yori'		=>	["Anime", [qw'utw commie'],				'Shinsekai',[undef],		undef],
	'little busters'	=>	["Anime", [qw'utw mazui'],				'Busters',	[undef],		undef],
	'girls und panzer'	=>	["Anime", [undef],						'Tanks',	[undef],		undef],
	'aoi sekai no chuushin de'	=>	["Anime", [undef],				undef,		[undef],		undef],
	"\x{300c}K\x{300d}"	=> ["Anime", ['commie'],					'[K]',		[undef],		undef], #lol.
	'hayate'			=> ["Anime", ['commie'],					'Hayate',	[undef],		undef],
	'haitai nanafa'		=> ["Anime", [undef],						'Nanafa',	[undef],		undef],
	'chuunibyou'		=> ["Anime", [qw'URW gg'],					'Chuunibyou',[undef],		undef],
	'tonari no kaibutsu'=> ["Anime", [qw'horrible commie'],			'Tonari',	[undef],		undef], #commie chopped the -kun off
	'jojo'				=> ["Anime", [qw'gg nutbladder'],			'Jojo',		[undef], 		undef],
	#onii-chan dakedo ai sae areba kankeinai yo ne / oniiai / generic harem / doki and coppola
	'Bakuman S3'		=> ["Anime", [qw|TMD sage|],				"Bakuman",	[undef],		undef],
	'Ixion Saga'		=> ["Anime", [undef],						'Ixion',	[undef],		undef],
	'robotics;notes'	=> ["Anime", [qw[commie whynot]],			'R;N',		[undef],		undef],
#winter 2012/13
	'mangirl'			=>	["Anime", [qw'commie horriblesubs'],'Mangirl',	[undef],		undef], #fri/sat
	'maoyuu maou yuusha'=>	["Anime", [qw'fff commie horriblesubs'],'Maoyuu',		[undef],		undef], #HS FFF Hadena, friday/saturday
	'shuraba'			=>	["Anime", [qw'rori commie'],	'OreShura',		[undef],		undef], #<Ore no Kanojo to Osananajimi ga Shuraba Sugiru>, saturday night; HS is calling it oreshura
#	'bakumatsu gijinden roman'=>	["Anime", [undef],		'Roman',		[undef],		undef], #lupin knockoff featuring monkey punch
	'senyuu'			=>	["Anime", [undef],				'Senyuu',		[undef],		undef],
	'tamako market'		=>	["Anime", [qw'mazui commie'],	'Tamako',		[undef],		undef],
	'nekomonogatari'	=>	["Anime", [qw'commie utw mazui'],'Nekomono',	[undef],		undef],
	'minami-ke'			=>	["Anime", [undef],				'Minamike',		[undef],		undef],
	'vividred'			=>	["Anime", [qw'commie horriblesubs'],'Vividred',	[undef],		undef],
	'Gj-bu'				=>	["Anime", [qw'anime-koi'],		'GJbu',			[undef],		undef],
	'dokidoki! precure'	=>	["Anime", [qw"commie doremi"],	'Precure',		[undef],		undef],
	'mondaiji'			=>	["Anime", [qw'commie horriblesubs'],'Monday',	[undef],		undef],
#spring 2013
	'hataraku maou-sama!'=>	["Anime", [qw'commie fff'],		'Maou'],
	karneval			=>	["Anime", ['anime-koi'],		'Karneval'],
	'seishun love come'	=>	["Anime", [qw'commie whynot fff'],'Love'],
	'photokano'			=>	["Anime", ['utw'],				'PhotoKano'],
	'date a live'		=>	["Anime", [undef],				"a Live",		["FFF:v0"]], #fff
	'devil survivor'	=>	["Anime", [qw'horrible commie'],'Survivor',		[undef],		undef],
	'aku no hana'		=>	["Anime", ['gg'],				'Hana',			[undef],		undef],
	'ore no imouto'		=>	["Anime", [undef],				'OreImo',		[undef],		undef],
	'zettai bouei leviathan'=>	["Anime", [undef],			'Leviathan',	[undef],		undef],
	'shingeki no kyoujin'=>	["Anime", [qw'commie gg horrible'],	'Shingeki',	[undef],		undef],
	'yamato 2199'		=>	["Anime", [undef],				'Yamato',		[undef],		undef],
	'arata kangatari'	=>	["Anime", [undef],				'Arata',		[undef],		undef],
	railgun				=>	["Anime", [undef],				'Railgun'], #utw-mazui
	'Shingeki no Kyojin'=>	["Anime", [qw'gg coalguys commie'],	'Shingeki'],
	Gargantia			=>	["Anime", [undef],				'Gargantia'], #utw-vivid
	yuyushiki			=>	["Anime", [undef],				'Yuyushiki'], #commie/hs
	aiura				=>	["Anime", [qw'commie horrible'],'Aiura'],
	valvrave			=>	["Anime", [qw'gg horrible'],	'Valvrave'], #gg
	muromi				=>	["Anime", ['vivid'],			'Muromi'],
	'hentai ouji'		=>	["Anime", [qw'gg rori commie'],	'Henneko'],
#summer 2013
	'Tsukaiyou'			=>	["Anime", [undef],				'Dog'],	#Inu to Hasami wa Tsukaiyou
	'free!'				=>	["Anime", [qw'whynot horrible commie'],	'Free'], ##whynot hs commie
	'C3-Bu'				=>	["Anime", [undef],				'C3bu'], #Stella Jogakuin Koutouka C3-Bu ##commie koi
	'Danganronpa'		=>	["Anime", [undef],				'Dango'], #Danganronpa Kibou no Gakuen to Zetsubou no Koukousei The Animation ##13eps ##utw
	'Rozen Maiden'		=>	["Anime", [undef],				'Rozen'], #hs aidoru uya
	'Love Lab'			=>	["Anime", [undef],				'Love Lab'],
	'Kiroku'			=>	["Anime", [undef],				'KKK'], #Kitakubu Katsudou Kiroku ##12eps ********************************* #hs
	Service				=>	["Anime", [undef], 				'SxS'], #Servant x Service ******************************************* #hs commie
	mosaic				=>	["Anime", [undef],				'Mosaic'], #Kiniro Mosaic ##12eps
	Taiyou				=>	["Anime", [qw'underwater horrible'],	'ei'], #Genei wo Kakeru Taiyou **************************************************** ##underwater horrible
	'ro-kyu-bu'			=>	["Anime", [undef],				'RKB'], #rokyubu ##doremi
	'Prisma Ilya'		=>	["Anime", ['UTW'],				'Ilya',		["UTW:v0"]], #Fate/kaleid liner Prisma Illya ****************************************** ##utw
	Monogatari 			=>	["Anime", [undef],				'Monogatari'], #Monogatari ##2-cour
	genshiken			=>	["Anime", [undef],				'Genshiken'], #Genshiken Nidaime
	'Nichiyoubi'		=>	["Anime", [undef],				'Nichiyoubi'], #Kami-sama no Inai Nichiyoubi ##vivid, hatsuyuki
	'Fantasista Doll'	=>	["Anime", [undef],				'Dolls'],
	'Uchouten Kazoku'	=>	["Anime", [undef],				'Uchouten'],
	'Blood Lad'			=>	["Anime", [undef],				'Twilight'], #10eps
	'Watamote'			=>	["Anime", [undef],				'Watamote'],
	'Omaera ga Warui!'	=>	["Anime", [undef],				'Watamote'], #commie
	'Gin no Saji'		=>	["Anime", [undef],				'Spoon'], #11eps ************************************************************* ##HS
	'Silver Spoon'		=>	["Anime", [undef],				'Spoon'], ##commie whynot
	'Neptun'			=>	["Anime", [qw'commie horrible'],'Neptunia'], #Choujigen Game Neptune The Animation / neptunia
	'GATCHAMAN Crowds'	=>	["Anime", [undef],				'Gatcha'], #12eps *************************************
	'Kimi no Iru Machi'	=>	["Anime", [undef],				'KnIM'], #****************************
);

@blacklist = qw(
remux .iso .flv .rmvb .fr PSP ipod [iP- unofficial un-official xvid ashtr 400p indonesian sunred sheline AnimeTL
animesenshi aoshen LQ bindesumux lorez thai italian persian getDBKAI gameternity senshiencodes 480p 848x480
german bakugan portuguese ptbr beyblade [RU] enconde ps3 dub Shani-san reencode re-encode animejoint anime-DDL
rena-chan imur88 chinese narutoforreal Español spanish animephase logn animestop grohotun pokemon youshikibi ohys
kanjouteki (Hi10) iPhone [P] [ReinWeiss] .avi [Hadena] [NemDiggers] [Hi10] CherryBoyz narutoverse asaadas deadfish
Farfie Aniplex-rip
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

####colorscheme
$Cname	= "09";
$Csize	= "04";
$Curl	= "14";
$Ccomnt	= "11,01";
$Chntai	= "05,10";

$debug = 0;
