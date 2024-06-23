first run `git submodule update --init --recursive`

### building on windows:
- needs python3 (https://www.python.org/downloads/)
  - make sure to enable the option to add python to PATH
- needs scons (`python3 -m pip install scons`)
building windows:
- needs visual studio
building linux:
- need wsl (https://learn.microsoft.com/en-us/windows/wsl/install)
- wsl needs python3, scons, and g++ (`wsl sudo apt install python3 scons build-essential`)
building android:
- needs JDK 17
- needs android sdkmanager and build tools
  1. download cmdline tools from https://developer.android.com/studio
  2. unzip into a folder named android_sdk (so that there is a path to 'android_sdk/cmdline-tools/bin/sdkmanager.bat')
  3. set the ANDROID_HOME user env var to the path to that folder (eg. `set ANDROID_HOME=C:\android_sdk`)
  4. then run `setup_android.bat`

### building on linux:
- needs python3 and scons (`sudo apt install python3 scons`)
building windows:
- needs 'g++-mingw-w64-x86-64-posix' package (if 'g++-mingw-w64-x86-64-win32' is installed it will not compile)
building linux:
- needs g++ compiler (`sudo apt install build-essential`)
building android:
- needs 'openjdk-17-jdk' (`sudo apt install openjdk-17-jdk`)
- needs android sdkmanager and build tools
  1. download cmdline tools from https://developer.android.com/studio
  2. unzip into a folder named android_sdk (so that there is a path to 'android_sdk/cmdline-tools/bin/sdkmanager')
  3. set the ANDROID_HOME user env var to the path to that folder (eg. `export ANDROID_HOME=~/android_sdk`)
  4. then run `setup_android.bat`
