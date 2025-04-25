package DivinumOfficium::Globals;

use strict;
use warnings;
use Exporter 'import';

our @EXPORT = qw($error $debug @dayname $votive $commemoration $scriptura $commune $communetype $rank $laudes $vespera
  $cvespera %winner %commemoration %scriptura %commune %winner2 %commemoratio2 %commune2 $rule $communerule $duplex
  $initia $lang1 $lang2 $langfb $dayofweek $border $smallblack $smallfont $blackfont $datafolder $version %setupstring_caches_by_version
  $hora $missa $caller $cwinner %cwinner $ctrank $background $htmlurl $officium $winner $commemoratio $scriptura $commune $commemorated $comrank
  $column %translate $width $dialogfont $rpar @rpar @cm
);

our %EXPORT_TAGS = (all => [@EXPORT]);

#*** common variables arrays and hashes
our $error;
our $debug;

#***common variables arrays and hashes
#filled  getweek()
our @dayname;    #0=Adv|{Nat|Epi|Quadp|Quad|Pass|Pent 1=winner|2=commemoratio/scriptura

our $votive;

our $officium;

#filled by occurence()
our $winner;          #the folder/filename for the winner of precedence
our $commemoratio;    #the folder/filename for the commemorated
our $scriptura;       #the folder/filename for the scripture reading (if winner is sancti)
our $commune;         #the folder/filename for the used commune
our $communetype;     #ex|vide
our $rank;            #the rank of the winner
our $laudes;          #1 or 2
our $vespera;         #1 | 3 index for ant, versum, oratio
our $cvespera;        #for commemoratio
our $commemorated;    #name of the commemorated for vigils
our $comrank;         #rank of the commemorated office

#filled by precedence()
our %winner;                                  #the hash of the winner
our %commemoratio;                            #the hash of the commemorated
our %scriptura;                               #the hash for the scriptura
our %commune;                                 # the hash of the commune
our (%winner2, %commemoratio2, %commune2);    #same for 2nd column
our $rule;                                    # $winner{Rank}
our $communerule;                             # $commune{Rank}
our $duplex;                                  #1= simplex 2=semiduplex, 3=duplex 0=rest

#4 = duplex majus, 5=duplex II class 6=duplex I class 7=higher
our $initia;
our $lang1;
our $lang2;
our $langfb = '';
our $column;
our $dayofweek;

our $border;
our $smallblack;
our $smallfont;
our $blackfont;
our $background;

our $datafolder;
our $htmlurl;

our $version;
our %setupstring_caches_by_version;

our $hora;
our $missa;
our $caller;

our $cwinner;
our %cwinner;
our $ctrank;

our %translate;    #translation of the skeleton label for 2nd language

our $width;
our $dialogfont;
our $rpar;
our @rpar;
our @cm;
1;
