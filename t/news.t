# -*- cperl -*-
use Test;
use Data::Dumper;
use Library::Catalog::News;

BEGIN { plan tests => 35 }

# Creating an object without 'title' or 'date' must have them there
# (they are required)
my $obj = Library::Catalog::News->new([qw/title/]);
# 1
if ($obj) { ok(1) } else { ok(0) }
ok(exists($obj->{FIELDS}{title}));
ok(exists($obj->{FIELDS}{date}));

$obj = Library::Catalog::News->new([qw/date/]);
ok(exists($obj->{FIELDS}{title}));
ok(exists($obj->{FIELDS}{date}));

$obj = Library::Catalog::News->new([qw/time author/]);
#6
ok(exists($obj->{FIELDS}{title}));
ok(exists($obj->{FIELDS}{author}));
ok(exists($obj->{FIELDS}{time}));
ok(exists($obj->{FIELDS}{date}));

$obj->add( {title=>'b', zbr => '2'}, {title=>'c'} );
ok(exists($obj->{DATA}));

my $record = $obj->{DATA}[0];

#11
ok(exists($record->{time}));
ok(exists($record->{time}{hour}));
ok(exists($record->{time}{minutes}));

#14
ok(exists($record->{date}));
ok(exists($record->{date}{day}));
ok(exists($record->{date}{month}));
ok(exists($record->{date}{year}));

#18
ok(exists($record->{title}));
ok(!exists($record->{zbr}));
ok(exists($record->{author}));

#21
ok(scalar(@{$obj->{DATA}}) == 2);


$obj = Library::Catalog::News->new([qw/date title/]);
$obj->save("/tmp/_${$}_");
#22
cmpfiles("/tmp/_${$}_","t/out5");


$obj->add( { date => '20020202', title => '20020202' } );
$obj->save("/tmp/_${$}_");
#23
cmpfiles("/tmp/_${$}_","t/out6");

$obj->add( { date => '20040202', title => '20040202' } );
$obj->save("/tmp/_${$}_");
#24
cmpfiles("/tmp/_${$}_","t/out7");

open X, ">/tmp/_${$}_";
print X $obj->as_HTML(0, "[DATE.DAY] - [DATE.MONTH] - [DATE.YEAR] : [TITLE]\n");
close X;
#25
cmpfiles("/tmp/_${$}_","t/out8");

open X, ">/tmp/_${$}_";
print X $obj->as_HTML(2, "[DATE.DAY] - [DATE.MONTH] - [DATE.YEAR] : [TITLE]\n");
close X;
#26
cmpfiles("/tmp/_${$}_","t/out8");

open X, ">/tmp/_${$}_";
print X $obj->as_HTML(2, "[DATE]: [TITLE]\n");
close X;
#27
cmpfiles("/tmp/_${$}_","t/out9");

my $obj2 = Library::Catalog::News->load("t/out7");
#28
ok(exists($obj2->{DATA}));

$record = $obj2->{DATA}[0];

#29
ok(exists($record->{date}));
ok(exists($record->{date}{day}));
ok(exists($record->{date}{month}));
ok(exists($record->{date}{year}));

#33
ok(scalar(@{$obj->{DATA}}) == 2);
ok(exists($obj->{FIELDS}{title}));
ok(exists($obj->{FIELDS}{date}));

unlink("/tmp/_${$}_");


sub cmpfiles {
  my $f1 = shift;
  my $f2 = shift;

  undef($/);
  if (open F, $f1) {
    my $t = <F>;
    close F;

    open R, $f2;
    my $res = <R>;
    close R;

    ok($t,$res);
  } else {
    ok(0);
  }
}

