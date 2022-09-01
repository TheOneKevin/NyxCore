#!/usr/bin/python3
import sys
import re
from os import path, system

if len(sys.argv) < 2:
    print('Usage: runtb.py <testname>')
    exit(-1)

workspaceRoot = path.dirname(path.realpath(__file__))
workspaceRoot = path.abspath(path.join(workspaceRoot, '../'))
tbPath = path.join(workspaceRoot, 'dv/tb', sys.argv[1], 'tc.sv')
buildRoot = path.join(workspaceRoot, 'build')

if not path.exists(tbPath):
    print('Error: Testbench "%s" not found'%(tbPath))
    exit(-1)

PATTERN = re.compile(r'^\/\/\s*TEST_CASES\s*=\s*(\d+)$')
TEST_CASES = 0

with open(tbPath) as f:
    matches = PATTERN.match(f.readline())
    if matches and len(matches.groups()) > 0:
        TEST_CASES = int(matches.groups()[0])
    else:
        print('Error: Cannot determine number of test cases')
        exit(-1)

print('Detected %d test cases.'%(TEST_CASES))
failed: list[str] = []
passed: int = 0
for i in range(1, TEST_CASES+1):
    print('Running test case %d...'%(i))
    result = system('make -s tb TEST_NAME=%s TEST_ID=%d NO_LINT=1'%(sys.argv[1], i))
    if result != 0:
        failed.append('Test case %d: Failed'%(i))
    else:
        failed.append('Test case %d: Pass'%(i))
        passed += 1
print('\nSummary: %d/%d tests passed.'%(passed, TEST_CASES))
