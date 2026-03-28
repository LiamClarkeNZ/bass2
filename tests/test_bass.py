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

    def test_dollar_star_preserved_in_parse(self):
        """Issue #91: $* in alias values should be captured (conversion happens later)."""
        state = [b"alias testing='ls $* -l'"]
        result = bass.parse_aliases(state)
        assert result == {b"testing": b"'ls $* -l'"}


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


class TestIgnored:
    def test_pwd_not_ignored(self):
        assert bass.ignored(b'PWD') is False

    def test_fish_readonly_ignored(self):
        assert bass.ignored(b'SHLVL') is True
        assert bass.ignored(b'fish_pid') is True

    def test_ps1_ignored(self):
        assert bass.ignored(b'PS1') is True

    def test_bash_func_ignored(self):
        assert bass.ignored(b'BASH_FUNC_foo%%') is True

    def test_percent_prefix_ignored(self):
        assert bass.ignored(b'%something') is True

    def test_normal_var_not_ignored(self):
        assert bass.ignored(b'HOME') is False
        assert bass.ignored(b'MY_CUSTOM_VAR') is False


class TestComment:
    def test_single_line(self):
        result = bass.comment(b'hello')
        assert result == b'# hello'

    def test_multi_line(self):
        result = bass.comment(b'line1\nline2')
        assert result == b'# line1\n# line2'


class TestLoadEnv:
    def test_simple_env(self):
        result = bass.load_env('{"HOME": "/home/user", "PATH": "/usr/bin"}')
        assert result == {b'HOME': b'/home/user', b'PATH': b'/usr/bin'}

    def test_empty_env(self):
        result = bass.load_env('{}')
        assert result == {}

    def test_unicode_value(self):
        result = bass.load_env('{"LANG": "en_US.UTF-8"}')
        assert result[b'LANG'] == b'en_US.UTF-8'


class TestLoadState:
    def test_empty_state(self):
        bash_state, function_source = bass.load_state(b'')
        assert bash_state == []
        assert function_source == b''

    def test_alias_only(self):
        state = b"alias ll='ls -la'\nalias grep='grep --color'"
        bash_state, function_source = bass.load_state(state)
        assert len(bash_state) == 2
        assert function_source == b''

    def test_skips_exported_vars(self):
        state = b"declare -x HOME='/home/user'\nalias ll='ls -la'"
        bash_state, function_source = bass.load_state(state)
        assert len(bash_state) == 1
        assert bash_state[0] == b"alias ll='ls -la'"

    def test_skips_readonly_bash_vars(self):
        state = b"declare -r BASHOPTS='checkwinsize'\nalias ll='ls -la'"
        bash_state, function_source = bass.load_state(state)
        assert len(bash_state) == 1


class TestParseFunctions:
    def test_function_declaration(self):
        state = [b"declare -f my_func"]
        result = bass.parse_functions(state)
        assert result == {b"my_func"}

    def test_non_function_declare_ignored(self):
        state = [b"declare -i counter"]
        result = bass.parse_functions(state)
        assert result == set()

    def test_malformed_declare(self):
        state = [b"declare"]
        result = bass.parse_functions(state)
        assert result == set()

    def test_mixed_state(self):
        state = [
            b"alias ll='ls -la'",
            b"declare -f func1",
            b"declare -x HOME='/home/user'",
            b"declare -f func2",
        ]
        result = bass.parse_functions(state)
        assert result == {b"func1", b"func2"}
