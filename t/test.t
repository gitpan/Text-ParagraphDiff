use Test;
BEGIN { plan tests => 3 };
use Text::ParagraphDiff;
ok(1);
my $newdiff = text_diff("old.txt","new.txt"
#,{plain=>1}
);
ok(1);

open (OLD_DIFF,"diff.txt") or die $!;
my $olddiff = do { local $/; <OLD_DIFF>; };
close (OLD_DIFF);
ok(1) if ($newdiff eq $olddiff);
ok(0) if ($newdiff ne $olddiff);


