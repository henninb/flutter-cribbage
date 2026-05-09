#!/bin/sh

flutter test --coverage
lcov --summary coverage/lcov.info
genhtml coverage/lcov.info -o coverage/html
xdg-open coverage/html/index.html
echo xdg-open coverage/html/index.html

exit 0
