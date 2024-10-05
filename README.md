# V-lang libmodbus wrapper

## requirement

you have to compile libmodbus

and you should double check this flags in the `modbus.v` file

```v
#flag -I/usr/include/modbus -lmodbus
#include "modbus.h"
```

how to get those param on my OS just run

`pkg-config --cflags --libs libmodbus`
