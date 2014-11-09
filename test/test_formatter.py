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

    def test_star_kwargs(self):
        form = Formatter(['x = hax(**kwargs)'], width=5)
        ret = form.format()

        assert ret == [
            'x = hax(',
            '    **kwargs,',
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
