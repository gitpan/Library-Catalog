#
# (C)2001-2002 Projecto Natura
#
package Library::Catalog::XML;
use Library::Catalog;
use XML::XPath;

require v5.6.0;
use strict;
use warnings;

require Exporter;

# Module Stuff
our @ISA = qw/Exporter Library::Catalog/;
our %EXPORT_TAGS = ( all => [ qw// ]);
our @EXPORT_OK = ( @{ $EXPORT_TAGS{all} });
our @EXPORT = qw/ /;

# Version
our $VERSION = '0.01';

# Conf should do something like:
#
# filename: file.xml
# entries: /xml/entry
# html: HTML\
#       TEMPLATE
# latex: LaTeX\
#        TEMPLATE
# ...
sub new {
  my $class = shift;
  my $self = shift;
  return bless $self, $class;
}

sub asList {
  my $self = shift;
  my $xp = XML::XPath->new(filename => $self->{filename});
  my $nodeset = $xp->find($self->{entries});
  my @nodes =  $nodeset->get_nodelist();
  return @nodes;
}

sub asHTML {
  my $self = shift;
  my $entry = shift;
  return "" unless ref($entry) eq "XML::XPath::Node::Element";
  my $xp = XML::XPath->new( context => $entry );
  my $nodeset = $xp->find($self->{html});
  my ($node) =  $nodeset->get_nodelist();
  return $node->string_value();
}



sub asText {
  my $self = shift;
  my $entry = shift;
  return "" unless ref($entry) eq "XML::XPath::Node::Element";
  my $text = $entry->toString();
  $text =~ s/\n/ /g;
  $text =~ s/<[^>]*>//g;
  $text =~ s/\s+/ /g;
  $text =~ s/^\s*//;
  $text =~ s/\s*$//;
  return $text;
}


1;
__END__

=head1 NAME

Library::Catalog::XML - Perl extension for managing XML generic catalogs

=head1 SYNOPSIS

  use Library::Catalog::XML;


=head1 DESCRIPTION


=head1 AUTHOR

Alberto M. B. Simões E<lt>albie@alfarrabio.di.uminho.ptE<gt>

=head1 SEE ALSO

Manpages CGI(3) and perl(1).

=cut
