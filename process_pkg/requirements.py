import pkg_resources
import platform
import re

if __name__ == '__main__':
    operating_system = platform.system().lower()
    print(operating_system)

    with open('setup.cfg', 'r') as cfg_file:
        data = cfg_file.read()
    #print(data)

    #reg = re.compile('\[options\]\s*install_requires\s*=([^[]*)\[')
    reg = re.compile('\[options\]([^[]*)\[')
    options = reg.search(data).group(1)
    print(options)

    reg = re.compile('install_requires\s*=\s*( {4}(.*\n))*')
    packages = reg.search(options).group(1)
    #reg = re.compile('\[options\]')
    print(packages)