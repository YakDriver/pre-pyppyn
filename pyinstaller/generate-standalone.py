import os
import platform
import shutil
import subprocess
import sys

from watchmaker import __version__ as wam_version

THIS_DIR = os.path.dirname(os.path.realpath(__file__))

if __name__ == '__main__':
    operating_system = platform.system()
    machine_type = platform.machine()

    app_name = 'watchmaker-{v}-standalone-{os}-{m}'.format(
        v=wam_version,
        os=operating_system.lower(),
        m=machine_type)

    if operating_system.lower() == 'linux':
        src_path = '/var/opt/git/watchmaker/src'
        additional_hooks = '/var/opt/git/pyppyn/pyinstaller'
    elif operating_system.lower() == 'windows':
        src_path = 'C:\\git\\watchmaker\\src'
        additional_hooks = 'C:\\git\\pyppyn\\pyinstaller'

    commands = [
        'pyinstaller',
        '--noconfirm',
        #'--clean',
        '--onefile',
        '--name', app_name,
        '--paths', src_path,
        '--additional-hooks-dir', additional_hooks,
        # This hidden import is introduced by botocore.
        # We won't need this when this issue is resolved:
        # https://github.com/pyinstaller/pyinstaller/issues/1844
        '--hidden-import', 'html.parser',
        # This hidden import is also introduced by botocore.
        # It appears to be related to this issue:
        # https://github.com/pyinstaller/pyinstaller/issues/1935
        '--hidden-import', 'configparser',
        '--hidden-import', 'watchmaker',
        '--hidden-import', 'packaging',
        '--hidden-import', 'packaging.specifiers',
        '--hidden-import', 'backoff',
        '--hidden-import', 'click',
        '--hidden-import', 'defusedxml',
        '--hidden-import', 'six',
        '--hidden-import', 'pyyaml',
        '--hidden-import', 'yaml',
        '--hidden-import', 'pkg_resources',
        'watchmaker-script.py'
    ]
    
    if operating_system.lower() == 'windows':
        insert_point = commands.index('yaml')
        commands[insert_point:insert_point] = ['--hidden-import', 'pypiwin32']

    subprocess.run(
        commands,
        check=True)

    # zip up
    """shutil.make_archive(
        base_name=os.path.join(
            THIS_DIR, 'dist',
            'watchmaker-{v}-standalone-{os}-{m}'.format(
                v=wam_version,
                os=operating_system,
                m=machine_type)),
        format='zip',
        root_dir=os.path.join(THIS_DIR, 'dist', app_name))"""
