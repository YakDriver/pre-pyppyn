from PyInstaller.utils.hooks import copy_metadata, collect_data_files, collect_submodules

hiddenimports = (
    collect_submodules('watchmaker')
    #+ collect_submodules('pypiwin32')
    #+ collect_submodules('defusedxml')
    + collect_submodules('watchmaker.exceptions')
    + collect_submodules('watchmaker.logger')
    + collect_submodules('watchmaker.managers')
    + collect_submodules('watchmaker.static')
    + collect_submodules('watchmaker.utils')
    + collect_submodules('watchmaker.utils.urllib')
    + collect_submodules('watchmaker.workers')
)
datas = copy_metadata('watchmaker')
datas += collect_data_files('watchmaker')
datas += copy_metadata('pypiwin32')
#datas += collect_data_files('pypiwin32')
datas += copy_metadata('defusedxml')
#datas += collect_data_files('defusedxml')
datas += copy_metadata('PyYAML')
#datas += collect_data_files('PyYAML')
datas += copy_metadata('six')
datas += copy_metadata('click')
datas += copy_metadata('backoff')

#datas.append(('setup.cfg', './'))
#datas.append(('src/watchmaker', './watchmaker'))

