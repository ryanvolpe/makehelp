# makehelp
Generates help documentation from embedded comments in a Makefile

## Example

Once marked up as below, running ``make makehelp`` will produce the following output:

<pre>
Usage: make [TARGETS]

  General documentation about building this project.

Targets:
  <b>build</b>    Builds the project.
  <b>clean</b>    Removes any <b>build</b> artifacts.
  <b>install</b>  Installs to the configured <u>prefix</u>.
  <b>makehelp</b> Display this help message and exit.
</pre>

~~~makefile
#: General documentation about building this project.

# […] miscellaneous useful variables and whatnot […]

#: Display this help message and exit.
makehelp:
	./makehelp.sh "$(lastword $(MAKEFILE_LIST))"

#: Builds the project.
build: $(BUILDDIR)
	@echo "Build a thing."

$(BUILDDIR):
	@echo "Make build directory."

#: Removes any *[build]* artifacts
clean:
	@echo "Clean up time!"

#: Installs to the configured _[prefix]_.
install:
	@echo "Install a thing."
~~~

## Doc strings
A *doc string* is a comment that will be captured and extracted by **makehelp** when processing a Makefile.

### Syntax
Any contiguous block of lines starting with ``#: `` will be captured as a doc string. Newlines will be removed.

A doc string that immediately precedes a make target will be "associated" with that target. Any other doc string will be considered general help information.

### Formatting
Minor formatting of help output is available via doc string markup:

<pre>
*[bold]*        => <b>bold</b>
_[underscore]_  => <u>underscore</u>
~[inverse]~     => <span style="color: #CCC; background: #333">inverse</span>
</pre>

## Output

When run, **makehelp** will collect all doc strings from the target Makefile. General help documentation will be collected and displayed in the header block. Doc strings associated with make targets will be sorted and displayed in the "targets" section.

## "Static" ouput

Developers may not want to distribute **makehelp** with their code, and that's entirely reasonable. The ``makehelp.sh`` script provides a ``--static`` argument that will append a pre-generated version of this documentation to the existing Makefile:

<pre>
$ ./makehelp.sh Makefile --static

.PHONY: makehelp
#: Display this help message and exit.
makehelp:
	# Generated by makehelp.sh version 0.2
	@echo 'Usage: make [TARGETS]'
	@echo ''
	@echo '  General documentation about building this project.'
	@echo ''
	@echo 'Targets:'
	@echo '  <b>build</b>    Builds the project.'
	@echo '  <b>clean</b>    Removes any <b>build</b> artifacts'
	@echo '  <b>install</b>  Installs to the configured <u>prefix</u>.'
	@echo '  <b>makehelp</b> Display this help message and exit.'
</pre>