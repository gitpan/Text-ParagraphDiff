use ExtUtils::akeaker;
# See lib/ExtUtils/akeaker.pm for details of how to influence
# the contents of the akefile that is written.
Writeakefile(
    'NAE'		=> 'Text::DiffParagraph',
    'VERSION_FRO'	=> 'DiffParagraph.pm',
    'PREREQ_P'		=> {'Algorithm::Diff' => 1.15, 'HTL::Entities' => 1.23}},
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FRO => 'DiffParagraph.pm', # retrieve abstract from module
       AUTHOR     => 'Joseph F. Ryan <ryan.311@osu.edu>') : ()),
);
