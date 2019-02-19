#!/bin/sh
elm make elm/Index.elm --output=.work/index.js
# elm make --optimize elm/Index.elm --output=.work/index.js
uglifyjs .work/index.js --compress 'pure_funcs="Elm.Index.init,F2,F3,F4,F5,F6,F7,F8,F9,A2,A3,A4,A5,A6,A7,A8,A9",pure_getters,keep_fargs=false,unsafe_comps,unsafe' | uglifyjs --mangle --output=static/js/index.min.js