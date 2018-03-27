import pkg_resources
import platform
from setuptools.config import read_configuration

if __name__ == '__main__':
    operating_system = platform.system().lower()
    #print(operating_system)

    config_dict = read_configuration('setup.cfg')
    #print(config_dict["options"]["install_requires"])

    win_only_reqs = []
    reqs = []
    low_python_reqs = []

    for r in pkg_resources.parse_requirements(config_dict["options"]["install_requires"]):
        print(r.key)
        if r.marker:
            #print("Markers:",len(r.marker._markers))
            for m in r.marker._markers:
                if len(m) == 3:
                    #print(type(m[0]))
                    if str(m[0]) == 'platform_system' and str(m[2]) == 'Windows':
                        print("For Windows")
                        win_only_reqs.append(r.key)
                    elif str(m[0]) == 'python_version':
                        low_python_reqs.append(r.key)
                        print("For python ",m[1],m[2])
        else:
            reqs.append(r.key)
            #print(len(r.marker._markers))
            #print(len(r.marker._markers[0]))
            #print(r.marker._markers[0])
            #print(r.marker._markers[0][0])
    print("Windows only",win_only_reqs)
    print("Low python",low_python_reqs)
    print("Reqs",reqs)


    