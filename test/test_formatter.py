import mock

from pythonx.formatter import Formatter


class BaseTest(object):
    def setup_method(self, method):
        self.form = Formatter()


class TestOneLinerCalls(BaseTest):
    def test_below_width(self):
        ret = self.form.format(['x = a(1)'], width=20)

        assert ret == ['x = a(1)']

    def test_long_with_one_opener(self):
        ret = self.form.format(['x = hax(11111)'], width=10)

        assert ret == [
            'x = hax(',
            '    11111,',
            ')',
        ]

    def test_long_with_one_opener_multiple_arguments(self):
        ret = self.form.format(['x = hax(11111, 22222)'], width=10)

        assert ret == [
            'x = hax(',
            '    11111,',
            '    22222,',
            ')',
        ]

    def test_indented_long_with_one_opener_multiple_arguments(self):
        ret = self.form.format(['    x = hax(11111, 22222)'], width=10)

        assert ret == [
            '    x = hax(',
            '        11111,',
            '        22222,',
            '    )',
        ]


class TestMultilineCalls(BaseTest):
    def test_already_formatted(self):
        lines = [
            'x = hax(',
            '    11111,',
            '    22222,',
            ')',
        ]

        ret = self.form.format(lines, width=10)

        assert ret == lines


class TestArgsAndKwargs(BaseTest):
    def test_star_args(self):
        ret = self.form.format(['x = hax(*args)'], width=5)

        assert ret == [
            'x = hax(',
            '    *args,',
            ')',
        ]

    def test_star_args_with_a_list(self):
        ret = self.form.format(['x = hax(*[1,2,3,])'], width=15)

        assert ret == [
            'x = hax(',
            '    *[1, 2, 3],',
            ')',
        ]

    def test_star_args_with_a_long_list(self):
        ret = self.form.format(['x = hax(*[1,2,3,])'], width=5)

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
        ret = self.form.format(['x = hax(**kwargs)'], width=5)

        assert ret == [
            'x = hax(',
            '    **kwargs,',
            ')',
        ]

    def test_star_kwargs_with_a_dict(self):
        ret = self.form.format(['x = hax(**{"hax": True})'], width=15)

        assert ret == [
            'x = hax(',
            '    **{"hax": True},',
            ')',
        ]

    def test_star_kwargs_with_long_dict(self):
        ret = self.form.format(['x = hax(**{"hax": True})'], width=5)

        assert ret == [
            'x = hax(',
            '    **{,',
            '        "hax": True,',
            '    },',
            ')',
        ]

    def test_kwargs(self):
        ret = self.form.format(['x = hax(keyword=11)'], width=5)

        assert ret == [
            'x = hax(',
            '    keyword=11,',
            ')',
        ]

    def test_args(self):
        ret = self.form.format(['x = hax(11)'], width=5)

        assert ret == [
            'x = hax(',
            '    11,',
            ')',
        ]

    def test_all(self):
        ret = self.form.format(
            ['x = hax(11, nofx=True, *coaster, **aye)'],
            width=20
        )

        assert ret == [
            'x = hax(',
            '    11,',
            '    nofx=True,',
            '    *coaster,',
            '    **aye,',
            ')',
        ]


class TestDict(BaseTest):
    def test_empty(self):
        ret = self.form.format(['        {}'], width=5)

        assert ret == ['        {}']

    def test_one_key(self):
        ret = self.form.format(['{"key": True}'], width=5)

        assert ret == [
            '{',
            '    "key": True,',
            '}',
        ]

    def test_below_length(self):
        ret = self.form.format(['{"key": True, "key2": False}'], width=79)

        assert ret == ['{"key": True, "key2": False}']

    def test_multiple_keys(self):
        ret = self.form.format(['{"key": True, "key2": False}'], width=5)

        assert ret == [
            '{',
            '    "key": True,',
            '    "key2": False,',
            '}',
        ]

    def test_non_string_key(self):
        ret = self.form.format(['{1: True}'], width=5)

        assert ret == [
            '{',
            '    1: True,',
            '}',
        ]


class TestList(BaseTest):
    def test_empty(self):
        ret = self.form.format(['        []'], width=5)

        assert ret == ['        []']

    def test_below_length(self):
        ret = self.form.format(['[1,2,3,4,5]'], width=79)

        assert ret == ['[1, 2, 3, 4, 5]']

    def test_above_length(self):
        ret = self.form.format(['[1,2,3,4,5]'], width=3)

        assert ret == [
            '[',
            '    1,',
            '    2,',
            '    3,',
            '    4,',
            '    5,',
            ']',
        ]


class TestTuple(BaseTest):
    def test_below_length(self):
        ret = self.form.format(['(1,2,3,4,5)'], width=79)

        assert ret == ['(1, 2, 3, 4, 5)']

    def test_above_length(self):
        ret = self.form.format(['(1,2,3,4,5)'], width=3)

        assert ret == [
            '(',
            '    1,',
            '    2,',
            '    3,',
            '    4,',
            '    5,',
            ')',
        ]


class TestSet(BaseTest):
    def test_below_length(self):
        ret = self.form.format(['{1,2,3,4,5}'], width=79)

        assert ret == ['{1, 2, 3, 4, 5}']

    def test_above_length(self):
        ret = self.form.format(['{1,2,3,4,5}'], width=3)

        assert ret == [
            '{',
            '    1,',
            '    2,',
            '    3,',
            '    4,',
            '    5,',
            '}',
        ]


class TestImportFrom(BaseTest):
    def test_comma_split_to_separate_import(self):
        ret = self.form.format(['from module import item, cls'])

        assert ret == [
            'from module import item',
            'from module import cls',
        ]

    def test_asname(self):
        ret = self.form.format(['from module import item as alias'])

        assert ret == ['from module import item as alias']

    def test_package(self):
        ret = self.form.format(['from module.package import item'])

        assert ret == ['from module.package import item']


class TestImport(BaseTest):
    def test_comma_split_to_separate_import(self):
        ret = self.form.format(['import item, cls'])

        assert ret == [
            'import item',
            'import cls',
        ]

    def test_asname(self):
        ret = self.form.format(['import item as alias'])

        assert ret == ['import item as alias']

    def test_package(self):
        ret = self.form.format(['import item.package'])

        assert ret == ['import item.package']


class TestCrash(BaseTest):
    @mock.patch('ast.parse')
    def test_hax(self, parse):
        parse.side_effect = Exception()

        ret = self.form.format(['unisonic', 'never too late'])

        assert ret == ['unisonic', 'never too late']


class TestComments(BaseTest):
    def test_below_length(self):
        ret = self.form.format(['# hehe'], width=79)

        assert ret == ['# hehe']

    def test_above_length(self):
        ret = self.form.format(['# You can fly, reach for the sky'], width=15)

        assert ret == [
            '# You can fly,',
            '# reach for the',
            '# sky',
        ]

    def test_restore_length(self):
        data = [
            '# You can fly,',
            '# reach for the',
            '# sky',
        ]
        ret = self.form.format(data, width=79)

        assert ret == ['# You can fly, reach for the sky']

    def test_restore_with_short_code(self):
        data = [
            '# You can fly,',
            '# reach for the',
            '# sky',
            'x = a(x=1)'
        ]
        ret = self.form.format(data, width=79)

        assert ret == [
            '# You can fly, reach for the sky',
            'x = a(x=1)',
        ]

    def test_short_code_with_restore(self):
        data = [
            'x = a(x=1)',
            '# You can fly,',
            '# reach for the',
            '# sky',
        ]
        ret = self.form.format(data, width=79)

        assert ret == [
            'x = a(x=1)',
            '# You can fly, reach for the sky',
        ]

    def test_long_comment_long_code(self):
        data = [
            '# You can fly, reach for the sky',
            'x = angel_underneath(x=1)',
        ]
        ret = self.form.format(data, width=15)

        assert ret == [
            '# You can fly,',
            '# reach for the',
            '# sky',
            'x = angel_underneath(',
            '    x=1,',
            ')',
        ]
