.PHONY: test clean

# Run all tests
test:
	python3 -m utils.runner all

# Run a single test by name
# Example: make run TEST=example_and_gate
run:
	python3 -m utils.runner $(TEST)

clean:
	rm -f **/*.vcd **/*.ghw || true
