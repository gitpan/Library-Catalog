# -*- cperl -*-
use Test;
use Data::Dumper;
use Library::Catalog::XML;

BEGIN { plan tests => 6 }

ok(1);

my $catalog = Library::Catalog::XML->new( {
					   filename => "t/xml.in",
					   entries => "/catalog/entry",
					   html => "/title"
					  });

ok($catalog);
ok($catalog->{filename});
my @es = $catalog->asList();
ok(scalar(@es) == 2);
ok($catalog->asText($es[0]) eq "x1");
ok($catalog->asHTML($es[1]) eq "t1");






