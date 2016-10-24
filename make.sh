#!/bin/bash

### set client root folder and perform everything there
ROOT="HistoGlobe_client"
## TODO: change fully

# ---------------------------------------------------------------------------- #
### set project

PROJECT=master

# ---------------------------------------------------------------------------- #
### clean or create build directory
if [ ! -d "$ROOT/build" ]; then
    mkdir $ROOT/build
else
    rm $ROOT/build/*
fi

# ---------------------------------------------------------------------------- #
### I have no idea what this is doing ...

rosetta --jsOut "$ROOT/build/default_config.js" \
        --jsFormat "flat" \
        --jsTemplate $'var HGConfig;\n(function() {\n<%= preamble %>\nHGConfig = <%= blob %>;\n})();' \
        --cssOut "$ROOT/build/default_config.less" \
        --cssFormat "less" $ROOT/config/common/default.rose

rosetta --jsOut "$ROOT/build/config.js" \
        --jsFormat "flat" \
        --jsTemplate $'(function() {\n<%= preamble %>\n $.extend(HGConfig, <%= blob %>);\n})();' \
        --cssOut "$ROOT/build/config.less" \
        --cssFormat "less" $ROOT/config/$PROJECT/style.rose

# ---------------------------------------------------------------------------- #
### compile all coffeescript files to javascript and put into build folder
cFiles=$(find $ROOT/script -name '*.coffee')
coffee -c -o $ROOT/build $cFiles

### copy all third-party libs into build folder
find $ROOT/script/third-party -name '*.js' -exec cp {} $ROOT/build \;

### uglify all javascript files and compile to a single min
# jFiles=$(find $ROOT/build -name '*.js')
# uglifyjs $jFiles -o $ROOT/script/histoglobe.min.js #-mc

### move project stylesheet into main style folder
lessc --no-color -x $ROOT/config/$PROJECT/main.less $ROOT/style/histoglobe.min.css

### ??!??!?!!!?!?!!!?!??!?!!!?!?!???!?!?!???!??!!!?!??!!?!??!??
# sed -i "1s/.*/<?php \$config_path = '$PROJECT'; ?>/" $ROOT/config.php
