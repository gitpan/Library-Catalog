use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	      'NAME'         => 'Library::Catalog',
		EXE_FILES => [bibtex2html],
	      'VERSION_FROM' => 'Catalog.pm',
	      'PREREQ_PM'    => {
				 'XML::DT' => '0.19',
				 'DB_File' => '1.804',
				 'Data::Dumper' => '2.10',
				 'XML::XPath' => '1.12',
				 #'Text::BibTeX' => '0.34',
				},
	     );

