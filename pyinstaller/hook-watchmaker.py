from PyInstaller.utils.hooks import copy_metadata, collect_data_files, collect_submodules
import os

hiddenimports = (
    collect_submodules('watchmaker')
    #+ collect_submodules('pypiwin32')
    #+ collect_submodules('defusedxml')
    #+ collect_submodules('watchmaker.exceptions')
    #+ collect_submodules('watchmaker.logger')
    #+ collect_submodules('watchmaker.managers')
    #+ collect_submodules('watchmaker.static')
    #+ collect_submodules('watchmaker.utils')
    #+ collect_submodules('watchmaker.utils.urllib')
    #+ collect_submodules('watchmaker.workers')
)
datas = copy_metadata('watchmaker')
datas += collect_data_files('watchmaker')
datas += copy_metadata('defusedxml')
datas += copy_metadata('PyYAML')
datas += copy_metadata('six')
datas += copy_metadata('click')
datas += copy_metadata('backoff')

#datas += copy_metadata('watchmaker.exceptions')
#datas += collect_data_files('watchmaker.exceptions')
#datas += copy_metadata('watchmaker.logger')
#datas += collect_data_files('watchmaker.logger')
#datas += copy_metadata('watchmaker.managers')
#datas += collect_data_files('watchmaker.managers')
#datas += copy_metadata('watchmaker.static')
#datas += collect_data_files('watchmaker.static')
#datas += copy_metadata('watchmaker.utils')
#datas += collect_data_files('watchmaker.utils')
#datas += copy_metadata('watchmaker.utils.urllib')
#datas += collect_data_files('watchmaker.utils.urllib')
#datas += copy_metadata('watchmaker.workers')
#datas += collect_data_files('watchmaker.workers')

if operating_system.lower() == 'linux':
    datas.append(('/var/opt/git/watchmaker/src/watchmaker/static', './watchmaker/static'))
else:
    datas += copy_metadata('pypiwin32')
    datas.append(('C:/git/watchmaker/src/watchmaker/static', './watchmaker/static'))


