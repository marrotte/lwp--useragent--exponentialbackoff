use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'LWP::UserAgent::ExponentialBackoff',
    VERSION_FROM      => 'lib/LWP/UserAgent/ExponentialBackoff.pm',
    PREREQ_PM         => {
        LWP::UserAgent => 0,
    },
    TEST_REQUIRES     => {
        'Test::NoWarnings' => 0,
    },
    'dist'         => { COMPRESS => 'gzip -6f', SUFFIX => 'gz', },
);
