#!/usr/bin/perl
use strict;
use File::Spec;
use Cwd 'abs_path';

sub help { 
  print STDERR <<EOHelp;
  Pour faire des actions qui respectent le squelette des dossiers:
  squel.pl -ln ploum/plim/plam foo fait que
  foo/ploum/plim/plam -> ploum/plim/plam
  Options.
    -v affiche des infos
    -vv affiche encore plus d'infos
    -q quiet
    -t pour ne pas executer les actions (faire -v pour voir des trucs!)
    -a pour que le ln soit absolu et pas relatif
    -abs pour utiliser Cwd::abs_path (aplanir les ../, suit les symlinks)
    -squel: pour préciser le squelette 
    -mv: pour déplacer
    -cp: pour copier
    -ln: pour lien symbolique
    -hln: pour hard link
    -mvln: pour déplacer puis faire un lien symbolique vers le rep d'origine
    -f pour écraser dest au cas où
    -i ne pas écraser dest sauf si c'est un symlink (défaut)
    -ii ne pas écraser dest )
EOHelp
};

my $opt_verbose = 0;
my $opt_test = 0;
my $squel="";
my $opt_absolute = 0;
my $opt_abspath = 0;
my $opt_remove=0;
my $opt_copy=0; 
my $opt_recursive=0; 
my $opt_link=0;
my $opt_hardlink=0;
my $opt_move=0;
my $opt_moveandln=0;
my $opt_force = 0;
while ($_ = $ARGV[0], defined($_) && /^-/) {
  shift;
  last if /^--$/;
  if (/^-v/) { $opt_verbose=1;  };
  if (/^-vv/) { $opt_verbose=2;  };
  if (/^-q/) { $opt_verbose=0;  };
  if (/^-t/) { $opt_test=1;  };
  if (/^-squel/) { $squel=shift;  };
  if (/^-a/) { $opt_absolute=1; };
  if (/^-abs/) { $opt_abspath=0; };
  if (/^-rm/) { $opt_remove=1; };
  if (/^-cp/) { $opt_copy=1; };
  if (/^-ln/) { $opt_link=1; };
  if (/^-mv/) { $opt_move=1; };
  if (/^-mvln/) { $opt_moveandln=1; };
  if (/^-f/) { $opt_force=1; };
  if (/^-i/) { $opt_force=0; };
  if (/^-ii/) { $opt_force=-1; };
  if (/^-r/) { $opt_recursive=1; };
  if (/^-h/) { &help(); exit 0 };
}
my $cpoptions; my $rmoptions;
$opt_force == 1 and $cpoptions="-f";
$opt_force == 0 and $cpoptions="-i";
$opt_force == -1 and $cpoptions="-n";
if ($opt_recursive) {
  $cpoptions="${cpoptions}r";
  $opt_force == 1 and $rmoptions="-rf";
  $opt_force == 0 and $rmoptions="-r";
  $opt_force == -1 and $rmoptions="-ri";
}

my $orig_dest=pop(@ARGV);
die "$orig_dest should be a directory" if ( ! -d $orig_dest);
if ($opt_abspath) 
{
  $orig_dest=Cwd::abs_path($orig_dest);
  $squel=Cwd::abs_path($squel);
}
else
{
  $orig_dest=File::Spec->rel2abs($orig_dest);
  $squel=File::Spec->rel2abs($squel);
}

for my $i (@ARGV) {
  $i=Cwd::cwd() if $i eq '.' ;
  my $absi;
  if ($opt_abspath) 
  {
    $absi=Cwd::abs_path($i);
  }
  else
  {
    $absi=File::Spec->rel2abs($i);
  }
  
  my $dest=$orig_dest;
  ( undef , my $dir, my $file) = File::Spec->splitpath($absi);
  my $rac;
  $rac=$dir;
  $rac=~s/^$squel//;
  print "i: $i, dest: $dest, rac: $rac, squel: $squel\n" if ($opt_verbose ge 2);

  $dest="$dest/$rac";
  my $destf="$dest/$file";

  if ($opt_remove && -e $destf) {
    if ($opt_recursive && -d $destf) {
      print "rm $rmoptions $destf" if ($opt_verbose);
      system("rm", $rmoptions, $destf) or warn "Error in rm -rf $destf: $!\n" unless ($opt_test);
    }
    else {
      if ($opt_force == 1 or $opt_force > -1 && -l $dest) {
        print "rm $destf\n" if ($opt_verbose);
        unlink($destf) or warn "Error in rm $destf: $!\n" unless ($opt_test);
      }
      else {
        print "Not removing $destf\n" if ($opt_verbose);
      }
    }
  };
  if ($opt_remove && ! -e $destf) {
    print "$destf does not exist (probably a bad symlink), removing\n" if ($opt_verbose);
    unlink($destf) or warn "Error in rm $destf: $!\n" unless ($opt_test);
  }

  if (! -e $dest ) {
    print "mkdir -p $dest\n" if ($opt_verbose);
    system("mkdir","-p",$dest) unless ($opt_test);
  }
  if (! -d $dest ) {
    warn "$dest should be a directory\n" unless ($opt_test);
    next;
  }

  if ($opt_copy) {
      print "cp $cpoptions $i $destf\n" if ($opt_verbose);
      system("cp",$cpoptions,$i,$destf)==0 or warn "Error in cp $i $destf: $!\n" unless ($opt_test);
  };

  if ($opt_move or $opt_moveandln) {
    if (! -e $destf or $opt_force == 1 or $opt_force > -1 && -l $dest) {
      print "mv $i $destf\n" if ($opt_verbose);
      rename($i,$destf) or warn "Error in mv $i $destf: $!\n" unless ($opt_test);
    }
    else {
      warn "File $dest exists\n";
      next;
    }
  };

  if ($opt_hardlink || $opt_link ) {
    if (-e $destf) {
      if ($opt_force == 1 or $opt_force > -1 && -l $destf) {
            print "removing $destf\n" if ($opt_verbose);
            unlink($destf) or die "Error in rm $dest: $!\n" unless ($opt_test);
      }
      else {
        warn "File $destf exists\n";
        next;
      }
    }
    else {
      print "$destf does not exist (probably a bad symlink), removing\n" if ($opt_verbose);
      unlink($destf) or warn "Error in rm $destf: $!\n" unless ($opt_test);
    }
  }
  if ($opt_hardlink) {
    print "ln $i $destf\n" if ($opt_verbose);
    link($i,$destf) or warn "Error in ln $i $destf: $!\n" unless ($opt_test);
  };

  if ($opt_link) {
    my $target="$dir/$file";
    $target=File::Spec->abs2rel($target,$dest) unless ($opt_absolute);
    print "ln -s $target $destf\n" if ($opt_verbose);
    symlink($target,$destf) or warn "Error in ln -s $target $destf: $!\n" unless ($opt_test);
  };

  if ($opt_moveandln) {
    my $target="$destf";
    $target=File::Spec->abs2rel($target,$dir) unless ($opt_absolute);
    print "ln -s $target $dir/$file\n" if ($opt_verbose);
    symlink($target,"$dir/$file") or warn "Error in ln -s $target $dir/$file: $!\n" unless ($opt_test);
  }
}
