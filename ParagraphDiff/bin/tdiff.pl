#!/usr/bin/perl -w
use strict;
use Text::DiffParagraph;

print text_diff($ARGV[0],$ARGV[1],{plain=>1});
