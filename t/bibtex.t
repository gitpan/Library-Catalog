# -*- cperl -*-
use Test;
use Library::Catalog::BibTeX;
use Data::Dumper;

BEGIN { plan tests => 4 }

#1# OK if we loaded the module;
ok(1);

#2# Now, create a bib object
$bibobj = Library::Catalog::BibTeX::loadBibTeX("t/bib.in");
ok($bibobj);

#3# A list of the keys with the right size
@keys = $bibobj->getKeys();
ok(scalar @keys, 29);

#4# Get something inexistent
ok(!$bibobj->get("EVIL"));

