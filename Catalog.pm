#
# (C)2001-2002 Projecto Natura
#
package Library::Catalog;

# We need v5.6 for 'our' variables;
require v5.6.0;
use strict;
use warnings;

use DB_File;
use Data::Dumper;
use XML::DT;

require Exporter;

# Module Stuff
our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw() ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw( );

# Version
our $VERSION = '0.12';

## 1: catalog ---> entry*
## 2: entry -----> text
## 3: entry -----> HTML
## 4: entry -----> LaTeX
## 5: entry -----> rel*


## Every sub-module should declare functions to:
sub asList {
  my $self = shift;
  ## Return the list of elements;
  return ();
}


1;
__END__
=head1 NAME

Library::Catalog - Perl extension for managing XML catalog files

=head1 SYNOPSIS

  use Library::Catalog;

=head1 DESCRIPTION

Super-class for catalog perl classes.

All Catalog perl classes should implement (some can be omitted):

  $catObj = new($class,$filename)

  $catObj->asList()

  $catObj->asText($entry)

  $catObj->asHTML($entry)

  $catObj->asLaTeX($entry)

  $catObj->asRelations($entry)

  $catObj->asIdentifier($entry)



=head1 AUTHOR

Alberto M. B. Simões <albie@alfarrabio.di.uminho.pt>

=head1 SEE ALSO

Manpages CGI(3) and perl(1).

=cut

