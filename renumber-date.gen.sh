#!/bin/bash

set -euo pipefail

cd "$(dirname "$0")"

function move {
	local -r old="$1"
	local -r new="$2"
	if [ "${move:-}" ]; then
		mv -- "$old" "$new"
	else
		echo "mv -- \"$old\" \"$new\""
	fi
}

move "001 Scotland/" "20120325 Scotland"
move "002 Kat & Mike/" "20120327 Kat & Mike"
move "003 Me/" "old_3 Me"
move "004 Telescope/" "20120330 Telescope"
move "006 Prime time (lens tests)/" "20120402 Prime time (lens tests)"
move "007 Lab/" "20120403 Lab"
move "008 Sun/" "20120405 Sun"
move "009 Random crap and jc's prime/" "20120413 Random crap and jc's prime"
move "010 Double-focusing and proximity/" "20120505 Double-focusing and proximity"
move "011 Rani & jay/" "20120505 Rani & jay"
move "012 Very long exposures/" "20120505 Very long exposures"
move "013 Multi exposure/" "20120505 Multi exposure"
move "014 Beacon fell and Unilever/" "20120604 Beacon fell and Unilever"
move "015 RAF Waddington 2012/" "20120630 RAF Waddington 2012"
move "016 Pi/" "20120621 Pi"
move "017 Katmelon/" "20120714 Katmelon"
move "018 Kat with JC's nikon, Photogenic by JC/" "20120722 Kat with JC's nikon, Photogenic by JC"
move "019 Old stuff from Fuji/" "20111125 Old stuff from Fuji"
move "020 Stretford Park/" "20120716 Stretford Park"
move "021 Kat in woods/" "20120722 Kat in woods"
move "022 Jc drunk/" "old_22 Jc drunk"
move "023 Moon/" "20120804 Moon"
move "024 Katiana/" "20120808 Katiana"
move "025 Showing JC the Pentax lenses and also testing the Sigma at short range/" "20120814 Showing JC the Pentax lenses and also testing the Sigma at short range"
move "026 Testing Sigma at uni/" "20120816 Testing Sigma at uni"
move "027 Kat & Sigma/" "20120818 Kat & Sigma"
move "028 Horwich/" "20120902 Horwich"
move "029 Weird bug in living room/" "20120906 Weird bug in living room"
move "030 Horwich (Kat+Ant)/" "20120908 Horwich (Kat+Ant)"
move "031 Cris testing lens & PhotoSoc UMIST/" "20121010 Cris testing lens & PhotoSoc UMIST"
move "032 Shahneela Rivington/" "20121012 Shahneela Rivington"
move "033 Lab harassment/" "20121018 Lab harassment"
move "034 Squash (35mm prime test)/" "20121019 Squash (35mm prime test)"
move "035 Hill/" "20121021 Hill"
move "036 Lab harassment (second group)/" "20121023 Lab harassment (second group)"
move "037 Monika's birthday/" "20121024 Monika's birthday"
move "038 Fibrelamp+Bokeh/" "20121103 Fibrelamp+Bokeh"
move "039 John's art/" "20121030 John's art"
move "040 Playing with prime/" "20121104 Playing with prime"
move "041 Rusholme from Shahneela's balcony/" "20121104 Rusholme from Shahneela's balcony"
move "042 Bonfire night (Shah+Cris)/" "20121105 Bonfire night (Shah+Cris)"
move "043 Francine weekend/" "20121108 Francine weekend"
move "044 Sara's birthday/" "20121112 Sara's birthday"
move "045 Pooplets in preston + Jc's bday dinner thing/" "20121117 Pooplets in preston + Jc's bday dinner thing"
move "046 Monika's leaving do/" "20121123 Monika's leaving do"
move "047 Moon Jupiter/" "20121128 Moon Jupiter"
move "048 Shah hyper/" "20121128 Shah hyper"
move "049 I'm John/" "20121207 I'm John"
move "050 Preston with Kat, Dec2012/" "20121216 Preston with Kat, Dec2012"
move "051 Shah's birthday + Bokeh/" "20121217 Shah's birthday + Bokeh"
move "052 Dad's D5100 first lot/" "20121226 Dad's D5100 first lot"
move "053 Rani+Jay+Shah sleeping+Gangham Rani/" "20121225 Rani+Jay+Shah sleeping+Gangham Rani"
move "054 Israt's painting + Dad at Rivington/" "20130112 Israt's painting + Dad at Rivington"
move "055 Shahneela at 8am after steaks/" "20130116 Shahneela at 8am after steaks"
move "056 Keylime Pi/" "20130122 Keylime Pi"
move "057 Sky + Shah/" "20130126 Sky + Shah"
move "058 Lytham beach sunset/" "20130202 Lytham beach sunset"
move "059 Israt birthday/" "20130214 Israt birthday"
move "060 Bday dinner Tai Wu/" "20130302 Bday dinner Tai Wu"
move "061 Joanne, Bath/" "20130324 Joanne, Bath"
move "062 Dad playing with my camera, monopoly/" "20130330 Dad playing with my camera, monopoly"
move "063 Chickens, Golf, Oxford lab, Beach sunset, Cave+aloowalk/" "20130506 Chickens, Golf, Oxford lab, Beach sunset, Cave+aloowalk"
move "064 Sunset timelapse/" "20130514 Sunset timelapse"
move "065 Ducklings/" "20130525 Ducklings"
move "066 Parlick, gliders, JBLs/" "20130526 Parlick, gliders, JBLs"
move "067 Lancaster sunset, cows/" "20130601 Lancaster sunset, cows"
move "068 Buteefish garden, bees/" "20130609 Buteefish garden, bees"
move "069 NFSMW on PC/" "20130609 NFSMW on PC"
move "070 Tawseef birthday at Shahneela's/" "20130629 Tawseef birthday at Shahneela's"
move "071 RAF Waddington 2013/" "20130706 RAF Waddington 2013"
move "072 Aloo Graduation/" "20130717 Aloo Graduation"
move "073 Testing HD nightvision video/" "old_73 Testing HD nightvision video"
move "074 Snowdon with Dad/" "20130729 Snowdon with Dad"
move "075 Manchester from a distance/" "20130801 Manchester from a distance"
move "076 Rivington and butterflies/" "20130803 Rivington and butterflies"
move "077 Cousins+chickens+Beacon Fell/" "20130806 Cousins+chickens+Beacon Fell"
move "078 Melbreak Hill/" "20130810 Melbreak Hill"
move "079 Wine/" "old_79 Wine"
move "080 Garden plants (sunflowers, mint, cress)/" "20130825 Garden plants (sunflowers, mint, cress)"
move "081 Douchebag taxi driver reversed into me/" "20130909 Douchebag taxi driver reversed into me"
move "082 Conwy beach, Wales with Disha/" "20130928 Conwy beach, Wales with Disha"
move "083 Lake district, Ambleside, Windermere/" "20131013 Lake district, Ambleside, Windermere"
move "084 Power cut/" "20131015 Power cut"
move "085 Dramatic clouds in Preston/" "20131019 Dramatic clouds in Preston"
move "086 Sigma 10-20mm test/" "20131030 Sigma 10-20mm test"
move "087 Sigma 10-20mm woods + aloo/" "20131031 Sigma 10-20mm woods + aloo"
move "088 Iceland, Nov-2013/" "20131110 Iceland, Nov-2013"
move "089 Aura SMPS/" "20121015 Aura SMPS"
move "090 JC's LED strip/" "20131212 JC's LED strip"
move "091 HMRC tax stuff Sigma Pi/" "20131213 HMRC tax stuff Sigma Pi"
move "092 Storm @ Lytham beach/" "20131224 Storm @ Lytham beach"
move "093 Storm @ Blackpool/" "20131224 Storm @ Blackpool"
move "094 Mum+dad in house (mum wideangle lols)/" "20131226 Mum+dad in house (mum wideangle lols)"
move "095 Laird/" "20131227 Laird"
move "096 Beacon Fell sunset/" "20131231 Beacon Fell sunset"
move "097 Failed northern lights @ Blackburn/" "20140110 Failed northern lights @ Blackburn"
move "100 Wideangle warmup, Iceland/" "20131110 Wideangle warmup, Iceland"
move "101 Bus and Reykjavik, Iceland/" "20131110 Bus and Reykjavik, Iceland"
move "102 Stormhike, Iceland/" "20131111 Stormhike, Iceland"
move "103 Golden Circle and snowmobiles, Iceland/" "20131112 Golden Circle and snowmobiles, Iceland"
move "104 Post-snowmobile, Iceland/" "20131112 Post-snowmobile, Iceland"
move "105 Around Reykjavik, Iceland/" "20131113 Around Reykjavik, Iceland"
move "106 Northern lights hunt (fail), Iceland/" "20131113 Northern lights hunt (fail), Iceland"
move "107 Journey home, Iceland/" "20131114 Journey home, Iceland"
move "111 Dad's wideangle and fisheye adaptor/" "20140130 Dad's wideangle and fisheye adaptor"
move "112 Warsaw, Poland/" "20140218 Warsaw, Poland"
move "113 Vilnius, Lithuania/" "20140222 Vilnius, Lithuania"
move "114 Tallinn, Estonia/" "20140225 Tallinn, Estonia"
move "115 Mari (private), Estonia/" "20140305 Mari (private), Estonia"
move "116 Tallinn, Estonia/" "20140306 Tallinn, Estonia"
move "117 Tallinn, Estonia/" "20140324 Tallinn, Estonia"
move "118 Tallinn, Estonia/" "20140403 Tallinn, Estonia"
move "119 Riga, Latvia/" "20140412 Riga, Latvia"
move "120 Vilnius, Lithuania/" "20140413 Vilnius, Lithuania"
move "121 Warsaw, Poland/" "20140417 Warsaw, Poland"
move "122 Krakow, Poland/" "20140418 Krakow, Poland"
move "123 Helsinki, Finland/" "20140419 Helsinki, Finland"
move "124 Back in Estonia/" "20140426 Back in Estonia"
move "125 Linnahall, Estonia/" "20140523 Linnahall, Estonia"
move "125 Pärnu, Estonia/" "20140517 Pärnu, Estonia"
move "125 Summer festival, Estonia/" "20140623 Summer festival, Estonia"
move "126 Saaremaa, Estonia/" "20140618 Saaremaa, Estonia"
move "127 Tolla, Estonia/" "20140628 Tolla, Estonia"
move "128 Suit, Estonia/" "20140630 Suit, Estonia"
move "130 Parade, Estonia/" "20140705 Parade, Estonia"
move "131 Song and dance festival, Estonia/" "20140706 Song and dance festival, Estonia"
move "135 Helsinki (Mario party + hostel)/" "20140712 Helsinki (Mario party + hostel)"
move "136 Norway/" "20140714 Norway"
move "137 Eidfjord, Norway/" "20140715 Eidfjord, Norway"
move "138 Long bridge (Norway)/" "20140715 Long bridge (Norway)"
move "139 Road trip to Oslo, Norway/" "20140716 Road trip to Oslo, Norway"
move "140 Meteor + Oslo, Norway/" "20140716 Meteor + Oslo, Norway"
move "141 Oslo, Norway/" "20140717 Oslo, Norway"
move "142 Oslo 3D timelapse, Norway/" "20140718 Oslo 3D timelapse, Norway"
move "143 Oslo, Norway/" "20140717 Oslo, Norway"
move "144 Oslo, Norway/" "20140718 Oslo, Norway"
move "145 Open air, around Vanalinn, Estonia, Dusk timelapse/" "20140719 Open air, around Vanalinn, Estonia, Dusk timelapse"
move "146 Patarei, sea museum, Estonia/" "20140725 Patarei, sea museum, Estonia"
move "147 Boat to Finland/" "20140726 Boat to Finland"
move "148 Boat to Finland (timelapse)/" "20140726 Boat to Finland (timelapse)"
move "150 Tactical Shooting, Estonia/" "20140724 Tactical Shooting, Estonia"
move "160 Suomenlinna boat timelapse, Finland/" "20140727 Suomenlinna boat timelapse, Finland"
move "161 Suomenlinna, Finland/" "20140727 Suomenlinna, Finland"
move "162 Suomenlinna, Finland/" "20140727 Suomenlinna, Finland"
move "170 Tolla Van Gogh/" "20140802 Tolla Van Gogh"
move "171 Tolla sunset with Mari/" "20140804 Tolla sunset with Mari"
move "172 Tolla insects/" "20140802 Tolla insects"
move "173 South Estonia tour/" "20140805 South Estonia tour"
move "174 Sandras summer house/" "20140808 Sandras summer house"
move "175 Watermelon/" "20140814 Watermelon"
move "176 Tartu weekend/" "20140906 Tartu weekend"
move "177 Potato picking/" "20140913 Potato picking"
move "178 Potato picking after/" "20140913 Potato picking after"
move "183 Haapsalu/" "20141004 Haapsalu"
move "184 Kardo/" "20141011 Kardo"
move "185 Reddy pubcrawl/" "20141113 Reddy pubcrawl"
move "186 Snow and booze for UK, Estonia/" "20141121 Snow and booze for UK, Estonia"
move "190 UK christmas trip/" "20141217 UK christmas trip"
move "191 Home and Dinner/" "20141219 Home and Dinner"
move "200 Xmas Kaiu/" "20141223 Xmas Kaiu"
move "201 Xmas Kaiu and swamp/" "20141226 Xmas Kaiu and swamp"
move "202 Mari knitting and glowstick/" "20150102 Mari knitting and glowstick"
move "203 Stockholm with Kat, Sweden/" "20150123 Stockholm with Kat, Sweden"
move "204 Amsterdam (Ploom, Kat, Macca, Birgit, Taavi)/" "20150220 Amsterdam (Ploom, Kat, Macca, Birgit, Taavi)"
move "205 Aurora, Tallinn/" "20150317 Aurora, Tallinn"
move "206 Copenhagen with Dad, Denmark/" "20150319 Copenhagen with Dad, Denmark"
move "207 Tolla long timelapse, Estonia/" "20150425 Tolla long timelapse, Estonia"
move "208 Volle birthday/" "20150425 Volle birthday"
move "209 Ploomi Isa birthday/" "20150425 Ploomi Isa birthday"
move "210 Andra birthday/" "20150502 Andra birthday"
move "211 Dad and Mari in UK/" "20150618 Dad and Mari in UK"
move "212 White scar with Mari/" "20150619 White scar with Mari"
move "213 North-east Estonia/" "20150728 North-east Estonia"
move "214 Tolla dark timelapse/" "20150425 Tolla dark timelapse"
move "215 EF weekend/" "20150806 EF weekend"
move "216 Dad+Mari Lithuania/" "20150810 Dad+Mari Lithuania"
move "217 Dad+Mari Trakkai timelapses/" "20150810 Dad+Mari Trakkai timelapses"
move "218 Dad+Mari Trakkai/" "20150810 Dad+Mari Trakkai"
move "219 Dad at Tondi shooting/" "20150814 Dad at Tondi shooting"
move "220 Aegna Saar/" "20150817 Aegna Saar"
move "221 Rummu quarry with Mari+Celia/" "20150818 Rummu quarry with Mari+Celia"
move "222 Milky way, Kaiu/" "20150905 Milky way, Kaiu"
move "223 Pärnu, Estonia/" "20150912 Pärnu, Estonia"
move "224 Farmers protest, Tallinn, Estonia/" "20150914 Farmers protest, Tallinn, Estonia"
move "225 Mari using D5100/" "20151205 Mari using D5100"
move "226 Kiruna/" "20160114 Kiruna"
move "227 Lab timelapse, Kiruna/" "20160114 Lab timelapse, Kiruna"
move "228 IRF, Kiruna/" "20160114 IRF, Kiruna"
move "229 Snow trails timelapse, Kiruna/" "20160115 Snow trails timelapse, Kiruna"
move "230 Ice rink timelapse, Kiruna/" "20160115 Ice rink timelapse, Kiruna"
move "231 Ice rink day, Kiruna/" "20160115 Ice rink day, Kiruna"
move "232 Failed aurora, Kiruna/" "20160120 Failed aurora, Kiruna"
move "233 Team dinner/" "20160123 Team dinner"
move "234 Clean-room timelapse, IRF/" "20160125 Clean-room timelapse, IRF"
move "236 Pripyat boredomlapse/" "20160130 Pripyat boredomlapse"
move "237 Aurora 1/" "20160202 Aurora 1"
move "238 Aurora timelapse 1/" "20160202 Aurora timelapse 1"
move "239 Aurora timelapse 2/" "20160203 Aurora timelapse 2"
move "240 Integration timelapse/" "20160215 Integration timelapse"
move "241 Aurora at late finish/" "20160215 Aurora at late finish"
move "242 Aurora at Bromsgatan/" "20160215 Aurora at Bromsgatan"
move "243 Scenery/" "20160213 Scenery"
move "244 Steak, integration, coop/" "20160219 Steak, integration, coop"
move "245 Snowdiving, caprice/" "20160225 Snowdiving, caprice"
move "246 Estonia break/" "20160226 Estonia break"
move "247 EF brochure/" "20160302 EF brochure"
move "248 Huge pi-day aurora/" "20160315 Huge pi-day aurora"
move "249 Aurora timelapse from balcony/" "20160316 Aurora timelapse from balcony"
move "250 More kiruna/" "20160318 More kiruna"
move "251 qb50 photos/" "20160322 qb50 photos"
move "252 More kiruna/" "20160323 More kiruna"
move "253 Igloo/" "20160403 Igloo"
move "254 Aurora from balcony, over the houses/" "20160412 Aurora from balcony, over the houses"
move "255 Radio equation/" "20160429 Radio equation"
move "256 Shake test for qb01/" "20160509 Shake test for qb01"
