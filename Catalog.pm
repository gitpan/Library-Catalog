#
# (C)2001-2002 Projecto Natura
#
package Library::Catalog;

# We need v5.6 for 'our' variables;
require v5.6.0;
use strict;
use warnings;

use Library::MLang;
use DB_File;
use Data::Dumper;
use XML::DT;

require Exporter;

# Module Stuff
our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw() ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw( &catalogNew &catalogLoad);

# Version
our $VERSION = '0.11';

# My language stuff
our $lang;

$INC{'Library/Catalog.pm'} =~ m{\/Catalog\.pm$};
$lang = loadMLangFile("$`/Catalog.lang");
$lang->setLanguage('pt');

sub catalogLanguages {
  return $lang->languages();
}

###

sub catalogSetLanguage {
  $lang->setLanguage(shift);
}

###
# This function receives a filename and optionally an encoding.
# Returns a catalog object and writes the basic skelleton to the
# catalog file.
#
sub catalogNew {
  my $filename = shift;
  my $encoding = shift || "";
  $encoding = " encoding=\"$encoding\"" if ($encoding ne "");

  open CATALOG, ">$filename" or die "Can't open file $filename ($!)";
  print CATALOG "<?xml version=\"1.0\"$encoding?>\n";
  print CATALOG "<catalog>\n</catalog>\n";
  close CATALOG;

  return bless({ filename => $filename });
}

###
# Given a filename, check if it is valid XML. If it is, return a new
# catalog object.
#
sub catalogLoad {
  my ($filename) = @_;
  eval{dt($filename,())};
  die "File $filename is not a valid catalog object ($@)" if $@;
  return bless({ filename => $filename });
}

###
# This method should be called over a catalog object. The first
# argument is the record identifier (like a key), the second is the
# record contents and remaining arguments are an associative array
# that maps relations names to lists of related terms or to a term
# string where terms are separated by semi-colons. Adds the record
# to the catalog cache (does not really save it!)
#
# If the record id already exists, it will be replaced.
#
sub catalogAdd {
  my ($self,$id,$xml,%relations) = @_;
  delete $self->{torem}{$id} if exists($self->{torem}{$id});
  $self->{toadd}{$id}{xml} = $xml;
  if (%relations) {
    for (keys %relations) {
      if (ref($relations{$_}) eq "ARRAY") {
	push @{$self->{toadd}{$id}{rels}{$_}}, @{$relations{$_}};
      } else {
	push @{$self->{toadd}{$id}{rels}{$_}}, split(/\s*;\s*/,$relations{$_});
      }
    }
  } else {
    %{$self->{toadd}{$id}{rels}} = ();
  }
  return $id;
}

###
# Call this method with a list of record identifiers to be removed
# from the catalog.
#
sub catalogRemove {
  my ($self, @records) = @_;
  for (@records) {
    delete ($self->{toadd}{$_}) if defined($self->{toadd}{$_});
    $self->{torem}{$_} = 1;
  }
}

###
# Saves the catalog on disk flushing buffers.
#
sub catalogSave {
  my ($self) = @_;
  $/ = "\n";
  my %cdata = ();
  my %rels = ();

  dt($self->{filename}, ( catalog  => sub { "" },
			  entry    => sub { $cdata{$v{id}}{xml} = $c;
					   %{$cdata{$v{id}}{rels}} = %rels;
					   %rels = (); },
			  rels     => sub { "" },
			  rel      => sub { push @{$rels{$v{type}}}, $c },
			  -default => sub {toxml}
			));

  %cdata = %{ djoin(\%cdata,$self->{toadd}) };

  for (keys %{$self->{torem}}) {
    delete $cdata{$_} if defined($cdata{$_});
  }

  open CAT, $self->{filename} or die ("cannot open catalog file:$!");
  chomp(my $fl = <CAT>);
  close CAT;
  $fl = '<?xml version="1.0"?>' unless ($fl =~ /<\?xml/);

  open CAT, ">$self->{filename}" or die ("Cannot open catalog file for writing: $!");
  print CAT $fl,"\n<catalog>";
  for (keys %cdata) {
    print CAT "\n<entry id=\"$_\">\n";
    print CAT $cdata{$_}{xml};

    if (keys %{$self->{toadd}{$_}{rels}} ) {
      print CAT "\n <rels>";
      for my $k (sort keys %{$self->{toadd}{$_}{rels}}) {
	for my $data (sort @{$self->{toadd}{$_}{rels}{$k}}) {
	  print CAT "\n <rel type=\"$k\">$data</rel>";
	}
      }
      print CAT "\n </rels>";
    }
    print CAT "\n</entry>";
  }
  print CAT "\n</catalog>\n";
  close CAT;
}

###
# Search method. Give an identifier and it will return the XML entry
#
sub catalogId {
  my ($self,$id) = @_;
  if (exists($self->{torem}{$id})) {
    return undef;
  } elsif (exists($self->{toadd}{$id})) {
    my $rels = "";
    my @rs;
    if (@rs = keys %{$self->{toadd}{$id}{rels}}) {
      $rels.="\n <rels>";
      for (@rs) {
	for my $data (@{$self->{toadd}{$id}{rels}{$_}}) {
	  $rels.="\n <rel type=\"$_\">$data</rel>";
	}
      }
      $rels.="\n </rels>\n";
    }
    return $self->{toadd}{$id}{xml}.$rels;
  } else {
    my $r = dt($self->{filename},
	       (
		-default => sub{toxml},
		catalog => sub{$c =~ s/^\s*|\s*$//g; $c},
		entry => sub{ ($v{id} eq $id)?$c:"" },
	       )
	      );
    return $r?$r:undef;
  }
}

# can't remember what this does...
sub djoin {
  my ($a,$b) = @_;
  my $c = $a;
  for my $id (keys %{$b}) {
    if (defined($c->{$id})) {
      if ($b->{$id}{xml}) {
	$c->{$id} = $b->{$id};
      } else {
	for (keys %{$b->{$id}{rels}}) {
	  push @{$c->{$id}{rels}{$_}}, @{$b->{$id}{rels}{$_}};
	}
      }
    } else {
      $c->{$id} = $b->{$id};
    }
  }
  return $c;
}

1;
__END__
=head1 NAME

Library::Catalog - Perl extension for managing XML catalog files

=head1 SYNOPSIS

  use Library::Catalog;

  $catalog = catalogNew("catalogue.xml","ISO-8859-1");

  $catalog = catalogLoad("catalogue.xml");

  $catalog -> catalogAdd("2","<title>Me</title>");

  $catalog -> catalogSave();

  $catalog -> catalogId(4); # will return "<title>They</title>"

  # these two functions handle multi-language support
  @languages = catalogLanguages();

  catalogSetLanguage('pt');

=head1 DESCRIPTION

This module aims to help people who needs to manage a XML catalog.
So, each record is identified by a number-id. The record contents
should be correct XML accordingly with some DTD.

=head2 catalogLanguages

This function returns a list of the valid languages in the current
version.

=head2 catalogSetLanguage

You must supply a valid language code (from the list returned by
catalogLanguages) to change the language used in the forms and
in the interactive shell. By default, it is used portuguese.

=head2 catalogNew

This function is an Catalog Object Constructor. Given a file name it
creates an empty catalog and returns the correspondent object.

If the second argument is present, it is used as a encoding
reference. So, if you use C<catalogNew("c.xml","ISO-8859-1")> command,
the file C<c.xml> will be created with the following contents:

  <?xml version="1.0" encoding="ISO-8859-1"?>
  <catalog>
  </catalog>

=head2 catalogLoad

This is another Catalog Object Constructor. Really, it's an Object
Re-Constructor as it loads a saved Catalog Object. It receives, as
argument the catalog file name.

=head2 catalogAdd

A method to add a record to the catalog. The following arguments are
the record id and the record contents. The record contents should be
valid XML. Meanwhile, there is no need for a root tag, but it can
exists. This XML is not checked, so, be sure it is valid XML. This
method returns the record id.

NOTE: the data is cached but not saved to the file. To have sure it
is, really, saved, call the catalogSave method. If the id already
exists, the contents will be replaced

=head2 catalogSave

This method syncs the catalog to disk. Use this everytime you make a
big amount of changes on the catalog.

=head2 catalogId

Given an identifier, this method returns the corresponding value or
undef if it does not exists.

=head1 AUTHOR

Alberto M. B. Simões <albie@alfarrabio.di.uminho.pt>

=head1 SEE ALSO

Manpages CGI(3) and perl(1).

=cut

