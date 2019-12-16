#!python
import os
from shutil import copyfile

with open('crawl.rc') as f1:
    with open('pillardance/pillardance.lua') as f2:
        with open('out.rc', 'w') as f3:
            f3.write(f1.read())
            f3.write('\n{\n')
            f3.write(f2.read())
            f3.write('\n}\n')

copyfile('out.rc', os.environ['HOME'] + '/.crawlrc')
