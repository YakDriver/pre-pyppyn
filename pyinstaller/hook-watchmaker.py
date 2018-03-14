from PyInstaller.utils.hooks import collect_data_files, collect_submodules

hiddenimports = (
    collect_submodules('watchmaker') +
    collect_submodules('watchmaker.exceptions') +
    collect_submodules('watchmaker.logger') +
    collect_submodules('watchmaker.managers') +
    collect_submodules('watchmaker.static') +
    collect_submodules('watchmaker.utils') +
    collect_submodules('watchmaker.utils.urllib') +
    collect_submodules('watchmaker.workers')
)
datas = collect_data_files('watchmaker')