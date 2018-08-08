test:
	prove t/

deps:
	cpan Search::Tools::UTF8 Text::CSV_XS Data::Dump DateTime::Format::Strptime

demo:
	perl norm-csv.pl < sample-with-broken-utf8.csv
	perl norm-csv.pl < sample.csv


.PHONY: test deps
