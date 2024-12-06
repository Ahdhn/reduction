# reduction [![Windows](https://github.com/Ahdhn/reduction/actions/workflows/Windows.yml/badge.svg)](https://github.com/Ahdhn/reduction/actions/workflows/Windows.yml) [![Ubuntu](https://github.com/Ahdhn/reduction/actions/workflows/Ubuntu.yml/badge.svg)](https://github.com/Ahdhn/reduction/actions/workflows/Ubuntu.yml)


## Build 
You might first need to change the project name in the `CMakeLists.txt` and the folder name and fill in any `TODO`. Then simply run 

```
mkdir build
cd build 
cmake ..
```

Depending on the system, this will generate either a `.sln` project on Windows or a `make` file for a Linux system. 

## Results 
Sample results on Windows with RTX 4090 

```
>> reduction.exe 10000000

>> res= 12499999, max_val= 12499999
>> res= 1276077248, sum_val= 1276077248
>> res= 2500000, min_val= 2500000
```

```
>> reduction.exe 50000000

>> res= 62499999, max_val= 62499999
>> res= 1937160128, sum_val= 1937160128
>> res= 12500000, min_val= 12500000
```
