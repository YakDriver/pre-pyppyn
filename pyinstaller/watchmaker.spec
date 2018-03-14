# -*- mode: python -*-

block_cipher = None

# put this in C:\watchmaker\src\ and ran pyinstaller watchmaker.spec
# running src/dist/watchmaker/watchmaker.exe results in 'watchmaker' distribution not found unless you comment out the 
# __version__ = '1.2.3' #_extract_version('watchmaker')
# line in __init__.py from src\watchmaker
# then it runs without errors but doesn't do anything seemingly

a = Analysis(['watchmaker\\cli.py'],
             pathex=['C:\\watchmaker\\src','C:\\watchmaker\\src\\watchmaker','C:\\watchmaker\\src\\watchmaker.egg-info'
			,'C:\\watchmaker\\src\\watchmaker\\exceptions'],
             binaries=[],
             datas=[],
             hiddenimports=['watchmaker'],
             hookspath=['C:\\watchmaker\\src\\hooks'],
             runtime_hooks=[],
             excludes=[],
             win_no_prefer_redirects=False,
             win_private_assemblies=False,
             cipher=block_cipher)
pyz = PYZ(a.pure, a.zipped_data,
             cipher=block_cipher)
exe = EXE(pyz,
          a.scripts,
          exclude_binaries=True,
          name='watchmaker',
          debug=True,
          strip=False,
          upx=False,
          console=True )
coll = COLLECT(exe,
               a.binaries,
               a.zipfiles,
               a.datas,
               strip=False,
               upx=False,
               name='watchmaker')
