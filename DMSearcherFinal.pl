#!/usr/bin/perl -w

#===============================================================================================================================#
#Dieses Skript übersetzt ein Pattern aus xy. Datenbank in einen regulären Ausdruck in Perl und sucht damit in einem Proteom nach#
#Domänen. Verwendet wird eine Proteom aus der UniProt Datenbank (Spezies einfügen). Die Ausgabe erfolgt in einer einem          #
#Kalkulationssheet                                                                                                              #
#===============================================================================================================================#
use lib "/home/johausmann/Dokumente/BIDA/STUDIENLEISTUNGBIDA/Excel-Writer-XLSX-0.95/lib";
@Arrayregac =();
  
print "Bitte geben Sie die zu suchende Accessionnumber ein:\n";          #Eingabe Prosite-Accessionnumber 
chomp ($eingabeacn = <>);

print "Bitte geben Sie den Namen der Proteomdatei an:\n";               #Eingabe des Proteoms; 
chomp ($proteomfasta = <>);

print "Bitte geben Sie den Namen der Ausgabedatei an:\n";                      
chomp ($ausgabe = <>);
                                
open FP, "prosite.dat";                                                 #Einlesen der Prosite Datenbank                                   
open FP2, "$proteomfasta" or die "Die Datei kann nicht geöffnet werden";                                              #Einlesen der Genom-Datenbank
use Excel::Writer::XLSX;                                                #Verwenden des Excel-Moduls

@Arrayregac = split '', $eingabeacn;                                    #Eingabe auf ein Array splitten
$newlength = unshift @Arrayregac, "AC   ";                              #ACN in Regex für Perl umwandeln --> AC und drei Leerzeichen
$regac = join '', @Arrayregac;                                          #Zusammensetzen
print "$regac\n";

while (<FP>){                                                           #File Pointer durchläuft Prosite
      if ($_ =~ m/$regac;\n/g){
		  print "Die Accessionnummer wurde gefunden\n";
		    while(<FP>){                                                #innere Schleife --> läuft ab der gefundenen AC Zeile
		      if ($_ =~ m/^PA\s\s\s(.{1,80})\-$/m){                     #Anker Setzung durch \.$ & \-$ --> zwingend letztes Zeichen im Regex.
			      $pattern1 .= $1;}                                     #\-$ --> Speichern der Zeile --> nächste Zeile einlesen und Vergleichen
		      if ($_ =~ m/^PA\s\s\s(.{1,80})\.$/m) {                    #\.$ --> Punkt am Ende deutet auf Ende des Pattern hin 
				  $pattern1 .= $1 ;                                     #        –> Zwischenspeicherung und Sprung aus der Scleife --> da Pattern
			      print"Pattern wurde gefunden\n"; 
			      last;}   
			  if ($_ =~ m/\/\//m){                                      #Sonderfall --> da PA Zeilen >=0 --> Sprung 
				  print "Zu der AC existiert kein Pattern\n";        
				  exit;}  
			}
	   last;
	  }
	  elsif (eof(FP)){ 
		  print "Die Accessionnumber ist nicht vorhanden.\n";
		  exit; 
	  }else {next;}                                                                  #   --> finden der ACN in Prosite und die Ausgabe des dazugehörigen Pattern
	

}
#==========================================================#
#Übersetzen des Pattern in einen regulären Ausdruck in Perl#
#==========================================================#
$pattern1 =~ s/-x-/./g;                                                 #ersetzen von -X- durch einen Punkt
$pattern1 =~ s/-x/./g;                                                  #ersetzen von -x durch einen Punkt
$pattern1 =~ s/-//g;                                                    #Löschen der Bindestriche
$pattern1 =~ s/{/[^/g;                                                  #Geschweifte Klammer wird durch Eckige Klammer mit ^ Zeichen ersetzt
$pattern1 =~ s/}/]/g;                                                   #Geschweifte Klammer wird durch scließende Eckige Klammer ersetzt
$pattern1 =~ s/\(/{/g;                                                  #Klammer wird durch geschweifte Klammer ersetzt
$pattern1 =~ s/\)/}/g;                                                  #                 ""
if ($pattern1 =~ m/(\[.>\])/g){
	$pattver = $1;                                                      #N und C Terminus Sonderfälle -->  ["irgeneinZeichen" ">"] --> sowohl mit als auch ohne Zeichen.
	print "$1\n";                                                       #Zwischenspeichern der Klammern und Substitutionen z.B [G>] --> G?
	$pattern1 =~ s/\[.>\]//d;
	$pattver =~ s/\[//d;
	$pattver =~ s/\]//d;
	$pattver =~ s/>/?/d;
	$pattern1 .= $pattver;}
$pattern1 =~ s/>//d;                                                    #restricted to C-Terminus
$pattern1 =~ s/<//d;                                                    #restricted to N-Terminus 
print "$pattern1\n";
close FP;
#===================================#
#Vorbereitung des Kalkulationssheet.#
#===================================#
$ausgabe .= '.xlsx';
my $workbook = Excel::Writer::XLSX->new( $ausgabe ); 
$worksheet = $workbook->add_worksheet($eingabeacn);
$worksheet->write( 0, 0, "Protein" );
$worksheet->write( 0, 1, "Position" );
$worksheet->write( 0, 2, "Sequence" );
 
#sleep(5);
open FP3, "|figlet Jetzt wird gesucht";                                  #Animation auf der Konsole ––> setzt als Abhängigkeit das Programm Figlet vorraus (in den Paketquellen enthalten)
$/ = ">";
$j = 0;
$i = 0;
$z = 0;
#===================================================#
#Suchen mit Hilfe des REGEX in der Proteom Datenbank#
#===================================================#

while(<FP2>){
	  #print "$_\n";
	  
	$_ =~ m/\|(.{1,10})\|/;                                          #Einlesen mit Hilfe des FP2
	 $ACPROTEIN = $1;                                                #––> Falls eine Accessionnummer vorhanden wird diese in $ACPROTEIN gespeichert
	$_ =~ m/(..\|.{1,10}\|.{1,80} OS=.{1,30} .{1,80}\n)/g;
	 $pos2 = length $1;
	                                                                    #––> Falls ein Matching für ein Pattern gefunden wird
	     $zw = $_; 
	     $zw =~ tr/..\|.{1,10}\|.{1,80} OS=.{1,30} .{1,80}\n//d;
	     print "$zw\n";
	     
	     $zw =~ tr/\n//d;
	     $zw =~ tr/>//d;
	     last;
#	     print "$zw\n"; 

	    while ($zw =~ m/($pattern1)/g){
		
	    $j++;                                                           #|––> dieses und die zuvor gefundene Accessionnummer werden in das Kalkulationssheet geschrieben
	    $worksheet->write ( $j, 2, $1);                                 #––> i und j sind Zählervariablen und dienen zum laufen durch die Tabellen
	    $pos = (pos $zw) - (length $&) + 1;
	    $pos = $pos - $pos2;
	    $z++;
	    $worksheet->write ( $z, 1, $pos);  
		$i++;
		$worksheet->write ( $i, 0, $ACPROTEIN);}
	
    
}

close FP2;
exit;



#==============================#
#erstellt von Johannes Hausmann#
#1. Version des Domänensucchers#
#==============================#
	
	
	
	
	
	

	
	




