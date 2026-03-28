all:
	@echo "Run 'make install' to deploy bass to your function directory."

install:
	install -d ~/.config/fish/functions
	install -m644 functions/__bass.py ~/.config/fish/functions
	install -m644 functions/bass.fish ~/.config/fish/functions

uninstall:
	rm -f ~/.config/fish/functions/__bass.py
	rm -f ~/.config/fish/functions/bass.fish

test-python:
	pytest tests/ -v

test-fish:
	fish test/test_bass.fish
	fish test/test_dollar_on_output.fish
	fish test/test_trailing_semicolon.fish
	fish test/test_non_zero_returncode.fish
	fish test/test_alias.fish
	fish test/test_function_capture.fish
	fish test/test_newline_env.fish
	fish test/test_quotes.fish
	fish test/test_virtualenv_compat.fish
	fish test/test_alias_dollar_star.fish
	fish test/test_slashed_path_perf.fish
	fish test/test_large_export.fish

test: test-python test-fish

.PHONY: test test-python test-fish
