# -*- cperl -*-
use Test;
use Library::Catalog;

BEGIN { plan tests => 12 }


### 1
my $cat = catalogNew("/tmp/_${$}_");
if ($cat) {
  ok(1);
} else {
  ok(0);
}

### 2
my $cat2 = catalogLoad("/tmp/_${$}_");
if ($cat2) {
  ok(1);
} else {
  ok(0);
}

### 3
undef($/);
if (open F, "/tmp/_${$}_") {
  my $t = <F>;
  close F;

  open R, "t/out1";
  my $res = <R>;
  close R;

  ok($t,$res);
} else {
  ok(0);
}

### 4
$cat2 -> catalogAdd(1, "<title>Me</title>");

if (defined($cat2->{toadd}->{1})) {
  ok(1);
} else {
  ok(0);
}

### 5
ok("<title>Me</title>",$cat2->catalogId(1));

$cat2->catalogSave;

### 6
undef($/);
if (open F, "/tmp/_${$}_") {
  my $t = <F>;
  close F;

  open R, "t/out2";
  my $res = <R>;
  close R;

  ok($t,$res);
} else {
  ok(0);
}

### 7
$cat3 = catalogLoad("/tmp/_${$}_");
ok("<title>Me</title>",$cat3->catalogId(1));

### 8
ok(undef,$cat3->catalogId(2));

### 9
$cat3->catalogRemove(1);
ok(undef,$cat3->catalogId(1));

### 10
$cat3 -> catalogAdd(1, "<title>Me</title>");
ok("<title>Me</title>",$cat3->catalogId(1));

### 11
$cat3->catalogRemove(1);
ok(undef,$cat3->catalogId(1));

### 12
$cat3->catalogSave;

undef($/);
if (open F, "/tmp/_${$}_") {
  my $t = <F>;
  close F;

  open R, "t/out1";
  my $res = <R>;
  close R;

  ok($t,$res);
} else {
  ok(0);
}


unlink("/tmp/_${$}_");
