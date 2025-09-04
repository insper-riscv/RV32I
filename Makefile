# Make sure /bin/bash is used for the 'find' in clean
SHELL := /bin/bash

.PHONY: test run clean

# Run all tests (no args)
test:
	python3 -m tests.python.utils.runner

# Run a single test by name
# Usage: make run TEST=<test_name>
run:
ifndef TEST
	$(error Usage: make run TEST=<test_name>)
endif
	python3 -m tests.python.utils.runner $(TEST)

# Remove generated waveforms
clean:
	find . -type f \( -name '*.vcd' -o -name '*.ghw' \) -print -delete
