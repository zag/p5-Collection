use Module::Build;
Module::Build->new
    ( module_name => 'Collection',
    license => 'perl',
    prereq =>{
	Storable =>0,
	Flow=>0.6,
	String::CRC32 => 1.4,
    },
    dist_author=>'Zahatski Aliaksandr zag@cpan.org',
    create_makefile_pl=>$ENV{DO_OUTCPAN} ? 'traditional':'passthrough'
    )->create_build_script;
