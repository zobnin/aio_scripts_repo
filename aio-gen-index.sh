#!/bin/sh

echo [

last_file=`ls -1 | tail -1`

for f in *.lua; do
    echo {
    echo " \"file\": \"$f\","
    cat $f | tr -d "\r" | grep '^--\s*[a-zA-Z]*\s*=' | sed -e 's/\ *=\ */": /' -e 's/^--\ */ "/' -e 's/$/,/' | grep -v 'arguments_'
    echo -n " \"md5sum\": "\"
    md5sum $f | cut -d ' ' -f 1 | sed 's/$/"/'

    if [[ $f = $last_file ]]; then
        echo }
    else
        echo },
    fi
done

echo ]
