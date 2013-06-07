#!/usr/bin/perl -w

#Copyright Filip Gadiuta 2009
#v.010 este cea din ianuarie 2008
#v.011 este in lucru

#Curatare folder de lucru 99TEST (de adaptat la nevoie)
@desters = glob('c:\Users\Filip\Documents\Perl\Teste\99TEST\*.xml');
foreach $junk (@desters) {
	unlink($junk);
}

#Aici incarc intr-un array fisierele din folder.
#Numele folderului trebuie adaptat!
@lista = glob('c:\Users\Filip\Documents\Perl\Teste\9TEST\*.html');

#Ma misc in folderul respectiv.
#Oare foloseste la ceva?
chdir('c:\Users\Filip\Documents\Perl\Teste\9TEST') || die "Cannot chdir ($!)";

#Pentru fiecare fisier, il deschidem, il prelucram si apoi salvam
#rezultatul in alt folder.
foreach $fisier (@lista) {

	#Introducem continutul fisierului in variabila scalara $continut
	#Prefer variabila scalara, fiindca vreau sa unesc randuri, sa
	#regex in functie de pozitia unui rand fata de celalalt
	local (*DATA);
	open( DATA, $fisier )
	  || die "ATENTIE: Nu am putut deschide un fisier!!! Iesire din program.\n";
	my $continut = do { local ($/); <DATA> };

#Obtinem numele fisierului, fara cale, in variabila $nume
#!!!Aici ar trebui un pic mai elegant, sa aleaga penultimul element din array....
	$x = $fisier;
	$x =~ s/\\/:/g;
	$x =~ s/\./:/g;
	$x =~ s/::/:/;
	@primularr = split( /:/, $x );
	$nume      = $primularr[7];

	#Aici vin inlocuirile in $continut
	#Vezi subrutina
	$continut = inlocuiri( $continut, $nume );

	#Scriem fisierul nou in folderul de fisiere noi (de actualizat calea!)
	$x = "c:\\Users\\Filip\\Documents\\Perl\\Teste\\99TEST\\$nume.xml";
	open DATAOUT, ">$x" || die "Nu pot deschide pentru scriere $fisier $!";
	print DATAOUT "$continut";
	close(DATAOUT);

	#Aici ar trebui sa creez un log
	#Eventual definesc o functie tiparire () si, in loc de print, zic tiparire
	print "Am creat fisierul $x\n";
}

#Inlocuirile efective se afla intr-o subrutina
sub inlocuiri {
	my @data    = @_;
	my $decizie = $data[0];
	my $cod     = $data[1];
	print "Prelucram $cod \n";
	#####################################################
	#scot tab-urile de aliniere a html-ului
	$decizie =~ s/\n\t+/\n/g
	  or print "ATENTIE: Nu am putut elimina taburile de aliniere din $cod \n";

#Aici elimin bucata <!-- --> din html, care e singura unde am capete de linii valide care nu se termina in ">"
#Modificatorul /s este ca sa ia si \n-urile in calcul
	$decizie =~ s/<!--(.+)-->//s
	  or print "ATENTIE: Nu am putut inlocui <!-- --> in $cod \n";

	#Eliminan hyperlinkurile
	#ATENTIE, aici dispar si posibile note de subsol!!!!!
	#Am mutat bucata chiar inainte de sfarsiturile de linie inutile, altfel pot ramane unele neeliminate (2009)
	$decizie =~ s/<A\sHREF="(.+?)">//sg;
	$decizie =~ s/<\/A>//sg;

	  #Eliminam sfarsiturile de linie inutile
	$decizie =~ s/([^>])\n/$1 /sg
	  or print "ATENTIE: Nu am putut inlocui sfarsiturile de linie in $cod \n";

	#Il facem xml la inceput si la sfarsit
	$decizie =~ s/<\/HTML>/<\/lex>/
	  or print "ATENTIE: Nu a mers </lex> in $cod \n";
	$decizie =~
s/<!DOCTYPE HTML PUBLIC "-\/\/W3C\/\/DTD HTML 4.0 Transitional\/\/EN">\n<HTML>/<?xml version="1.0" encoding="ISO-8859-2"?>\n<lex>/s
	  or print "ATENTIE: Nu a mers <lex> in $cod \n";
	#Extrag CHANGED din fisier
	if ( $decizie =~ m/<META\sNAME="CREATED"\sCONTENT="(.+)">/ ) {
		my $temporar = $1;
		$decizie =~ s/<lex>\n/<lex>\n<wordchanged id="$temporar" \/>\n/s;
	}
	else {print "ATENTIE: Nu am gasit CHANGED in $cod \n";}
	#Extrag CREATED din fisier
	if ( $decizie =~ m/<META\sNAME="CREATED"\sCONTENT="(.+)">/ ) {
		$temporar = $1;
		$decizie =~ s/<lex>\n/<lex>\n<wordacreated id="$temporar" \/>\n/s;
	}
	else {print "ATENTIE: Nu am gasit CREATED in $cod \n";}
	#Extrag CHANGEDBY din fisier
	if ( $decizie =~ m/<META\sNAME="CHANGEDBY"\sCONTENT="(.+)">/ ) {
		$temporar = $1;
		$decizie =~ s/<lex>\n/<lex>\n<wordchangedby id="$temporar" \/>\n/s;
	}
	else {print "ATENTIE: Nu am gasit CHANGEDBY in $cod \n";}
	#Extrag AUTHOR din fisier
	if ( $decizie =~ m/<META\sNAME="AUTHOR"\sCONTENT="(.+)">/ ) {
		$temporar = $1;
		$decizie =~ s/<lex>\n/<lex>\n<wordauthor id="$temporar" \/>\n/s;
	}
	else {print "ATENTIE: Nu am gasit AUTHOR in $cod \n";}
	#Stergem HEAD-ul din care am scos chestiile utile (AUTHOR; CHANGEDBY, CHANGED, CHANGEDBY)
	$decizie =~ s/<HEAD>(.+)<\/HEAD>\n//s;
	#Introducem numele fisierului (trebuie sa reconvertim in numele initial intai)
	$temporar = $cod;
	$temporar =~ s/D//;
	$temporar =~ s/CC/:/;
	@tempstring = split ( /:/, $temporar);
	$tempstring[1] =~ s/^0//g;
	$temporar = 'Dosar ' . $tempstring[1]. '_' . $tempstring[0];
	$decizie =~ s/<lex>\n/<lex>\n<dosar id="$temporar" \/>\n/s;
	#Identificam numarul deciziei si bagam meta-urile emitent, type, nr
	#Emitent si type sunt un pic redundante, dar daca extind programul la alte chestii...
	if ($decizie =~ m/<P\s(.+)DECIZIA\sNr\.(\d+)<\/B><\/P>/ ) {
		$temporar = $2;
		$decizie =~ s/<lex>\n/<lex>\n<emitent id="CCR" \/>\n<tip id="decizie" \/>\n<nr id="$temporar" \/>\n/s;
	}
	else {print "ATENTIE: Nu am gasit numarul deciziei in $cod \n";}
	#Identificam data deciziei
	#Preluam numarul deciziei cu $temporar, ca sa identificam exact segmentul de text.
	#Avem variabile temporare pentru zi, luna, an
	if ($decizie =~ m/>DECIZIA\sNr\.$temporar<\/B><\/P>\n(.+)<B>din\s(\d+)\s(\w+)\s(\d+)<\/B>/s) {
		my $zi = $2;
		my $lu = $3;
		my $an = $4;
		$decizie =~ s/<nr\sid="$temporar" \/>\n/<nr id="$temporar" \/>\n<date>\n<zi id="$zi" \/>\n<luna id="$lu" \/>\n<an id="$an" \/>\n<\/date>\n/s;
	}
	else {print "ATENTIE: Nu am gasit data deciziei in $cod \n";}
	#Stergem tagurile BODY (ungreedy!)
	$decizie =~ s/\n<BODY(.+?)\n/\n/s;
	$decizie =~ s/\n<\/BODY(.+?)\n/\n/s;
	#Rezolvam titlul
	$decizie =~ s/<P\s(.+?)<B>DECIZIA\sNr\.$temporar<\/B><\/P>/<titlu>\n<numar>DECIZIA Nr\.$temporar<\/numar>/ or print "ATENTIE: Nu am putut prelucra primul rand din titlu la $cod\n";
	$decizie =~ s/<P\s(.+?)<B>din\s(\d+)\s(\w+)\s(\d+)<\/B><\/FONT><\/P>/<data>din $2 $3 $4<\/data>/ or print "ATENTIE: Nu am putut prelucra al doilea rand din titlu la $cod\n";
	$decizie =~ s/<\/data>\n(.+?)referitoare\sla\sexcep(.+?)\n/<\/data>\n<ref>referitoare la excep$2<\/ref>\n/s or print "ATENTIE: Nu am putut prelucra al treilea rand din titlu la $cod \n";
	$decizie =~ s/<\/(.+)<\/ref>/<\/ref>/; #aici elimin niste resturi de taguri de inchidere din randul cu "referitoare la"
	$decizie =~ s/<\/ref>\n(.+?)Publicat(.+?)\n/<\/ref>\n<publ>Publicat$2<\/publ>\n<\/titlu>\n/s or print "ATENTIE: Nu am putut prelucra al patrulea rand din titlu la$cod \n";
	$decizie =~ s/<\/(.+)<\/publ>/<\/publ>/; #aici elimin niste resturi de taguri de inchidere din randul cu "Publicata la"
	#Eliminare junk dintre <titlu></titlu> si tabelul cu judecatorii
	$decizie =~ s/\/titlu>(.+?)<TABLE/\/titlu>\n<TABLE/s or print "ATENTIE: Nu am putut elimina junk intre titlu si tabel la $cod\n";
	#Prelucrare tabel judecatori+procuror+magistrat-asistent
	$decizie =~ s/<\/titlu>\n(.+?)<TR\s/<\/titlu>\n<TR /s or print "ATENTIE: Nu a mers prima etapa din tabel in $cod\n";
	$decizie =~ s/<TR\s(.+?)<TD\s(.+?)<P\s(.+?)<FONT\s(.+?)>(.+?)<\/FONT><\/P>\n<\/TD>\n<TD\s(.+?)<P\s(.+?)<FONT\s(.+?)>(.+?)<\/FONT><\/P>\n<\/TD>\n<\/TR>\n/<membru tip="$9" nume="$5">$5<\/membru>\n/sg or print "ATENTIE: problema majora la tabelul cu judecatorii\n";
	$decizie =~ s/tip=".\s/tip="/sg or print "ATENTIE: Nu am putut elimina liniutele din tabelul cu judecatorii\n"; #eliminam o liniuta in plus
	$decizie =~ s/<\/membru>\n<\/TABLE>\n<\/CENTER>/<\/membru>/s or print "ATENTIE: Nu am putut elimina resturile tabelului cu judecatorii\n"; #eliminam ultimele ramasite ale tabelului
	#Mai scoatem niste formatari inutile
	$decizie =~ s/\sSTYLE=\"margin-bottom:\s0cm;\sline-height:\s100%\"//g or print "ATENTIE: Nu am putut scoate primele formatari inutile in $cod \n";
	$decizie =~ s/\;\smargin-bottom:\s0cm\;\sline-height:\s100\%//g or print "ATENTIE: Nu am putut scoate celelalte formatari inutile in $cod \n";
	#Mai xml-izam niste cod html
	$decizie =~ s/ALIGN=(\w+?)>/align=\"$1\">/g;
	$decizie =~ s/ALIGN=(\w+?)\s/align=\"$1\" /g;
	$decizie =~ s/"JUSTIFY"/"justify"/g;
	$decizie =~ s/"CENTER"/"center"/g;
	$decizie =~ s/\sSTYLE=/ style=/g;
	$decizie =~ s/\n<P\s/\n<p /sg;
	$decizie =~ s/\/P>/\/p>/g;
	#Scoatem fonturile
	$decizie =~ s/<FONT SIZE=\d>//g;
	$decizie =~ s/<\/FONT>//g;
	#Scoatem <BR>
	$decizie =~ s/<BR>//g;
	#Aducem pe acelasi rand <P...>-urile
	$decizie =~ s/\n<p\s([^>]+?)>\n/\n<p $1>/sg or print "ATENTIE: problema la aducerea pe acelasi rand a <P..>-urilor in $cod\n";
	#Avem capat de linie dupa </B>?
	$decizie =~ s/<\/B>\n/<\/B> /sg;
	#Avem capat de linie inainte de </P>?
	$decizie =~ s/\n<\/p>\n/<\/p>\n/sg;
	#Diacritice
	$decizie =~ s/&Icirc\;/Î/g;
	$decizie =~ s/&icirc\;/î/g;
	$decizie =~ s/&acirc\;/â/g;
	$decizie =~ s/&quot\;/\"/g;
	$decizie =~ s/&aacute\;/á/g;
	#Grupare taguri pentru info wor
	$decizie =~ s/<\/date>\n/<\/date>\n<word>\n/;
	$decizie =~ s/\n<titlu>/\n<\/word>\n<titlu>/;
	#Grupare taguri pentru membri
	$decizie =~ s/<\/titlu>\n/<\/titlu>\n<membri>\n/s;
	$decizie =~ s/<\/membru>\n<p/<\/membru>\n<\/membri>\n<p/s;
	#Eliminare paragrafe fara text
	$decizie =~ s/\n<p\s([^>]+?)><\/p>\n/\n/sg or print "ATENTIE: Nu am putut elimina paragrafele fara text in $cod\n";
	#Separare in heading-uri
	$decizie =~ s/\n<p align="center">CURTEA,<\/p>/\n<\/heading>\n<p align="center">CURTEA,<\/p>/sg or print "ATENTIE: Nu am putut inchide headingurile CURTEA in $cod\n";
	$decizie =~ s/<\/membri>\n/<\/membri>\n<heading id="intro">\n/s or print "ATENTIE: Nu am putut deschide heading intro in $cod \n"; #primul heading - intro
	$decizie =~ s/<\/heading>\n<p align="center">CURTEA,<\/p>/<\/heading>\n<heading id="fact">\n<p align="center">CURTEA,<\/p>/s or print "ATENTIE: Nu am putut deschide heading fact din $cod\n"; # al doilea heading - fact
	$decizie =~ s/<\/heading>\n<p align="center">CURTEA,<\/p>/<\/heading>\n<heading id="reason">\n<p align="center">CURTEA,<\/p>/s or print "ATENTIE: Nu am putut deschide heading reason din $cod\n"; # al doilea treilea- reason (e la fel ca inainte, dar nu are modificator de repetare
	$decizie =~ s/<\/lex>/<\/heading>\n<\/lex>/s or print "ATENTIE: Nu am putut inchide al treilea heading din $cod\n"; #daca am ceva cu opinie separata, intercalez mai sus un heading, nu e problema
	$decizie =~ s/\n<p\salign="center">CURTEA\sCONSTITUÞIONALÃ<\/p>/\n<\/heading>\n<heading id="conclusion">\n<p align="center">CURTEA CONSTITUÞIONALÃ<\/p>/s or print "ATENTIE: Nu am putu pune heading conclusion in $cod\n"; #al patrulea heading, concluzia
	#De aici am reluat in 2009!
	#Marcare "pe rol"
	$decizie =~ s/>Pe\srol/ type="rol">Pe rol/ or print "ATENTIE: Nu am gasit paragraful PE ROL";
	#Marcare "apel nominal"
	$decizie =~ s/>La\sapelul\snominal/ type="apel">La apelul nominal/ or print "ATENTIE: Nu am gasit paragraful APEL NOMINAL";
	#Marcare "reprezentant MP"
	$decizie =~ s/>Reprezentantul\sMinisterului\sPublic/ type="repmp">Reprezentantul Ministerului Public/ or print "ATENTIE: Nu am gasit paragraful REP MP";
	#Marcare "parte" --- sper ca e ok, dar daca apare "partile"? daca sunt alte fraze care incep asa? de verificat!
	$decizie =~ s/>Partea/ type="parte">Partea/ or print "ATENTIE: Nu am gasit paragraful PARTEA";
	#Marcare concluzii de respingere MP
	if ($decizie =~ m/type="repmp">(.+)concluzii\sde\srespingere/)
	{$decizie =~ s/<\/word>/<\/word>\n<info>\n<MP opinion="no" \/>\n<\/info>/ or die "MP nu a pus concluzii de respingere in $cod\n";}
	#Identificare MO
	if ($decizie =~ m/<publ>Publicat(.+)nr\.(\d+)\sdin\s(\d+)\.(\d+)\.(\d+)<\/publ>/) {
		my $mo = $2;
		my $zi = $3;
		my $lu = $4;
		my $an = $5;
		$decizie =~ s/<\/date>\n/<\/date>\n<mo>\n<mo_nr id="$mo" \/>\n<mo_zi id="$zi" \/>\n<mo_lu id="$lu" \/>\n<mo_an id="$an" \/>\n<\/mo>\n/ or print "Atentie: Nu a mers ceva cu nr MO\n";}
	#Vedem daca decizia  este de respingere si marcare in <info>
	#ATENTIE: de gasit toate formularile de respingere si acceptare
	if ($decizie =~ m/<heading\sid="conclusion">(.+)>Respinge\sca\sinadmisibil/s) {
	$decizie =~ s/<info>/<info>\n<decision type="no" \/>/;}
	else {print "ATENTIE: decizia $cod nu a fost de respingere sau avem o eroare";}
	###NORMELE CONTESTATE###
	if ($decizie =~ m/<ref>referitoare\sla\s(excep.ia|excep.iile)\sde\sneconstitu.ionalitate\s(a|ale)\s(dispozi.iilor|prevederilor)(.+)<\/ref>/) {
		print "OK, am gasit randul lung cu referinta la actele contestate\n";
		$mo = $4;
		print "$mo\n";} #aici referinta propriu-zisa intra in $mo si avem o formula introductiva lunga, cu dispozitiilor/prevederilor
	elsif ($decizie =~ m/<ref>referitoare\sla\s(excep.ia|excep.iile)\sde\sneconstitu.ionalitate\s(a|ale)\s(.+)<\/ref>/) {
		print "OK, am gasit randul scurt cu referinta la actele contestate\n";
		$mo = $3;
		print "$mo\n";} #aici referinta propriu-zisa intra in $mo si avem o formula introductiva scurta, fara dispozitiilor/prevederilor
		else {die "ATENTIE: nu am gasit referintele la actele contestate!!!\n";}
	#OK, am obtinut in variabila $mo textul in care se afla referintele propriu-zise
	#Exista doua variante: referinta incepe cu articolele sau
	#incepe cu actul, fara a preciza articolele. Uneori, in aceeeasi
	#referinta avem ambele variante. Exista si cazuri atipice, care
	#trebuie identificate cumva, prin avertizarea utilizatorului cand
	#nu se potriveste nici unul din cele anterioare.
	#De asemenea, de obicei avem mai intai articol, pe urma alineat.
	#De testat situatia in care avem intai alineat si pe urma articol!!!
	#Eventual o procedura speciala pentru asta? 
	#Programul ar fi asa:
	#while stringul $mo nu are dimensiune nula
	#	IF incepe cu art (procedura 1)
	#	ELSIF incepe cu tip act (procedura 2)
	#	ELSE eroare DIE
	$length = length($mo);
	print "Lungimea sirului este $length\n";
	while (length($mo) > 0) {
		if ($mo =~ m/^\sart(.+?)/) {
			###########################
			#Aici vine prelucrarea daca incepe cu articol (procedura 1)#
			###########################
			#Separam sirul in partea cu articole si restul:
			if ($mo =~ m/^\sart(.+?)\s(din|al|ale)\s(Leg|Ordon|Hot|Codul|Ordi)(.+)/) {
				#ok, e destul de standard
				print "Ok, actul $cod are referinta standard\n";
				my $articole = 'art'.$1;
				print "Articole: $articole\n";
				#impartim $articole in functie de "art." si bagam intr-un array
				my @art; #array-ul cu articolele
				@art = split (/art\./, $articole);
				my $artn = @art; #lungimea array-ului, precum si nr de linii ale matricii care vine mai jos
				$artn--; #se pare ca este deja alocata valoarea zero din array cu null, iar restul vin incepand cu 1
				#vine un FOR pentru trunchierea restului de text din articole
				for $i (1..$artn) {
					if ($art[$i] =~ m/(.+)(\s)$/) { #scoatem spatiul final
					$art[$i] = $1;}
					if ($art[$i] =~ m/(.+)\s(a|ale)$/) { #scoatem a/ale
					$art[$i] = $1;}
					if ($art[$i] =~ m/(.+),$/) { #scoatem virgula finala
					$art[$i] = $1;}
					if ($art[$i] =~ m/(.+)(\s.i)$/) { #scoatem si-ul final
					$art[$i] = $1;}
					print "$i    Primul element din array: $art[$i]\n";}
				###############
				#Aici trebuie continuata prelucrarea articolelor; de bagat @art intr-o matrice
				###############
				my $rest = $3.$4; #restul de referinta, fara articolel
				print "Rest: $rest\n";
				my @matrice; #pe urma cream o matrice care in prima coloana are nr. articolului, iar apoi alin etc
				for $i (1..$artn) {
					$matrice[$i][1] = $art[$i];
					print "$i Matrice: $matrice[$i][1]\n";}
				for $i (1..$artn) {
					if ($matrice[$i][1] =~ m/(.+?)\s(.+)/) { #cautam daca sunt spatii, ceea ce ar semnala ca sunt alineate etc
						$matrice[$i][2] = $2;
						$matrice[$i][1] = $1; }
					print "Randul $i din matrice contine $matrice[$i][1] ===== $matrice[$i][2]\n";
				}
				#Buun, avem in coloana [1] numarul articolului, iar in coloana [2] avem restul de chestii
				#trebuie sa scoatem cumva si spatiile initiale/finale si punctele aiurea, daca nu le-am scos deja
				#atentie, uneori avem alineatele intre paranteze, iar literele cu paranteza dupa!
				my $max = 2; #numarul maxim de coloane
				my $indicator = 1; #daca devine 1, inseamna ca am creat coloane noi care trebuie prelucrate
				my $diferenta = 0; #contor pentru numarul de randuri adaugate
				#ar trebui sa bag un indicator cu coloana curenta, in loc de [2], ca sa devina reciclabil
				while ($indicator == 1) {
					#incepe FOR
					for $i (1..$artn) {
						undef (@art); #golesc array-ul initial pentru articole ca sa il refolosesc
						if ($matrice[$i][$max-1] =~ m/^(alin|lit|pct)\.(.+)/) {
							#aici trebuie lucrat pentru crearea unei formule generice, cu un WHILE
							$indicator = 1;
							my $subdiv= $1; #aici bagam ce tip de subdiviziune vine
							@art = split (/$subdiv/, $matrice[$i][$max]);
							my $lungart = @art; #aici bagam lungimea noului array 
							$lungart--; #reducem si aici cu 1, ca valoarea [0] e alocata de la inceput cu null
							$matrice[$i][$max-1] = $subdiv;
							$matrice[$i][$max] = $art[1];
							if ($lungart > 1) {
								print "Cream randuri noi in matrice\n";
								for $j (1..$lungart-1) { #aici trebuie generalizat!!!
									for $k (1..$max-1) {
										$matrice[$artn+$j][$k] = $matrice[$i][$k];}
									$matrice[$artn+$j][$max] = $subdiv;
									$matrice[$artn+$j][$max+1] = $art[$j+1];
									$diferenta = $lungart-1;}
							}
							$max++; #am creat o coloana noua, deci creste maxul							
						}
						else {
						$indicator = 0;}
					}
					#Aici se termina FOR
				$artn = $artn+$diferenta;
				#Aici se termina WHILE si matricea ar trebui sa fie gata
				}
				#AICI AR TREBUI SA PRINTEZ UN ARRAY DE TEST
				#
				##############
				#Aici trebuie identificat actul si ciuntit $mo acolo unde se termina
				##############
				}
			else {
				#e nonstandard (norme metodologice, de exemplu)
				print "Atentie, referinta actului in $cod e nonstandard\n";}
			#aici am scos masiv
			}
		elsif ($mo =~ m/^\slegeaETC(.+)/) {
			###########################
			#Aici vine prelucrarea daca NU incepe cu articol (procedura 2)#
			###########################
			print "Incepe cu actul normativ!\n";}
		else {
		print "Atentie!\n"}
	}
	#####################################################
	return $decizie;
}
