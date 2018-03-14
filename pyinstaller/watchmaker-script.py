#!c:\git\watchmaker\venv\scripts\python.exe
# EASY-INSTALL-ENTRY-SCRIPT: 'watchmaker','console_scripts','watchmaker'
# this was copied from virtual environment Scripts folder after installing watchmaker
# for example:
# cd C:\git\watchmaker
# pip install --index-url "$PYPI_URL" --editable .
# copy C:\git\watchmaker\venv\Scripts\watchmaker-script.py C:\git\pyppyn
__requires__ = 'watchmaker'
import re
import sys
from pkg_resources import load_entry_point

if __name__ == '__main__':
    sys.argv[0] = re.sub(r'(-script\.pyw?|\.exe)?$', '', sys.argv[0])
    sys.exit(
        load_entry_point('watchmaker', 'console_scripts', 'watchmaker')()
    )
