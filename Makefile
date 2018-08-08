test:
	prove t/

deps:
	cpan Search::Tools::UTF8 Text::CSV_XS Data::Dump DateTime::Format::Strptime


.PHONY: test deps
