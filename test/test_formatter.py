from pythonx.formatter import Formatter


class TestOneLiner(object):
    def test_below_width(self):
        form = Formatter(['x = 1'], width=20)
        ret = form.format()

        assert ret == ['x = 1']

    def test_long_without_opener(self):
        form = Formatter(['x = 12345'], width=7)
        ret = form.format()

        assert ret == ['x = 12345']

    def test_long_with_one_opener(self):
        form = Formatter(['x = hax(11111)'], width=10)
        ret = form.format()

        assert ret == [
            'x = hax(',
            '    11111',
            ')',
        ]

    def test_long_with_one_opener_multiple_arguments(self):
        form = Formatter(['x = hax(11111, 22222)'], width=10)
        ret = form.format()

        assert ret == [
            'x = hax(',
            '    11111',
            '    22222',
            ')',
        ]

    def test_indented_long_with_one_opener_multiple_arguments(self):
        form = Formatter(['    x = hax(11111, 22222)'], width=10)
        ret = form.format()

        assert ret == [
            '    x = hax(',
            '        11111',
            '        22222',
            '    )',
        ]
