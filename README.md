Truss example project
----------------------

This Perl project uses some CPAN modules to test and coerce UTF-8 and parse CSV files.

## Depedencies

Requires a modern (> 5.10) Perl version.

To install the necessary CPAN modules, try:

```
% make deps
```

## Tests

To run the test suite, try:

```
% make test
```

## Usage

The `norm-csv.pl` script expects CSV-formatted text on stdin, and will output
CSV-formatted text to stdout. Example:

```
% perl norm-csv.pl < sample.csv > sample-output.csv
```
