#!/usr/bin/perl
use strict;
use File::Spec;
use Cwd 'abs_path';

sub help { 
  print STDERR <<EOHelp;
  Pour déplacer un fichier vers un autre répertoire et faire un lien
  symbolique dessus.
  Options.
    -v affiche des infos
    -q quiet (défaut)
    -t pour ne pas executer les actions (faire -v pour voir des trucs!)
    -a pour que le ln soit absolu et pas relatif
    -f pour écraser dest au cas où
    -i ne pas écraser dest sauf si c'est un symlink (défaut)
    -ii ne pas écraser dest )
    -n pour traiter un symlink vers un répertoire comme un fichier
EOHelp
};

my $opt_verbose = 0;
my $opt_test = 0;
my $opt_absolute = 0;
my $opt_force = 0;
my $opt_noderefdir = 1;
while ($_ = $ARGV[0], defined($_) && /^-/) {
  shift;
  last if /^--$/;
  if (/^-v/) { $opt_verbose=1;  };
  if (/^-q/) { $opt_verbose=0;  };
  if (/^-t/) { $opt_test=1;  };
  if (/^-a/) { $opt_absolute=1; };
  if (/^-n/) { $opt_noderefdir=0; };
  if (/^-f/) { $opt_force=1; };
  if (/^-i/) { $opt_force=0; };
  if (/^-ii/) { $opt_force=-1; };
  if (/^-h/) { &help(); exit 0 };
}

my $dest=pop(@ARGV);
( undef , my $dir, my $file) = File::Spec->splitpath($dest);
if (-d $dest && ($opt_noderefdir || ! -l $dest)) {
  $dir=$dest;
  $dir = Cwd::abs_path($dir);
}
else {
  $dir = Cwd::abs_path($dir);
  $dest="$dir/$file";
}
my $odest=$dest;

for my $orig (@ARGV) {
  $orig = Cwd::abs_path($orig);
  ( undef , my $dir0, my $file0) = File::Spec->splitpath($orig);
  $dir0 = Cwd::abs_path($dir0);

  my $dest = $odest;
  if (-d $dest && ($opt_noderefdir || ! -l $dest)) {
      $dest="$dest/$file0";
  };

  my $target;
  if ($opt_absolute) {
    $target=Cwd::abs_path($dest);
  }
  else {
    $target=File::Spec->abs2rel($dest,$dir0);
  }
  print "mv $orig $dest ; $orig -> $target\n" if ($opt_verbose);
  if (! -e $dest or $opt_force == 1 or $opt_force > -1 && -l $dest) {
    rename($orig,$dest) or die "Error in mv $orig $dest: $!\n" unless ($opt_test);
    symlink($target,$orig) or warn "Error in ln -s $target $orig: $!\n" unless ($opt_test);
  }
  else {
    warn "File $dest exists\n";
  }
}
