#!/usr/bin/perl -w
#aici incarc intr-un array fisierele din folder
@a = glob('c:\Users\Filip\Desktop\ReFLOW\1Standardized\*.doc');

#ca sa vad cate fisiere sunt
$length = @a;
print "Avem $length fisiere\n";

#ma misc in folderul respectiv
chdir('c:\Users\Filip\Desktop\ReFLOW\1Standardized') || die "Cannot chdir ($!)";

#ditai for-ul care trece prin fiecare fisier
foreach $x (@a) {
	my $nume1;
	my $nr;
	my $an;
	my $y;
	my $z;
	my $ini;

	# print "Avem fisierul $x \n";
	$ini = $x;
	$x =~ s/\\/:/g;
	$x =~ s/\./:/g;

	# print "Avem fisierul dupa inlocuirea cu puncte $x \n";
	$x =~ s/::/:/;

	# print "Dupa ce scap de doua puncte dublate $x \n";
	@primularr = split( /:/, $x );
	$nume1     = $primularr[6];

	# print "Dupa eliminare extensie $nume1 \n";
	$nume1 =~ s/\s/:/g;
	$nume1 =~ s/_/:/g;

	# print "Dupa eliminare underscore si spatiu $nume1 \n";
	@doileaarr = split( /:/, $nume1 );
	$nr = $doileaarr[1];
	$an = $doileaarr[2];
	print "Dosarul este $nr si anul este $an \n";
	if ( $nr < 10 ) {
		$nr = '000' . $nr || die "Varza la ifuri \n";
	}
	elsif ( $nr < 100 ) {
		$nr = '00' . $nr;
	}
	elsif ( $nr < 1000 ) {
		$nr = '0' . $nr;
	}
	else {

		#print "Ba, ce munciti, ati depasit o mie de hotarari \n";
	}
	$y = "D" . $an . "CC" . $nr;

	#print "Avem acum la final x egal cu $x \n";
	print "Avem acum y egal cu $y \n";
	$x = $ini;

	#print "Avem acum x egal cu $x \n";
	$z = "C:\\USers\\Filip\\Desktop\\ReFLOW\\1Standardized\\$y.doc";

	#print "Avem acum z egal cu $z \n";
	rename( "$x", "$z" ) || die "Nu a mers sa redenumesc fisierul: $!";
}
