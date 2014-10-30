import ast
import _ast


class Formatter(object):
    def __init__(self, lines, width=79):
        self.lines = lines
        self.width = width
        self.data = '\n'.join(lines)

        self.indentation = ''

    def format(self):
        ret = []
        root = ast.parse(self.data)

        for node in root.body:
            ret += self.parse(node)

        return ret

    def handle_assign(self, node):
        targets = ', '.join(t.id for t in node.targets)
        value = self.parse(node.value)

        if isinstance(value, list):
            ret = ['{0} = {1}'.format(targets, value[0])]
            ret += value[1:]
            return ret

        line = '{0} = {1}'.format(targets, value)
        return [line]

    def handle_call(self, node):
        func = node.func.id
        args = []
        if node.args:
            args += [self.parse(a) for a in node.args]
        if node.keywords:
            args += [self.handle_keyword(a) for a in node.kwargs]

        if node.starargs:
            args.append('*{0}'.format(node.starargs.id))
        if node.kwargs:
            args.append('**{0}'.format(node.kwargs.id))

        line = '{0}({1})'.format(func, ', '.join(args))
        if len(line) < self.width:
            # Line fits. Send it.
            return [line]

        print(args)
        ret = ['{0}('.format(func)]
        ret += ['    {0},'.format(arg) for arg in args]
        ret.append(')')

        return ret

    def handle_num(self, node):
        return str(node.n)

    def handle_keyword(self, node):
        return '{0}={1}'.format(node.arg, self.parse(node.value))

    def parse(self, node):
        if isinstance(node, _ast.Assign):
            return self.handle_assign(node)
        elif isinstance(node, _ast.Call):
            return self.handle_call(node)
        elif isinstance(node, _ast.Num):
            return self.handle_num(node)

        raise Exception('Unhandled node {0}'.format(node))
