import re
import ast


class Formatter(object):
    def __init__(self, lines, width=79):
        self.lines = lines
        self.width = width

        self.indent = 0

    def format(self):
        """
        The main executor function. Takes all lines, formats them and returns
        the result.

        """

        ret = []
        data = self.unindent(self.lines)
        root = ast.parse('\n'.join(data))

        for node in root.body:
            ret += self.parse(node)

        return self.reindent(ret)

    def unindent(self, lines):
        """
        Remove indentation from the lines.

        The ast parser will parse the code as valid Python code. The formatter
        can get partial parts of a Python file, and trying to run that would
        lead to an indentation error. This function checks the first line of
        code, detects the indentation, store that on the instance, removes the
        indentation from all lines, and returns them.

        """

        self.indent = re.search('\S', lines[0]).start()
        if self.indent == 0:
            return lines

        lines = [s[self.indent:] for s in lines]
        return lines

    def reindent(self, lines):
        """
        Re-apply the indentation that was removed.

        """

        if self.indent == 0:
            return lines
        return ['{0}{1}'.format(' ' * self.indent, s) for s in lines]

    def handle_assign(self, node):
        """
        x = y

        A simple assignment. Will run self.parse on the y part.

        """

        targets = ', '.join(t.id for t in node.targets)
        value = self.parse(node.value)

        ret = ['{0} = {1}'.format(targets, value[0])]
        ret += value[1:]
        return ret

    def handle_call(self, node):
        """
        function()

        Handles a function call. Handles arguments, keyword arguments and star
        arguments.

        """

        func = node.func.id
        args = []
        if node.args:
            args += [self.parse(a) for a in node.args]
        if node.keywords:
            args += [self.handle_keyword(a) for a in node.keywords]

        if node.starargs:
            args.append('*{0}'.format(node.starargs.id))
        if node.kwargs:
            args.append('**{0}'.format(node.kwargs.id))

        line = '{0}({1})'.format(func, ', '.join(args))
        if len(line) < self.width:
            # Line fits. Send it.
            return [line]

        ret = ['{0}('.format(func)]
        ret += ['    {0},'.format(arg) for arg in args]
        ret.append(')')

        return ret

    def handle_num(self, node):
        """
        1

        Any numeric node.

        """

        return str(node.n)

    def handle_nameconstant(self, node):
        """
        True

        Constants defined by the language, such as None and True.

        """

        return str(node.value)

    def handle_keyword(self, node):
        """
        x=y

        Keyword assignments to calls. Has separate logic since it should not
        have spaces. Will run self.parse on y.

        """

        return '{0}={1}'.format(node.arg, self.parse(node.value))

    def parse(self, node):
        """
        Determine what to do with a node.

        Raises an Exception if no handler method is defined.

        """

        cls = node.__class__.__name__.lower()
        func = getattr(self, 'handle_{0}'.format(cls), None)
        if func:
            return func(node)

        raise Exception('Unhandled node {0}'.format(node))  # pragma: nocover
