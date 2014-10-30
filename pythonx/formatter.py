import re


OPENERS = '([{'
OPENERS_RE = re.compile(r'([\[({])')
CLOSERS = ')]}'


class Formatter(object):
    def __init__(self, lines, width=79):
        self.lines = lines
        self.width = width

        self.indentation = ''

    def format(self):
        if len(self.lines) == 1:
            return self.oneline()

    def oneline(self):
        line = self.lines[0]
        # Line under width. Do nothing.
        if len(line) <= self.width:
            return [line]

        # No opening things. Do nothing.
        if not OPENERS_RE.search(line):
            return [line]

        # Line is too long and has openers. Apply magic.
        return self.align_opening(self.lines)

    def align_opening(self, lines):
        pre = ''
        inner = ''
        post = ''

        saw_char = False
        inside = False
        exited = False
        for line in lines:
            for c in line:
                if not inside and not exited:
                    if c == ' ':
                        if not saw_char:
                            self.indentation += c
                    else:
                        saw_char = True

                    pre += c
                    if c in OPENERS:
                        inside = True
                elif inside and not exited:
                    if c in CLOSERS:
                        exited = True
                        post += c
                    else:
                        inner += c
                # else:
                #     post += c

        # Take the inner arguments, split them on comma and indent them
        inner = map(str.strip, inner.split(','))
        inner = map(self.indent, inner)

        # Add the default indentation to the ender
        post = self.indentation + post

        return [pre] + list(inner) + [post]

    def indent(self, s):
        return self.indentation + '    ' + s
