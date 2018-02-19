#!/usr/bin/env bash
# vim: ft=sh:sts=4:sw=4:expandtab

AUTHOR="Ryan Volpe"
VERSION="0.2"
LICENSE="Apache Public License, v2.0"

set -euo pipefail
IFS=$'\n\t'

STATIC_MODE=1
MAKEFILE=

while (( "$#" )); do
    arg="${1:-}"
    shift
    case "$arg" in
        --static)
            STATIC_MODE=0
            ;;

        --help)
            echo "Usage: $0 [OPTIONS] <Makefile>"
            echo
            echo -e "  Parses a \033[4mMakefile\033[0m for help documentation."
            echo
            echo "  This help documentation can be appended as a new make target via"
            echo "     \`./makehelp.sh Makefile --static >> Makefile'."
            echo "  The resulting Makefile will include help documentation without"
            echo -e "  requiring distribution of \033[1mmakehelp\033[0m itself."
            echo
            echo "Options:"
            echo "  --help   Show this message and exit."
            echo "  --static Generate a new make target with a static help string."
            exit 0
            ;;

        *)
            MAKEFILE="$arg"
            ;;
    esac
done

if [ -z "$MAKEFILE" ]; then
    echo "Error: a Makefile is required (see --help for details)" >&2
    echo "Usage: $0 [OPTIONS] <Makefile>" >&2
    exit 2
fi

if (( "$STATIC_MODE" == 0 )); then
    echo ""
    echo ".PHONY: makehelp"
    echo "#: Display this help message and exit."
    echo "makehelp:"
    echo $'\t'"# Generated by makehelp.sh version $VERSION"
    export _INJECT_MAKEHELP=0
    output="$($0 $MAKEFILE)"
    while read -r line; do
        echo $'\t'"@echo '$line'"
    done <<< "$output"
    exit 0
fi

parse_makefile ()
{
    in_doc=1
    decl=$'^([a-zA-Z0-9][^: ]*):'
    declare -a buf
    declare -a targets
    src="$(grep -v -E $'^\t' "$1")"
    for line in $src; do
        stripped="${line##\#:}"
        if (( ${#stripped} != ${#line} )); then
            if (( $in_doc == 1 )); then
                unset buf
                declare -a buf
                in_doc=0
            fi
            buf=( "${buf[@]}" "${stripped#"${stripped%%[![:space:]]*}"}" )
        elif [[ "$line" =~ $decl ]]; then
            if (( $in_doc == 0 )); then
                printf "${BASH_REMATCH[1]}"
                printf $'\1'
                echo "${buf[@]:0}"
                in_doc=1
            fi
            unset buf
            declare -a buf
        else
            if (( $in_doc == 0 )); then
                printf $'\1'
                echo "${buf[@]:0}"
                in_doc=1
            fi
            unset buf
            declare -a buf
        fi
    done
    if (( "${_INJECT_MAKEHELP:-1}" == 0 )); then
        # dirty hack time!
        # if --static, there *should* be no makehelp target defined.
        # let's inject it now...
        printf "makehelp"
        printf $'\1'
        echo "Display this help message and exit."
    fi
    return 0
}

format_doc ()
{
    echo "$1" | sed \
        -e's,_\[,\\033[4m,g' -e's,]_,\\033[0m,g' \
        -e's,\*\[,\\033[1m,g' -e's,]\*,\\033[0m,g' \
        -e's,\~\[,\\033[7m,g' -e's,]\~,\\033[0m,g'
}

maxlen=0
declare -a general
declare -a targets
for line in $(parse_makefile "$MAKEFILE"); do
    target=$(echo "$line" | awk -F$'\1' '{print $1}')
    doc=$(echo "$line" | awk -F$'\1' '{print $2}')
    doc="$(format_doc $doc)"
    if [ -n "$target" ]; then
        targets=( "${targets[@]}" "$target" )
        key="doc_$(echo $target | tr '-' '_')"
        declare $key="$doc"
        (( ${#target} > $maxlen )) && maxlen=${#target}
    else
        general=( "${general[@]}" "$doc" )
    fi
done

echo "Usage: make [TARGETS]"
echo
for doc in ${general[@]}; do
    echo -e ' ' "$doc"
    echo
done
echo "Targets:"

for target in $(sort <<<"${targets[*]}"); do
#for target in ${targets[@]}; do
    key="doc_$(echo $target | tr '-' '_')"
    doc="${!key}"
    let outlen=${#target}
    printf "  \033[1m%s\033[0m" "$target"
    for i in `seq $outlen $maxlen`; do
        printf ' '
    done
    echo -e "$doc"
done
