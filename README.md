linkutils
=========

A set of tools to help in the manipulation of symlinks, using the
`File::Spec` and `Cwd::abs_path` perl modules. They are released under the
MIT licence, see COPYING.

*Warning* Most of these utilities deal only with symlinks, but some
(`mv_and_ln`, `squel`) can also delete more general files on the
filesystem, so use them with care, especially with the `-f` switch!

## `bad_links`

### Description

Print or remove non valid symlinks.

## `abs_to_rel.pl`

### Description

Convert absolute symlinks to relative ones.

## `rel_to_abs.pl`

### Description

Convert relative symlinks to absolute ones.

## `mv_and_ln.pl`

### Description

Move a file around, and put a symlink on the original location to the new
location.

*Example*:
 `mv_and_ln.pl foo bar/` move `foo` in `bar/foo` and makes a symlink
  `foo -> bar/foo`.

## `rel_ln.pl`

### Description

Create a symlink to a file. Contrary to `ln -s`, the symlink is made in such a way that the symlink will point to the file, wherever you put it.

*Example*:
 `rel_ln.pl foo bar/baz` makes a symlink `bar/baz -> ../foo`. The usual way 
 using `ln -s foo bar/baz` makes a symlink `bar/baz -> foo`. So `bar/baz`
 point to the file `bar/foo` which is probably not what was intended.

## `squel.pl`

### Description

Used to manage "packages". A package is a directory containing directory
and files. Installing a package to a directory consist of making symlinks
in this directory to files in the package. I use this to install latex
packages to `~/texmf`, or before switching to [pathogen](https://github.com/tpope/vim-pathogen) to install vim packages in `~/.vim`.

`install_package` and `rm_package` are wrappers around `squel.pl`.
