#!/usr/bin/perl -w
use strict;
use Text::ParagraphDiff;

print text_diff($ARGV[0],$ARGV[1]);
