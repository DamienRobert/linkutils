#!/usr/bin/perl
use strict;
use File::Spec;
use Cwd 'abs_path';

sub help { 
  print STDERR <<EOHelp;
  Pour transformer des liens symboliques absolus en liens relatifs.
  -v: verbose
  -q quiet
  -t: test
  -base: pour spécifier à partir de quoi prendre le lien
  relatif plutot que cwd
EOHelp
};

my $opt_verbose = 0;
my $opt_test = 0;
my $opt_cwd = 0;
my $opt_base = "";
while ($_ = $ARGV[0], defined($_) && /^-/) {
  shift;
  last if /^--$/;
  if (/^-v/) { $opt_verbose=1;  };
  if (/^-q/) { $opt_verbose=0;  };
  if (/^-t/) { $opt_test=1;  };
  if (/^-base/) { $opt_base=shift;  
        $opt_base=File::Spec->rel2abs($opt_base);
  };
  if (/^-h/) { &help(); exit 0 };
}

my $cwd=Cwd::getcwd();
for my $i (@ARGV) {
  chdir $cwd;
  if (-l $i) {
    my $link=readlink($i);
    if (File::Spec->file_name_is_absolute($link)) {
      ( undef , my $dir, my $file) = File::Spec->splitpath($i);
      print "cd $dir\n" if ($opt_verbose);
      chdir $dir;
      my $newlink=File::Spec->abs2rel($link,$opt_base);
      print "$i -> $newlink\n" if ($opt_verbose);
      unlink($file) or warn "Erreur dans le rm: $!\n"
      unless ($opt_test);
      symlink($newlink, $file) or warn "Erreur dans le ln: $!\n"
      unless ($opt_test);
    }
  }
}
