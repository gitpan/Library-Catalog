# -*- cperl -*-
use Test;
use Data::Dumper;
use Library::Catalog;

BEGIN { plan tests => 8 }


# 1 #
my $cat = catalogNew("/tmp/_${$}_");
if ($cat) {
  ok(1);
} else {
  ok(0);
}

# 2 #
$cat->catalogAdd(1,"<title>Me</title>","IOF","Test");
ok(defined($cat->{toadd}{1}{rels}{IOF}));

# 3 #
$cat->catalogSave();

undef($/);
if (open F, "/tmp/_${$}_") {
  my $t = <F>;
  close F;

  open R, "t/out3";
  my $res = <R>;
  close R;

  ok($t,$res);
} else {
  ok(0);
}

# 4 #
$xml = $cat->catalogId(1);
$out =<<'E';
<title>Me</title>
 <rels>
 <rel type="IOF">Test</rel>
 </rels>
E

ok($xml,$out);

# 5 #
my $cat1 = catalogLoad("/tmp/_${$}_");
$xml = $cat1->catalogId(1);
$xml.="\n" unless $xml=~/\n$/;
ok($xml,$out);

# 6 #
$cat1->catalogRemove(1);
ok(not defined $cat1->{toadd}{1});

# 7 #
$cat1->catalogAdd(2,"<title>Another</title>",("IOF","cat;dog","POF",['test','catalog']));
$cat1->catalogSave;

undef($/);
if (open F, "/tmp/_${$}_") {
  my $t = <F>;
  close F;

  open R, "t/out4";
  my $res = <R>;
  close R;

  ok($t,$res);
} else {
  ok(0);
}

# 8 #
$cat1->catalogAdd(2,"text");
ok( not keys %{ $cat1->{toadd}{2}{rels}});

#unlink("/tmp/_${$}_");

