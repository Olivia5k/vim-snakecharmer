import re
import ast


class Formatter(object):
    def format(self, lines, width=79):
        """
        The main executor function. Takes all lines, formats them and returns
        the result.

        """

        try:
            ret = []
            blocks = [[]]
            comment = False
            comment_block = False
            data, indent = self.unindent(lines)

            for line in data:
                comment = line.startswith('#')
                comment_block = blocks and blocks[-1] and \
                    blocks[-1][0].startswith('#')

                if comment:
                    if not comment_block:
                        blocks.append([])
                    blocks[-1].append(line)
                else:
                    if comment_block:
                        blocks.append([])
                    blocks[-1].append(line)

            for block in blocks:
                if block[0].startswith('#'):
                    ret += self.format_comments(block)
                else:
                    root = ast.parse('\n'.join(block))

                    for node in root.body:
                        ret += self.parse(node, width)

            ret = self.reindent(ret, indent)

        except Exception:
            # If anything at all goes wrong, just return the original.
            ret = lines

        return ret

    def format_comments(self, lines):
        return lines

    def unindent(self, lines):
        """
        Remove indentation from the lines.

        The ast parser will parse the code as valid Python code. The formatter
        can get partial parts of a Python file, and trying to run that would
        lead to an indentation error. This function checks the first line of
        code, detects the indentation, removes the indentation from all lines,
        and returns them.

        """

        indent = re.search('\S', lines[0]).start()
        if indent == 0:
            return lines, indent

        lines = [s[indent:] for s in lines]
        return lines, indent

    def reindent(self, lines, indent):
        """
        Re-apply the indentation that was removed.

        """

        if indent == 0:
            return lines
        return ['{0}{1}'.format(' ' * indent, s) for s in lines]

    def parse(self, node, width):
        """
        Determine what to do with a node.

        Raises an Exception if no handler method is defined.

        """

        cls = node.__class__.__name__.lower()
        func = getattr(self, 'handle_{0}'.format(cls), None)
        if func:
            return func(node, width)

        raise Exception('Unhandled node {0}'.format(node))  # pragma: nocover

    def handle_assign(self, node, width):
        """
        x = y

        A simple assignment. Will run self.parse on the y part.

        """

        targets = ', '.join(t.id for t in node.targets)
        value = self.parse(node.value, width)

        ret = ['{0} = {1}'.format(targets, value[0])]
        ret += value[1:]
        return ret

    def handle_call(self, node, width):
        """
        function()

        Handles a function call. Handles arguments, keyword arguments and star
        arguments.

        """

        func = node.func.id
        args = []
        if node.args:
            args += [self.parse(a, width) for a in node.args]
        if node.keywords:
            args += [self.handle_keyword(a, width) for a in node.keywords]

        if node.starargs:
            args += self._handle_stars('*', node.starargs, width)
        if node.kwargs:
            args += self._handle_stars('**', node.kwargs, width)

        line = '{0}({1})'.format(func, ', '.join(args))
        if len(line) < width:
            # Line fits. Send it.
            return [line]

        ret = ['{0}('.format(func)]
        ret += ['    {0},'.format(arg) for arg in args]
        ret.append(')')

        return ret

    def handle_num(self, node, width):
        """
        1

        Any numeric node.

        """

        return str(node.n)

    def handle_nameconstant(self, node, width):
        """
        True

        Constants defined by the language, such as None and True.

        """

        return str(node.value)

    def handle_expr(self, node, width):
        """
        Handle any kind of expression that is not an assignment. Just parse it.

        """

        return self.parse(node.value, width)

    def handle_dict(self, node, width):
        """
        {"key": Value}

        Parse a dictionary. Will run parse on both keys and values.
        Will not sort the keys.

        """

        if not node.keys:
            return ['{}']

        items = []
        for key, value in zip(node.keys, node.values):
            items.append(
                '{0}: {1}'.format(
                    self.parse(key, width),
                    self.parse(value, width)
                )
            )

        line = '{{{0}}}'.format(', '.join(items))
        if len(line) < width:
            # Line fits. Send it.
            return [line]

        ret = ['{']
        ret += ['    {0},'.format(item) for item in items]
        ret.append('}')

        return ret

    def handle_str(self, node, width):
        """
        "hehe"

        Handle a string.

        """

        # TODO: Single or double? Raw strings?
        return '"{0}"'.format(node.s)

    def handle_name(self, node, width):
        """
        x

        Handle a variable.

        """

        return "{0}".format(node.id)

    def handle_list(self, node, width):
        # TODO: .ctx?
        return self._handle_iterable('[]', node.elts, width)

    def handle_tuple(self, node, width):
        return self._handle_iterable('()', node.elts, width)

    def handle_set(self, node, width):
        return self._handle_iterable('{}', node.elts, width)

    def handle_importfrom(self, node, width):
        """
        from module import item

        Will split comma separated imports to separate lines.

        """

        return self._handle_import(node, module=node.module)

    def handle_import(self, node, width):
        """
        import item

        Will split comma separated imports to separate lines.

        """
        return self._handle_import(node)

    def handle_keyword(self, node, width):
        """
        x=y

        Keyword assignments to calls. Has separate logic since it should not
        have spaces. Will run self.parse on y.

        """

        return '{0}={1}'.format(node.arg, self.parse(node.value, width))

    def _handle_stars(self, token, items, width):
        """
        Handle parsing of starargs and starkwargs in function calls.

        """

        args = []
        targets = self.parse(items, width)

        if isinstance(targets, list):
            args.append('{0}{1}'.format(token, targets[0]))
            if len(targets) > 1:
                # The x[:-1] is to remove the comma that the parser added.
                args += [x[:-1] for x in targets[1:-1]]
                args.append(targets[-1])
        else:
            args.append('{0}{1}'.format(token, targets))

        return args

    def _handle_iterable(self, tokens, items, width):
        """
        Handle a iterable, such as a list or a tuple.

        """

        if not items:
            return [tokens]

        items = [self.parse(x, width) for x in items]
        line = '{1}{0}{2}'.format(', '.join(items), *tokens)
        if len(line) < width:
            # Line fits. Send it.
            return [line]

        ret = [tokens[0]]
        ret += ['    {0},'.format(item) for item in items]
        ret.append(tokens[1])

        return ret

    def _handle_import(self, node, module=None):
        """
        Handle both kinds of import statements.

        """

        ret = []
        for name in node.names:
            imp = name.name
            if name.asname:
                imp = '{0} as {1}'.format(imp, name.asname)

            mod = ''
            if module:
                mod = 'from {0} '.format(module)
            ret.append('{mod}import {imp}'.format(imp=imp, mod=mod))
        return ret
