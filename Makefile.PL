use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'         => 'Library::Catalog',
    'VERSION_FROM' => 'Catalog.pm',
    'PREREQ_PM'    => {
		       'Library::MLang' => '0.03',
		       'Data::Dumper' => '2.10',
		      },
	     );

