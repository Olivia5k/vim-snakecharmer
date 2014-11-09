from pythonx.formatter import Formatter


class TestOneLinerCalls(object):
    def test_below_width(self):
        form = Formatter(['x = a(1)'], width=20)
        ret = form.format()

        assert ret == ['x = a(1)']

    def test_long_with_one_opener(self):
        form = Formatter(['x = hax(11111)'], width=10)
        ret = form.format()

        assert ret == [
            'x = hax(',
            '    11111,',
            ')',
        ]

    def test_long_with_one_opener_multiple_arguments(self):
        form = Formatter(['x = hax(11111, 22222)'], width=10)
        ret = form.format()

        assert ret == [
            'x = hax(',
            '    11111,',
            '    22222,',
            ')',
        ]

    def test_indented_long_with_one_opener_multiple_arguments(self):
        form = Formatter(['    x = hax(11111, 22222)'], width=10)
        ret = form.format()

        assert ret == [
            '    x = hax(',
            '        11111,',
            '        22222,',
            '    )',
        ]


class TestMultilineCalls(object):
    def test_already_formatted(self):
        lines = [
            'x = hax(',
            '    11111,',
            '    22222,',
            ')',
        ]

        form = Formatter(lines, width=10)
        ret = form.format()

        assert ret == lines


class TestArgsAndKwargs(object):
    def test_star_args(self):
        form = Formatter(['x = hax(*args)'], width=5)
        ret = form.format()

        assert ret == [
            'x = hax(',
            '    *args,',
            ')',
        ]

    def test_star_args_with_a_list(self):
        form = Formatter(['x = hax(*[1,2,3,])'], width=15)
        ret = form.format()

        assert ret == [
            'x = hax(',
            '    *[1, 2, 3],',
            ')',
        ]

    def test_star_args_with_a_long_list(self):
        form = Formatter(['x = hax(*[1,2,3,])'], width=5)
        ret = form.format()

        assert ret == [
            'x = hax(',
            '    *[,',
            '        1,',
            '        2,',
            '        3,',
            '    ],',
            ')',
        ]

    def test_star_kwargs(self):
        form = Formatter(['x = hax(**kwargs)'], width=5)
        ret = form.format()

        assert ret == [
            'x = hax(',
            '    **kwargs,',
            ')',
        ]

    def test_star_kwargs_with_a_dict(self):
        form = Formatter(['x = hax(**{"hax": True})'], width=15)
        ret = form.format()

        assert ret == [
            'x = hax(',
            '    **{"hax": True},',
            ')',
        ]

    def test_star_kwargs_with_long_dict(self):
        form = Formatter(['x = hax(**{"hax": True})'], width=5)
        ret = form.format()

        assert ret == [
            'x = hax(',
            '    **{,',
            '        "hax": True,',
            '    },',
            ')',
        ]

    def test_kwargs(self):
        form = Formatter(['x = hax(keyword=11)'], width=5)
        ret = form.format()

        assert ret == [
            'x = hax(',
            '    keyword=11,',
            ')',
        ]

    def test_args(self):
        form = Formatter(['x = hax(11)'], width=5)
        ret = form.format()

        assert ret == [
            'x = hax(',
            '    11,',
            ')',
        ]

    def test_all(self):
        form = Formatter(['x = hax(11, nofx=True, *coaster, **aye)'], width=20)
        ret = form.format()

        assert ret == [
            'x = hax(',
            '    11,',
            '    nofx=True,',
            '    *coaster,',
            '    **aye,',
            ')',
        ]


class TestDict(object):
    def test_empty(self):
        form = Formatter(['        {}'], width=5)
        ret = form.format()

        assert ret == ['        {}']

    def test_one_key(self):
        form = Formatter(['{"key": True}'], width=5)
        ret = form.format()

        assert ret == [
            '{',
            '    "key": True,',
            '}',
        ]

    def test_below_length(self):
        form = Formatter(['{"key": True, "key2": False}'], width=79)
        ret = form.format()

        assert ret == ['{"key": True, "key2": False}']

    def test_multiple_keys(self):
        form = Formatter(['{"key": True, "key2": False}'], width=5)
        ret = form.format()

        assert ret == [
            '{',
            '    "key": True,',
            '    "key2": False,',
            '}',
        ]

    def test_non_string_key(self):
        form = Formatter(['{1: True}'], width=5)
        ret = form.format()

        assert ret == [
            '{',
            '    1: True,',
            '}',
        ]


class TestList(object):
    def test_empty(self):
        form = Formatter(['        []'], width=5)
        ret = form.format()

        assert ret == ['        []']

    def test_below_length(self):
        form = Formatter(['[1,2,3,4,5]'], width=79)
        ret = form.format()

        assert ret == ['[1, 2, 3, 4, 5]']

    def test_above_length(self):
        form = Formatter(['[1,2,3,4,5]'], width=3)
        ret = form.format()

        assert ret == [
            '[',
            '    1,',
            '    2,',
            '    3,',
            '    4,',
            '    5,',
            ']',
        ]
