package Library::Catalog::BibTeX;
use Text::BibTeX;

use v5.6.0;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter Library::Catalog);
our %EXPORT_TAGS = ( 'all' => [ qw( ) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw( loadBibTeX );

our $VERSION = '0.01';

sub loadBibTeX {
  my $filename = shift;
  my $bibfile = Text::BibTeX::File->new($filename);
  return bless( +{ filename => $filename,
		   bibfile => $bibfile } );
}

sub asList {
  my $self = shift;
  return $self->getArray();
}

sub getArray {
  my $self = shift;
  my @keys = getKeys($self);
  my $key;
  my @out = ();
  for $key (@keys) {
    my %o = get($self,$key);
    $o{key} = $key;
    push @out, \%o;
  }
  return @out;
}

sub tex2html {
  my $latex = shift;
  return "" unless defined($latex);

  for ($latex) {
    s/\\textit\{([^{]+)\}/<i>$1<\/i>/g;
    s/\\textbf\{([^{]+)\}/<b>$1<\/b>/g;
    s/\\texttt\{([^{]+)\}/<tt>$1<\/tt>/g;
    s/\\emph{([^{]+)}/<i>$1<\/i>/g;
    s/\\item\b/<li>/g;
    s/\\_/_/g;
    s/\\mbox{([^}]+)}/$1/g;
    s/{\\it\s([^}]+)}/<i>$1<\/i>/g;
    s/\\LaTeX/LaTeX/g;
    s/\\begin{itemize}/<ul>/g;
    s/\\begin{quote}/<blockquote><i>/g;
    s/\\end{quote}/<\/i><\/blockquote>/g;
    s/\\end{itemize}/<\/ul>/g;
    s/[}{]//g;
  }

  return $latex;
}

sub asHTML {
  my $self = shift;
  my $entry = shift;
  return $self->toEntry($entry);
}

sub toEntry {
  my $self = shift;
  my $entry = shift;

  my $title = tex2html($entry->{title});
  my $url = (exists($entry->{url}))?$entry->{url}:"";
  my $body = tex2html($entry->{abstract})."<br><i>".tex2html($entry->{author})."</i>";

  return ($title,$body,$url);
}

sub toHtml {
  my @data = toEntry(@_);
  my ($title,$body,$url) = @data;
  if (defined($url) && $url ne "") {
    return "<h3><a href=\"$url\">$title</a></h3><blockquote>$body</blockquote>";
  } else {
    return "<h3>$title</h3><blockquote>$body</blockquote>";
  }
}


sub Keywords {
  my ($self,$entry) = @_;
  my @keys = defined($entry->{keyword})?(split /\s*,\s*/,$entry->{keyword}):($entry->{key}, $entry->{title}, $entry->{author});
  return @keys;
}

sub toText {
  my $self = shift;
  my $entry = shift;
  my $text = "";
  foreach my $field (keys %$entry) {
    $text.=$entry->{$field};
  }
  $text=~ s/\n/ /g;
  return $text;
}

sub getKeys {
  my $self = shift;
  my @list = ();
  while (my $entry = Text::BibTeX::Entry->new($self->{bibfile})) {
    next unless $entry->parse_ok;
    push @list, $entry->key;
  }
  $self->{bibfile} = Text::BibTeX::File->new($self->{filename});
  return @list;
}

sub get {
  my $self = shift;
  my $key = shift;
  my %result = ();
  while (my $entry = Text::BibTeX::Entry->new($self->{bibfile})) {
    next unless $entry->parse_ok;
    if ($entry->key eq $key) {
      my %r = ();
      my @ks = $entry->fieldlist;
      for (@ks) {
	$r{$_} = $entry->get($_);
      }
      %result = %r;
    }
  }
  $self->{bibfile} = Text::BibTeX::File->new($self->{filename});
  return %result;
}


1;
__END__
=head1 NAME

Library::Catalog::BibTeX - Perl extension for managing BibTeX files as a Catalog

=head1 SYNOPSIS

  use Library::Catalog::BibTeX;

=head1 DESCRIPTION


=head1 AUTHOR

Alberto M. B. Simões <albie@alfarrabio.di.uminho.pt>

=head1 SEE ALSO

Manpages Library::Catalog(3), Library::Simple(3) and perl(1).

=cut

