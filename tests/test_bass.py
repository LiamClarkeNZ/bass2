"""Tests for __bass.py core logic."""
import sys
import os
import importlib
import importlib.util


def _load_bass_module():
    """Load __bass.py as a module, neutralizing its top-level side effects."""
    spec = importlib.util.spec_from_file_location(
        "_bass",
        os.path.join(os.path.dirname(__file__), '..', 'functions', '__bass.py')
    )
    # Create a dummy fd 3 so the module-level os.fdopen(SCRIPT_FD, 'wb') doesn't crash
    r, w = os.pipe()
    if w != 3:
        os.dup2(w, 3)
        os.close(w)
    os.close(r)

    module = importlib.util.module_from_spec(spec)
    # Patch sys.argv so the module doesn't exit (needs at least state_file arg)
    old_argv = sys.argv
    sys.argv = ['__bass.py', '/dev/null', 'echo', 'hello']
    try:
        spec.loader.exec_module(module)
    except SystemExit:
        pass
    finally:
        sys.argv = old_argv
    return module


bass = _load_bass_module()


class TestParseAliases:
    def test_valid_alias(self):
        state = [b"alias ll='ls -la'"]
        result = bass.parse_aliases(state)
        assert result == {b"ll": b"'ls -la'"}

    def test_malformed_line_no_space(self):
        """Issue #113: ValueError when alias line has no space."""
        state = [b"malformed_line_without_space"]
        result = bass.parse_aliases(state)
        assert result == {}

    def test_empty_state(self):
        result = bass.parse_aliases([])
        assert result == {}

    def test_non_alias_lines_ignored(self):
        state = [
            b"declare -x HOME='/home/user'",
            b"alias grep='grep --color=auto'",
        ]
        result = bass.parse_aliases(state)
        assert result == {b"grep": b"'grep --color=auto'"}


class TestEscape:
    def test_simple_string(self):
        result = bass.escape(b'hello')
        assert result == b'\\x68\\x65\\x6c\\x6c\\x6f'

    def test_newline(self):
        """Issue #103: newlines must not be mangled."""
        result = bass.escape(b'line1\nline2')
        assert b'\\x0a' in result

    def test_dollar_sign(self):
        result = bass.escape(b'$HOME')
        assert b'\\x24' in result

    def test_single_quote(self):
        result = bass.escape(b"it's")
        assert b'\\x27' in result

    def test_empty_string(self):
        result = bass.escape(b'')
        assert result == b''


class TestQuoteHandling:
    def test_json_string_in_escape(self):
        """Issue #105: quotes should be preserved in escaped output."""
        result = bass.escape(b'{"key": "value"}')
        assert b'\\x22' in result  # double quote
        assert b'\\x7b' in result  # {
        assert b'\\x7d' in result  # }
