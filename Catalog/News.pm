#
# (C)2001-2002 Projecto Natura
#
package Library::Catalog::News;
use Library::Catalog;
use CGI qw/:standard/;

use XML::DT ;

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
our $VERSION = '0.02';

our @REQ_FIELDS = ( qw/date title/ );
our @KNOWN_FIELDS = ( @REQ_FIELDS,
		      qw/time url description author/ );

# First argument is a reference to the list of items we want on the
# catalog of news.
sub new {
  my $class = shift;
  my $fields = shift;
  my %tmp = ();
  @tmp{@$fields} = @$fields;
  my $self = { FIELDS => \%tmp };

  for (@REQ_FIELDS) {
    $self->{FIELDS}{$_} = $_;
  }

  return bless $self, $class;
}

sub simple_attr {
  my $record = shift;
  my $key = shift;
  if (exists($record->{$key})) {
    if ($key eq "time") {
      return sprintf("%d:%02d", $record->{time}{hour},$record->{time}{minutes});
    } elsif ($key eq "date") {
      return sprintf("%d-%02d-%02d", $record->{date}{year},$record->{date}{month},$record->{date}{day});
    } else {
      return $record->{$key}
    }
  } else {
    return "";
  }
}


sub asHTML {
  my $record = shift;
  return apply_template($record, def_template($record));
}

sub asText {
  my $record = shift;
  my $answer = "";
  for (keys %$record) {
    next if ref($_);
    $answer.=$_;
  }
  return $answer;
}

sub asRelations {
  my $record = shift;
  return ();
}

# This works for _ALL_ records...
sub as_HTML {
  my $self = shift;
  my $count = shift || -1; ## Here we really mean || (not // on perl 6)
  my $template = shift;

  my $ssub;

  if (exists($self->{time})) {
    $ssub = sub {
	my $sb = sprintf("%d%2d%2d%2d%2d",
			 $b->{date}{year},$b->{date}{month},$b->{date}{day},
			 $b->{time}{hour},$b->{time}{minutes});
	my $sa = sprintf("%d%2d%2d%2d%2d",
			 $a->{date}{year},$a->{date}{month},$a->{date}{day},
			 $a->{time}{hour},$a->{time}{minutes});
	$sb =~ s/\s/0/g;
	$sa =~ s/\s/0/g;
	$sb <=> $sa
      }
  } else {
    $ssub = sub {
	my $sb = sprintf("%d%2d%2d",
			 $b->{date}{year},$b->{date}{month},$b->{date}{day});
	my $sa = sprintf("%d%2d%2d",
			 $a->{date}{year},$a->{date}{month},$a->{date}{day});
	$sb =~ s/\s/0/g;
	$sa =~ s/\s/0/g;
	$sb <=> $sa
      }
  }

  # we ensure all records are equal, so... :)
  $template = def_template($self->{DATA}[0]) unless defined $template;

  my $HTML = "\n";
  for my $new ( sort $ssub @{$self->{DATA}}) {
    last unless $count;
    $count--;
    $HTML .= apply_template($new, $template);
  }

#  if (exists($self->{ENCODING})) {
#    return lat1::utf8($HTML);
#  } else {
    return $HTML;
#  }
}

sub apply_template {
  my ($record, $template) = @_;

  my $tmp = $template;
  while ($template =~ m!\[([A-Z]+)(\.([A-Z]+))?\]!g) {
    my $name = $1;
    if ($2) {
      my $name2 = $3;
      $tmp =~ s/\[$name\.$name2\]/$record->{lc($name)}{lc($name2)} || ""/e;
    } else {
      $tmp =~ s/\[$name\]/simple_attr($record,lc($name))/e;
    }
  }
  return $tmp;
}

sub def_template {
  my $record = shift;
  my $tmpl = "";
  my $author = "";

  $author = "<span style=\"font-size: small\">([AUTHOR])</span> - " if exists $record->{author};
  my $title = "$author";

  if (exists($record->{url})) {
    $title.= "<a href=\"[URL]\">[TITLE]</a></b>";
  } else {
    $title.= "[TITLE]</b>";
  }
  if (exists($record->{time})) {
    $title = "<b><tt>[DATE] [TIME]</tt> - $title";
  } else {
    $title = "<b><tt>[DATE]</tt> - $title";
  }
  if (exists($record->{description})) {
    return "$title <blockquote>[DESCRIPTION]</blockquote>\n";
  } else {
    return $title;
  }
}

sub load {
  my $class = shift;
  my $filename = shift;

  my %handler=(
	       '-default' => sub { $c },
	       '-type' => {
			   fields => 'SEQ',
			   date => 'MAP',
			   data => 'SEQ',
			   time => 'MAP',
			   new => 'MAP',
			   news => 'MAP',
			   meta => 'MAP',
			  },
	       'news' => sub{
		 $c->{ENCODING} = $c->{meta}{encoding} if exists($c->{meta}{encoding});
		 $c->{DATA} = $c->{data};
		 delete($c->{data});
		 $c->{FIELDS} = $c->{meta}{fields};
		 delete($c->{meta}{fields});
		 delete($c->{meta});
		 return $c;
	       },
	       'fields' => sub{ my %h = ();
			   @h{@$c}=@$c; return \%h },
	      );
  return bless(dt($filename,%handler),$class);
}

sub asList {
  my $self = shift;
  return @{$self->{DATA}};
}

# Save to an XML file.
sub save {
  my $self = shift;
  my $filename = shift;
  open XML, ">$filename" or die "Cannot open file $filename: $!";

  ## Print <?xml version="1.0" encoding="..."?>
  print XML "<?xml version=\"1.0\"";
  print XML " encoding=\"$self->{ENCODING}\"" if exists $self->{ENCODING};
  print XML "?>\n";

  print XML "<news>\n";
  ## Now, print info
  print XML " <meta>\n";
  print XML "  <encoding>$self->{ENCODING}</encoding>\n" if exists $self->{ENCODING};
  print XML "  <fields>\n";
  for (sort keys %{$self->{FIELDS}}) {
    print XML "   <field>$_</field>\n";
  }
  print XML "  </fields>\n";
  print XML " </meta>\n";


  ## Aux function for recursive dump.
  sub dump_data {
    my ($spaces, $tag, $hash) = @_;
    print XML "$spaces<$tag>\n";
    for my $k (sort keys %$hash) {
      if (ref($hash->{$k}) eq "HASH") {
	dump_data(" ".$spaces, $k, $hash->{$k});
      } else {
	print XML " $spaces<$k>$hash->{$k}</$k>\n";
      }
    }
    print XML "$spaces</$tag>\n";
  }

  print XML " <data>\n";
  for (@{$self->{DATA}}) {
    dump_data('  ','new', $_);
  }
  print XML " </data>\n";
  print XML "</news>\n";
  close XML;
}


# add records. Each record is a map from keywords to respective
# data. If any required field is missing, that record is not added.
sub add {
  my $self = shift;
  RECORD: for my $record (@_) {
    # Check if it is an hash reference
    next unless ref $record eq "HASH";

    # Treat TIME
    if (exists($self->{FIELDS}{time})) {
      if (exists($record->{time})) {
	$record->{time} = make_time($record->{time})
      } else {
	$record->{time} = today_time()
      }
    }

    # Treat DATE
    if (exists($record->{date})) {
      $record->{date} = make_date($record->{date})
    } else {
      $record->{date} = today_date();
    }

    # Check REQUIRED FIELDS
    for (@REQ_FIELDS) {
      next RECORD unless exists($record->{$_});
    }

    # Remove unwanted fields
    for (keys %{$record}) {
      delete $record->{$_} unless exists $self->{FIELDS}{$_};
    }

    # Add undefined fields
    for (keys %{$self->{FIELDS}}) {
      $record->{$_} = " " unless exists $record->{$_};
    }

    push @{$self->{DATA}}, $record;
  }
}


sub make_time {
  my $time = shift;
  my $new = {};
  if ($time =~ m!^(\d?\d):?(\d\d)$!) {
    $new -> {hour} = $1;
    $new -> {minutes} = $2;
  } else {
    $new = today_time();
  }
  return $new;
}

sub make_date {
  my $date = shift;
  my $new = {};
  if ($date =~ m!^(\d\d\d\d)[-./]?(\d\d)[-./]?(\d\d)$!) {
    $new->{day} = $3;
    $new->{month} = $2;
    $new->{year} = $1;
  } elsif ($date =~ m!^(\d\d)[-./](\d\d)[-./](\d\d\d\d)$!) {
    $new->{day} = $1;
    $new->{month} = $2;
    $new->{year} = $3;
  } else {
    $new = today_date();
  }
  return $new;
}

sub today_date {
  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday) = localtime(time);
  return {
	  day => $mday,
	  month => $mon+1,
	  year => $year+1900
	 };
}

sub today_time {
  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday) = localtime(time);
  return {
	  hour => $hour,
	  minutes => $min,
	 };
}

sub add_as_HTML {
  my $self = shift;
  my $parms = shift;
  my $conf = shift;
  my $HTML = "";

  if (exists($parms->{date})) {
    if (exists($conf->{authfile})) {
      my $username;
      my $password;
      if (exists($self->{FIELDS}{author})) {
	$username = $parms->{author};
      } else {
	$username = $parms->{username};
      }
      $password = $parms->{passwd};
      unless ( open X, "<$conf->{authfile}" ) {
		print "Cannot open passwd file";
		exit;
	  }
    while(<X>) {
	chomp;
	m!^(\S+)\s+(\S+)$!;
	my ($u,$p) = ($1,$2);
	if ($u eq $username) {
	  if (crypt($password, $p) eq $p) {
	    $self->add($parms);
	    $self->save($conf->{outfile} || "novidades.xml");
	    $HTML .= "New added!";
	    last;
	  }
	}
      }
      if ($HTML eq "") {
	$HTML .= "Authorization failed";
      }
    } else {
      $self->add($parms);
      $self->save($conf->{outfile} || "novidades.xml");
      $HTML .= "New added!";
    }
  } else {
    my $date = today_date;
    $date = "$date->{year}-$date->{month}-$date->{day}";
    my $time = today_time;
    $time = "$time->{hour}:$time->{minutes}";

    $HTML.= start_multipart_form();

    $HTML.= " <fieldset>\n  <legend>Date</legend>\n";
    $HTML.= " <input name=\"date\" value=\"$date\" type=\"hidden\"/>\n";
    $HTML.= "$date\n </fieldset>\n";

    if ($self->{FIELDS}{time}) {
      $HTML.= " <fieldset>\n  <legend>Time</legend>\n";
      $HTML.= " <input name=\"time\" value=\"$time\" type=\"hidden\"/>\n";
      $HTML.= "$time\n </fieldset>\n";
    }

    $HTML.= " <fieldset>\n  <legend>Title</legend>\n";
    $HTML.= "  <input name=\"title\" size=\"50\"/>\n";
    $HTML.= " </fieldset>\n";

    for (keys %{$self->{FIELDS}}) {
      next if $_ eq "time" or $_ eq "date" or $_ eq "title";

      $HTML.= " <fieldset>\n  <legend>".ucfirst($_)."</legend>\n";
      if ($_ eq "description") {
	$HTML.= "  <textarea name=\"$_\" rows=\"5\" cols=\"50\"></textarea>\n";
      } else {
	$HTML.= "  <input name=\"$_\" size=\"50\"/>\n";
      }
      $HTML.= " </fieldset>\n";
    }

    if (exists($conf->{authfile})) {
      unless (exists($self->{FIELDS}{author})) {
	$HTML.= " <fieldset>\n  <legend>Username</legend>\n";
	$HTML.= "  <input name=\"username\" size=\"50\"/>\n";
	$HTML.= " </fieldset>\n";
      }
      $HTML.= " <fieldset>\n  <legend>Password</legend>\n";
      $HTML.= "  <input name=\"passwd\" size=\"50\" type=\"password\"/>\n";
      $HTML.= " </fieldset>\n";
    }

    $HTML.=" <input type=\"submit\" value=\"Adicionar\"/>\n";
    $HTML.="</form>\n";
  }
  return $HTML;
}

1;
__END__

=head1 NAME

Library::Catalog::News - Perl extension for managing XML News as a catalog

=head1 SYNOPSIS

  use Library::Catalog::News;

  $new_cat = Library::Catalog::News->new([ qw/author title date time/ ]);

  $new_cat->add( { title => "title" }, { title => "title2" } );

  $new_cat->save( $filename );

  $other_cat = Library::Catalog::News->load( $filename );

  $other_cat->as_HTML( $count, $template );

  @records = $other_cat->asList();

=head1 DESCRIPTION

This module creates an XML file of news. This file will be handled as
a catalog as described by Library::Catalog. The news file is a set of
records. Each record consists of some data fields. This module assumes
some fields as possible fields. Some are required and some are
optional, and can be defined in the constructor in any order you would
like.

=head2 Fields

Valid fields in the news file are:

=over 4

=item C<date>

As any new you can imagine, there is necessary a date. This date
consists of a day, month and year. It is B<REQUIRED>.

=item C<time>

On some cases, there are many news each day. This can cause confusion,
so the module makes it possible to define an hour:minute pair for each
new. It is B<OPTIONAL>.

=item C<title>

Normally a new consists of something more than a date and a
description. It contains, specially, a title to resume all the new
text. It is B<REQUIRED>.

=item C<url>

There can be an C<url> to point to a special address where the new is
more described, or the address for the new object in cause. It is
B<OPTIONAL>.

=item C<description>

This is a core of the new. A small text describing the new. For a
question of flexibility we support some XHTML tags on this field, but
we really discourage using more than simple bold and italic ones. It
is B<OPTIONAL>.

=item C<author>

In some situations it could be usefull to associate a user to each new
posted. Use this to make the trick. It is B<OPTIONAL>.

=back

=head1 AUTHOR

Alberto M. B. Simões E<lt>albie@alfarrabio.di.uminho.ptE<gt>

=head1 SEE ALSO

Manpages CGI(3) and perl(1).

=cut
