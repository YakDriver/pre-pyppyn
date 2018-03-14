import os
import platform
import shutil
import subprocess
import sys

sys.path.append('C:\git\watchmaker\src')

from watchmaker import __version__ as wam_version

THIS_DIR = os.path.dirname(os.path.realpath(__file__))

if __name__ == '__main__':
    operating_system = platform.system()
    if operating_system.lower() == 'darwin':
        operating_system = 'OSX'
    machine_type = platform.machine()

    subprocess.run(
        [
            'pyinstaller',
            '--noconfirm',
            #'--clean',
            '--name', 'watchmaker',
            '--paths', 'C:\\git\\watchmaker\\src',
            #'--paths', 'C:\\git\\watchmaker\\src\\watchmaker.egg-info',
            '--additional-hooks-dir', 'C:\\git\\pyppyn\\pyinstaller',
            # This hidden import is introduced by botocore.
            # We won't need this when this issue is resolved:
            # https://github.com/pyinstaller/pyinstaller/issues/1844
            '--hidden-import', 'html.parser',
            # This hidden import is also introduced by botocore.
            # It appears to be related to this issue:
            # https://github.com/pyinstaller/pyinstaller/issues/1935
            '--hidden-import', 'configparser',
            '--hidden-import', 'watchmaker',
            '--hidden-import', 'backoff',
            '--hidden-import', 'click',
            '--hidden-import', 'defusedxml',
            '--hidden-import', 'six',
            '--hidden-import', 'PyYAML',
            '--hidden-import', 'pypiwin32',
            '--hidden-import', 'pkg_resources',
            'watchmaker-script.py'
        ],
        check=True)

    shutil.make_archive(
        base_name=os.path.join(
            THIS_DIR, 'dist',
            'watchmaker-{v}-standalone-{os}-{m}'.format(
                v=wam_version,
                os=operating_system,
                m=machine_type)),
        format='zip',
        root_dir=os.path.join(THIS_DIR, 'dist', 'watchmaker'))
