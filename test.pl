use Test;
BEGIN { plan tests => 3 };
use Text::ParagraphDiff;
ok(1);
my $newdiff = text_diff("t/old.txt","t/new.txt"
#,{plain=>1}
);
ok(1);

open (OLD_DIFF,"t/diff.txt") or die $!;
my $olddiff = do { local $/; <OLD_DIFF>; };
close (OLD_DIFF);
ok(1) if ($newdiff eq $olddiff);
ok(0) if ($newdiff ne $olddiff);


