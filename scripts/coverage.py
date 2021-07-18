import os
import sys
import importlib.util
from os import path, system

workspaceRoot = path.dirname(path.realpath(__file__))
workspaceRoot = path.abspath(path.join(workspaceRoot, '../'))
cocoRoot = path.join(workspaceRoot, 'dv/coco')
buildRoot = path.join(workspaceRoot, 'build')

print('Workspace root: %s'%(workspaceRoot))

# Generate coverage data
system('rm -f merged.dat')
system('touch merged.dat')

# Get all tests in cocoRoot
for d in os.scandir(cocoRoot):
    if not path.isdir(d):
        continue
    print('Found test: %s'%(d))
    # Import test module
    tbroot = path.join(cocoRoot, d)
    tbpath = path.join(tbroot, 'tb.py')
    tbspec = importlib.util.spec_from_file_location('tb', tbpath)
    tb = importlib.util.module_from_spec(tbspec)
    tbspec.loader.exec_module(tb)
    tests = [x for x in dir(tb) if 'cocotb.decorators.test' in str(type(getattr(tb,x)))]
    print('Found tests: %s'%(tests))
    # Execute tests
    tbmakefile = path.join(tbroot, 'Makefile')
    coveragedat = path.join(tbroot, 'coverage.dat')
    system('rm -f %s/*.dat'%(tbroot))
    for x in tests:
        if system('make -C %s COCOTB_REDUCED_LOG_FMT=1 COCOTB_LOG_LEVEL=ERROR TESTCASE=%s'%(tbroot,x)) != 0:
            print("Test failed. Unable to generate coverage, exiting.")
            sys.exit(1)
        system('verilator_coverage -write merged.dat merged.dat %s'%(coveragedat))
    # Clean up
    system('rm -f %s/*.dat'%(tbroot))
    
# Parse lcov.info
system('verilator_coverage -write-info %s merged.dat'%(path.join(buildRoot, 'coverage.info')))
fin = open(path.join(buildRoot,'coverage.info'), 'rt')
fout = open(path.join(buildRoot,'lcov.info'), 'wt')
for line in fin:
    if line.startswith('SF:'):
        abspath = path.relpath(line[3:], workspaceRoot)
        fout.write('SF:%s'%(abspath))
    else:
        fout.write(line)
fin.close()
fout.close()

# Generate html
system('rm -rf %s'%(path.join(buildRoot, 'lcov')))
system('genhtml %s -o %s -d %s'%(path.join(buildRoot,'lcov.info'), path.join(buildRoot,'lcov'), workspaceRoot))

# Clean up
system('rm -f merged.dat')
system('rm -f %s'%(path.join(buildRoot, 'coverage.info')))
