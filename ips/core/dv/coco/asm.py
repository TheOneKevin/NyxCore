import re
from functools import reduce
from enum import Enum, auto
from typing import Callable, Pattern

# Tokens
class T(Enum):
    WHITESPACE  = auto()
    LBRAC       = auto()
    RBRAC       = auto()
    COMMA       = auto()
    REG         = auto()
    PM          = auto()
    SH          = auto()
    HEX_LIT     = auto()
    DEC_LIT     = auto()
    # Opcode classes
    OPR_LDR     = auto()
    OPR_STR     = auto()
    OPR_ALU     = auto()
    OPR_MOV     = auto()
    OPR_MVT     = auto()
    OPR_OTHER   = auto()
    # Patterns
    IMM         = auto()
    REFI        = auto()
    REFR        = auto()
    SHIFT       = auto()
    INSTR       = auto()

################################################################################
# Classes and structures for tokens and rules
################################################################################

class Token():
    def __init__(self, name: T, value):
        self.name = name
        self.value = value
    def __repr__(self):
        return 'Token(%s, "%s")'%(self.name, self.value)

class TRule():
    def __init__(self, name: T, pattern: Pattern):
        self.name = name
        self.pattern = pattern

class SRule():
    def __init__(
        self,
        name:       T,
        pattern:    list[T],
        parser:     Callable[[list[Token]], any] = lambda x: None
    ):
        self.name = name
        self.pattern = pattern
        self.parser = parser

################################################################################
# ISA Encoders
################################################################################

# TODO: Special register aliases

def encode_reg(name: Token):
    REGS = { 'r%d'%(i): i for i in range(0, 16) }
    a = REGS.get(name.value)
    if a is not None: return a
    raise SyntaxError('Unrecognized register "%s"'%name.value)

def encode_shift(reg: Token, sh: Token, imm: Token):
    SHIFT = { 'shl': 0, 'shr': 1, 'srx': 2, 'ror': 3 }
    a = SHIFT.get(sh.value); b = encode_reg(reg)
    if a and b and (imm.value in range(0, 32)):
        return (a << 12) | ((imm.value & 0b11111) << 4) | ((b & 0b11) << 2)
    raise SyntaxError('Bad shift expression')

def encode_simm(sign: Token, imm: Token, bits: int):
    if sign.value in ['+', '-']:
        return (imm.value if sign.value == '+' else (-imm.value + 2**32)) & ((1 << bits) - 1)
    raise SyntaxError('Bad immediate expression')

def encode_refi(reg: Token, sign: Token, imm: Token):
    return (encode_reg(reg) << 16) | encode_simm(sign, imm, 14)

def encode_refi(reg: Token, sign: Token, imm: Token):
    return (encode_reg(reg) << 16) | encode_simm(sign, imm, 14)

def encode_regs(reg: Token, sign: Token, shift: Token):
    return (encode_reg(reg) << 16) | (shift.value << 2)

def encode_mrs(op: int, rd: Token, sh: Token):
    return (op << 24) | (encode_reg(rd) << 20) | sh

def encode_mrr(op: int, rd: Token, rn: Token):
    return (op << 24) | (encode_reg(rd) << 20) | (encode_reg(rn) << 12)

################################################################################
# Assembly language grammar specification
################################################################################

# Tokens to be replaced, with rule priority as array order.
# Token value will be 1st capture group, if exists, otherwise entire match.

TOKEN_TABLE = [
    TRule(T.WHITESPACE, re.compile(r'\s')),
    TRule(T.LBRAC,      re.compile(r'\[')),
    TRule(T.RBRAC,      re.compile(r'\]')),
    TRule(T.COMMA,      re.compile(r',')),
    TRule(T.PM,         re.compile(r'(\+|\-)')),
    TRule(T.REG,        re.compile(r'(r\d+)')),
    TRule(T.SH,         re.compile(r'(shl|shr|srx|ror)')),
    TRule(T.HEX_LIT,    re.compile(r'(?:0x|0X)([A-Fa-f0-9_]+)')),
    TRule(T.HEX_LIT,    re.compile(r'([A-Fa-f0-9_]+)(?:h|H)')),
    TRule(T.DEC_LIT,    re.compile(r'([0-9]+)')),
    # Different opcode classes for instruction formats
    TRule(T.OPR_LDR,    re.compile(r'(ldr\.[bwd])')),
    TRule(T.OPR_STR,    re.compile(r'(str\.[bwd])')),
    TRule(T.OPR_MOV,    re.compile(r'(mov)')),
    TRule(T.OPR_MVT,    re.compile(r'(movt)')),
    TRule(T.OPR_ALU,    re.compile(r'(add|addc|sub|subc|and|bic|or|xor)')),
    TRule(T.OPR_OTHER,  re.compile(r'([A-Za-z0-9_]+)'))
]

# Substrings of tokens to be replaced, with rule priority as array order
# TODO: Banked moves, branches, comparisons

SYNTAX_TABLE = [
    SRule(T.IMM,    [ T.HEX_LIT ],
        lambda x: int(x[0].value, 16)),
    SRule(T.IMM,    [ T.DEC_LIT ],
        lambda x: int(x[0].value, 16)),
    SRule(T.SHIFT,  [ T.REG, T.SH, T.IMM ],
        lambda x: encode_shift(x[0], x[1], x[2])),
    SRule(T.REFI,   [ T.LBRAC, T.REG, T.PM, T.IMM, T.RBRAC ],
        lambda x: encode_refi(x[1], x[2], x[3])),
    SRule(T.REFR,   [ T.LBRAC, T.REG, T.PM, T.SHIFT, T.RBRAC ],
        lambda x: encode_regs(x[1], x[2], x[3])),
    SRule(T.REFR,   [ T.LBRAC, T.REG, T.PM, T.REG, T.RBRAC ],
        lambda x: encode_regs(x[1], x[2], { 'value': 0 })),
    # Instructon expression types
    SRule(T.INSTR,  [ T.OPR_ALU, T.REG, T.COMMA, T.REG, T.COMMA, T.SHIFT ]),
    SRule(T.INSTR,  [ T.OPR_ALU, T.REG, T.COMMA, T.REG, T.COMMA, T.REG ]),
    SRule(T.INSTR,  [ T.OPR_ALU, T.REG, T.COMMA, T.REG, T.COMMA, T.IMM ]),
    SRule(T.INSTR,  [ T.OPR_MOV, T.REG, T.COMMA, T.SHIFT ],
        lambda x: encode_mrs(0b010001, x[1], x[3])),
    SRule(T.INSTR,  [ T.OPR_MOV, T.REG, T.COMMA, T.REG ],
        lambda x: encode_mrr(0b010001, x[1], x[3])),
    SRule(T.INSTR,  [ T.OPR_MOV, T.REG, T.COMMA, T.IMM ]),
    SRule(T.INSTR,  [ T.OPR_MVT, T.REG, T.COMMA, T.IMM ]),
    SRule(T.INSTR,  [ T.OPR_LDR, T.REG, T.COMMA, T.REFI ]),
    SRule(T.INSTR,  [ T.OPR_LDR, T.REG, T.COMMA, T.REFR ]),
    SRule(T.INSTR,  [ T.OPR_STR, T.REFI, T.COMMA, T.REG ]),
    SRule(T.INSTR,  [ T.OPR_STR, T.REFR, T.COMMA, T.REG ])
]

################################################################################
# Tokenizer and parser
################################################################################

def tokenize(input: str):
    line = input.strip()
    tokens: list[Token] = []
    hasMatch = True
    while(hasMatch):
        hasMatch = False
        for p in TOKEN_TABLE:
            m = p.pattern.match(line)
            if m is None:
                continue
            hasMatch = True
            line = line[m.span()[1]:]
            if p.name is not T.WHITESPACE:
                tokens.append(Token(
                    name = p.name,
                    value = m.groups()[0] if len(m.groups()) > 0 else m.group()
                ))
            break
    if line:
        raise SyntaxError("Tokenizer ended with non-zero residue")

    hasMatch = True
    while(hasMatch):
        hasMatch = False
        for p in SYNTAX_TABLE:
            rule = p.pattern
            for j in range(len(tokens) - len(rule) + 1):
                tokenSlice = tokens[j:j+len(rule)]
                if len(tokenSlice) == 0:
                    continue
                matchOnce = reduce(lambda x, y: x and y, [
                    x == y.name for x, y in zip(rule, tokenSlice)
                ], True)
                if not matchOnce:
                    continue
                hasMatch = True
                tokens[j:j+len(rule)] = [ Token(p.name, p.parser(tokenSlice)) ]
                break
            if hasMatch:
                break
    return tokens

print(tokenize('r1 shr 3'))
