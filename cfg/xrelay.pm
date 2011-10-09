#item (show) => "category|group,group2|topicname|tracker,tracker2,etc|blacklist,of,terms"
#TODO:
#TOSHO HAS NEW CATEGORIES


#	UNICODE:
#	U+[codepoint]s from wikipedia are HEX
#	chr() is BASE-10/DECIMAL
#	ord() is BASE-10/DECIMAL
#	regex/strings use \x{HEX}



%config = (
	LonE			=>	"Music	|LonE						|					|fansub-torrents		|mp3",
	nipponsei		=>	"Music	|nipponsei					|					|brokenonpurpose		|",
	eng				=>	"Hentai	|							|					|ehtracker,sukebei		|raw",	#english hentai on ehtracker\sukebei, hopefully
	"[BSS]"			=>	"Anime	|BSS						|					|minglong				|.avi",
	"THORA"			=>	"Anime	|thora						|					|						|",
	"ore no imouto"	=>	"Anime	|mazui						|Imouto				|mazuisubs,herpes,nyaa	|xvid",
	"star driver"	=>	"Anime	|gg							|Sparkle Driver		|						|",
	'index'			=>	"Anime	|UTW						|Index				|mazuisubs,nyaa			|",
	'bakuman'		=>	"Anime	|							|Bakuman			|minglong,nyaa			|",
	'mirai nikki'	=>	"Anime	|							|					|						|",
	koisento		=>	"Anime	|							|					|						|",	#koisento OVA
	"yuri seijin"	=>	"Anime	|							|					|						|",	#yuri seijin naoko-san TV
	fractale		=>	"Anime	|umee,utw					|Fractale			|						|",	#fractale TV
	"wandering son"	=>	"Anime	|umee,crunchy				|Musuko				|						|",	#wandering son TV
	'madoka magica'	=>	"Anime	|gg,nutbladder				|Madoka				|						|",	#mahou shoujo madoka magica
	'yumekui merry'	=>	"Anime	|gg							|Merry				|						|",
	gosick			=>	"Anime	|tsuki						|Gosick				|						|avi",
	'zombie desu'	=>	"Anime	|commie,TMD					|Zombies			|						|",
	'break blade'	=>	"Anime	|gg							|					|						|",
	'todoke 2nd'	=>	"Anime	|Eclipse					|2nd				|speedsubs				|",
	'deadman'		=>	"Anime	|							|Deadman			|						|480p",
	exorcist		=>	"Anime	|gg							|AoEx				|						|",	#ao no exorcist
	'hen zemi'		=>	"Anime	|wasurenai,whynot			|Zemi				|						|",
	'taiiku'		=>	"Anime	|doki,subdesu				|30-sai				|hologfx,nyaa,doki		|848",	#30-sai no hoken taiiku
	'iroha'			=>	"Anime	|doki,hatsuyuki				|Iroha				|hologfx,nyaa,doki		|848,704x400",	#hana-?saku iroha
	'dog days'		=>	"Anime	|ayako						|Days				|						|",
	'astarotte'		=>	"Anime	|pwq,commie					|Astarotte			|						|480p",	#astarotte no omocha!
	'money of soul'	=>	"Anime	|gg							|C					|						|",	#[C] THE MONEY OF SOUL AND POSSIBILITY CONTROL
	'ano hana'		=>	"Anime	|UTW						|Anohana			|						|480p",	#ano hi mita hana no namae o bokutachi wa mada shiranai
	'ano hi mita'	=>	"Anime	|gg							|Anohana			|						|",
	'steins;gate'	=>	"Anime	|mazui,UTW,commie			|S;G				|nyaa,mazuisubs			|SD,480p",
	'kaiji S2'		=>	"Anime	|nutbladder,commie			|Kaiji				|						|",
	"\x{2020}Holic Alive"	=>	"Anime	|commie				|holic				|						|480p",
	'bunny'			=>	"Anime	|commie						|Bunnies			|						|",
	nichijou		=>	"Anime	|doki,commie				|Nichijou			|nyaa,doki				|848,480p",
	aria			=>	"Anime	|UTW,gg						|Aria				|						|",
	'Gintama\''		=>	"Anime	|rumbel						|Gintama			|						|SD",
	gintama			=>	"Anime	|rumbel,horrible			|Gintama			|						|SD,480p",
	dororon			=>	"Anime	|gg							|Enma-kun			|						|",	#dororon enma-kun meeramera
	naruto			=>	"Anime	|taka						|Ship				|takafansubs			|",
	'denpa onna'	=>	"Anime	|commie						|Onna				|						|480p",
#summer 2011 starts hereish
	'mayo chiki'	=>	"Anime	|ayako,doki					|Chiki				|nyaa,anime-index		|",
	'No 6'			=>	"Anime	|gg,doki					|No6				|nyaa,anime-index		|",
#	'6'				=>	"Anime	|							|no6				|						|",	#No
	'usagi drop'	=>	"Anime	|commie,horrible,doki		|Drop				|nyaa,anime-index		|480p",
	mukuchi			=>	"Anime	|hadena,AFFTW,horrible		|Morita-san			|						|",	#morita-san wa mukuchi
	dolls			=>	"Anime	|doki,chihiro				|Dolls			|anime-index,nyaa,minglong	|",	#kamisama dolls
	yuruyuri		=>	"Anime	|horrible,tonde				|Yuruyuri			|						|SD,480p",
	"yuru yuri"		=>	"Anime	|coalgirls					|Yuruyuri			|coalgirls,wakku		|",
	'kaitou tenshi'	=>	"Anime	|							|kaitou				|						|848x480",
	'twin angel'	=>	"Anime	|chiki						|kaitou				|						|848x480", #kaitou tenshi
	nyanpire		=>	"Anime	|nutbladder					|nyanpire			|						|",
	'baka to test'	=>	"Anime	|commie,fffpeeps			|Bakatest			|						|480p",
	bakatest		=>	"Anime	|							|Bakatest			|						|",
	'itsuka tenma'	=>	"Anime	|derp,afftw					|Tenma				|						|",
	penguindrum		=>	"Anime	|gg							|Penguins			|						|",	#mawaru penguindrum
	nekogami		=>	"Anime	|fffpeeps					|Nekogami			|						|480p",
	'R-15'			=>	"Anime	|commie,chiki,horriblesubs	|R15				|						|480p",
	dantalian		=>	"Anime	|commie						|Dantalian			|						|",
	"mardock scramble"	=>	"Anime	|						|					|						|",	#YOU WANT THIS
	"Ro-Kyu-Bu"		=>	"Anime	|doki						|Loliball			|nyaa,anime-index		|848x480",
	memochou		=>	"Anime	|gg,UTW						|Memochou			|						|", #kamisama no memochou
	"sacred seven"	=>	"Anime	|gg							|Seven				|						|",
	'idolm@ster'	=>	"Anime	|doki,chibiki				|Idols				|nyaa,anime-index		|848x480",
	'Blood-c'		=>	"Anime	|doki,underwater,horrible	|Blood-C			|nyaa,anime-index		|",
	"manyuu hikenchou"=>"Anime	|subdesu					|Tit Ninjas			|nyaa					|xvid,avi",
	phantasm		=>	"Anime	|UTW						|					|nyaa,utw.me			|",
#fall 2011 starts here
	"hunter x hunter"=>	"Anime	|tsuki,horrible,kanjouteki	|HxH				|						|", #horrible
	chihayafuru		=>	"Anime	|commie						|					|						|",
	"gundam AGE"	=>	"Anime	|							|					|						|",
	"guilty crown"	=>	"Anime	|							|					|						|",
	horizon			=>	"Anime	|commie						|Horizon			|						|", #kyoukai senjou no horizon
	"persona 4"		=>	"Anime	|commie						|P4					|						|",
	"fate \x{2044} zero"=>	"Anime	|commie					|F/0				|						|8bit",
	"fate zero"		=>	"Anime	|UTW						|F/0				|						|", #utw
	"maken-ki"		=>	"Anime	|							|					|						|",
	symphony		=>	"Anime	|							|					|						|", #mashiro-iro symphony
	"ginyoku no fam"=>	"Anime	|							|					|						|", #last exile: ginyoku no fam
	"phi brain"		=>	"Anime	|							|					|						|",
	bakuman			=>	"Anime	|TMD,SFW					|Bakuman			|						|", #bakuman 2 #TMD and SFW
	"tomodachi ga sukunai"=>"Anime	|mazui					|BokuTomo			|mazuisubs				|", #boku ha/wa tomodachi ga sukunai
	"Cursed x Curious" =>"Anime	|UTW						|C3					|						|", #cube[d] x cursed x curious [C3]
	"C\xB3"			=>	"Anime	|commie						|C3					|						|",
	"ben-to"		=>	"Anime	|gg							|Ben-to				|						|",
	"mouretsu pirates"	=>	"Anime	|						|					|						|",
	tamayura		=>	"Anime	|							|					|						|",
	"Working'!!"	=>	"Anime	|gg							|Working			|						|"
);
@blacklist = qw( 
remux .iso .flv .rmvb .fr PSP ipod [iP- unofficial un-official xvid ashtr 400p indonesian sunred
animesenshi aoshen LQ bindesumux lorez thai italian persian getDBKAI gameternity senshiencodes 480p 848x480
german bakugan portuguese ptbr beyblade [RU] enconde ps3 dub Shani-san reencode re-encode animejoint
rena-chan imur88 chinese narutoforreal Español spanish animephase logn animestop grohotun pokemon 
kanjouteki (Hi10) iPhone [P]
); #regex special characters should NOT be escaped
@moreblacklist = (	
					"one piece", "galactic heroes", "kamen rider", "hitman reborn", 
					"shin koihime musou", "shugo chara", "heartcatch precure", "pretty cure",
					"hidamari sketch", "character song", "character album", "dragon ball",
					"tinkle", "shuffle", "rainbow gate", "cardfight", "doraemon",
					"pocket monsters"
				);
push @blacklist, @moreblacklist;

####colorscheme
$Cname	= "09";
$Csize	= "04";
$Curl	= "14";
$Ccomnt	= "11,01";
$Chntai	= "05,10";