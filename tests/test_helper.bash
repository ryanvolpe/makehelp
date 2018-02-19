# vim: sts=4:sw=4:expandtab

fixtures ()
{
    FIXTURE_ROOT="$BATS_TEST_DIRNAME/fixtures/$1"
    bats_trim_filename "$FIXTURE_ROOT" 'RELATIVE_FIXTURE_ROOT'
}
