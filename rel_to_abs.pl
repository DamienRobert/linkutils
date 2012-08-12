#!/usr/bin/perl
use strict;
use File::Spec;
use Cwd 'abs_path';

sub help { 
  print STDERR <<EOHelp;
  Pour transformer des liens symboliques relatifs en liens absolus.
  -v: verbose
  -q quiet
  -t: test
  -base: Pour spécifier à partir de quoi prendre le lien, mettre '' pour utiliser cwd.  Utilise rel2abs plutot que abspath, garde les ../

EOHelp
};

my $opt_verbose = 0;
my $opt_test = 0;
my $opt_spec = 0;
my $mybase = '';
while ($_ = $ARGV[0], defined($_) && /^-/) {
  shift;
  last if /^--$/;
  if (/^-v/) { $opt_verbose=1;  };
  if (/^-q/) { $opt_verbose=0;  };
  if (/^-t/) { $opt_test=1;  };
  if (/^-base/) { 
        $opt_spec=1;
        $mybase=shift;  
        $mybase=File::Spec->rel2abs($mybase);
  };
  if (/^-h/) { &help(); exit 0 };
}

my $cwd=Cwd::getcwd();
for my $i (@ARGV) {
  chdir $cwd;
  if (-l $i) {
    ( undef , my $dir, my $file) = File::Spec->splitpath($i);
    chdir $dir;
    my $link=readlink($file);
    if (not File::Spec->file_name_is_absolute($link)) {
      my $newlink=Cwd::abs_path($link);
      if ($opt_spec) {
        $newlink=File::Spec->rel2abs($link,$mybase);
      };
      print "$i -> $newlink\n" if ($opt_verbose);
      unlink($file) or warn "Erreur dans le rm: $!\n"
      unless ($opt_test);
      symlink($newlink, $file) or warn "Erreur dans le ln: $!\n"
      unless ($opt_test);
    }
  }
}

