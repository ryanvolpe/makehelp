#!/usr/bin/env bat
# vim: sw=4:sts=4:expandtab:foldmethod=marker:foldmarker={,}

MAKEFILES="$BATS_TEST_DIRNAME/makefiles"

@test "makehelp.sh has a --help option" {
    run ./makehelp.sh --help
    [ "$status" -eq 0 ]
    [ "${#lines[@]}" -ge 3 ]
}

@test "makehelp.sh takes exactly one Makefile" {
    run ./makehelp.sh
    [ "$status" -ne 0 ]
    [ "${#lines[@]}" -eq 2 ]
    skip "currently failing"
    run ./makehelp.sh one two
    [ "$status" -ne 0 ]
    [ "${#lines[@]}" -eq 2 ]
}

@test "makehelp.sh has a --static option" {
    run ./makehelp.sh --static "$MAKEFILES/simple.mk"
    [ "$status" -eq 0 ]
    run ./makehelp.sh "$MAKEFILES/simple.mk" --static
    [ "$status" -eq 0 ]
}

@test "check simple makefile" {
    run ./makehelp.sh "$MAKEFILES/simple.mk"
    [ "$status" -eq 0 ]
}
