use Test;
BEGIN { plan tests => 12 };
use Text::ParagraphDiff;
ok(1);


Text::ParagraphDiff::create_diff( ["First middle last"],
                                  ["First middle last"]
) eq qq(\n<p>\nFirst middle last \n</p>\n) ? ok(1) : ok(0);

Text::ParagraphDiff::create_diff( ["First middle last"],
                                  ["First middle last extra"]
) eq qq(\n<p>\nFirst middle last  <span class="plus"> extra</span> \n</p>\n) ? ok(1) : ok(0);

Text::ParagraphDiff::create_diff( ["First middle last extra"],
                                  ["First middle last"]
) eq qq(\n<p>\nFirst middle last  <span class="minus"> extra</span> \n</p>\n) ? ok(1) : ok(0);

Text::ParagraphDiff::create_diff( ["First middle last"],
                                  ["Extra First middle last"]
) eq qq(\n<p>\n <span class="plus"> Extra</span> First middle last \n</p>\n) ? ok(1) : ok(0);

Text::ParagraphDiff::create_diff( ["Extra First middle last"],
                                  ["First middle last"]
) eq qq(\n<p>\n <span class="minus"> Extra</span> First middle last \n</p>\n) ? ok(1) : ok(0);

Text::ParagraphDiff::create_diff( ["First middle last"],
                                  ["First middle other"]
) eq qq(\n<p>\nFirst middle  <span class="plus"> other</span>  <span class="minus"> last</span> \n</p>\n) ? ok(1) : ok(0);

Text::ParagraphDiff::create_diff( ["First middle last"],
                                  ["First other last"]
) eq qq(\n<p>\nFirst  <span class="plus"> other</span>  <span class="minus"> middle</span> last \n</p>\n) ? ok(1) : ok(0);

Text::ParagraphDiff::create_diff( ["First middle last"],
                                  ["Other middle last"]
) eq qq(\n<p>\n <span class="plus"> Other</span>  <span class="minus"> First</span> middle last \n</p>\n) ? ok(1) : ok(0);

Text::ParagraphDiff::create_diff( ["First middle other"],
                                  ["First middle last"]
) eq qq(\n<p>\nFirst middle  <span class="plus"> last</span>  <span class="minus"> other</span> \n</p>\n) ? ok(1) : ok(0);

Text::ParagraphDiff::create_diff( ["First other last"],
                                  ["First middle last"]
) eq qq(\n<p>\nFirst  <span class="plus"> middle</span>  <span class="minus"> other</span> last \n</p>\n) ? ok(1) : ok(0);

Text::ParagraphDiff::create_diff( ["Other middle last"],
                                  ["First middle last"]
) eq qq(\n<p>\n <span class="plus"> First</span>  <span class="minus"> Other</span> middle last \n</p>\n) ? ok(1) : ok(0);