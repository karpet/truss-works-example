#!/usr/bin/env perl
use strict;
use warnings;

# This is written in a procedural style.
# It could easily be re-factored into a object oriented style
# by encapsulating all the normalization functions as methods
# in a class.

use Search::Tools::UTF8 qw( find_bad_utf8 is_valid_utf8 to_utf8 debug_bytes );
use Text::CSV_XS;
use Data::Dump qw( dump );
use DateTime::Format::Strptime;

# the encode_utf8 turns a unicode "character" back into a sequence of bytes.
my $UTF8_REPLACEMENT = Encode::encode_utf8( chr(0xfffd) );

my $DATE_PARSER = DateTime::Format::Strptime->new(
    pattern   => '%D %T %P',
    time_zone => 'US/Pacific',
);

my $DEBUG = $ENV{'DEBUG'} || 0;

sub utf8ify {
    my ($buf) = @_;
    if ( !is_valid_utf8($buf) ) {
        my $buf_copy
            = $buf;    # copy it so we can optionally sanity check later.

        #debug_bytes($buf_copy);

        while ( my $invalid_frag = find_bad_utf8($buf_copy) ) {

# The beginning of $invalid_frag is invalid sequence of bytes.
# We don't know how long the sequence is, however, so we replace every bad byte
# with the replacement sequence, and let find_bad_utf8 find the next bad sequence.
            my $valid_frag = $invalid_frag;
            $valid_frag =~ s/^./$UTF8_REPLACEMENT/;

            $buf_copy =~ s/$invalid_frag/$valid_frag/;

        }

        return to_utf8($buf_copy);
    }
    else {
        return to_utf8($buf);
    }
}

sub iso8601ify {
    my ($ts) = @_;

    #warn "parse date '$ts'";
    my $dt = $DATE_PARSER->parse_datetime($ts);
    unless ($dt) {

        #warn "Unable to parse '$ts'";

        # munge it manually
        my ( $m, $d, $y, $h, $min, $s, $p )
            = ( $ts =~ m/^(\d+)\/(\d+)\/(\d+) (\d+):(\d+):(\d+) ([AP]M)$/i );
        if ( $d && $p ) {
            $dt = DateTime->new(
                year   => ( $y < 69 ? ( 2000 + $y ) : ( 1900 + $y ) ),
                day    => $d,
                month  => $m,
                hour   => ( uc($p) eq 'AM' ? $h : ( $h + 12 ) ),
                minute => $min,
                second => $s,
            );

            #warn "manually parsed $dt";
        }
        return $ts unless $dt;
    }
    $dt->set_time_zone('US/Eastern');
    return $dt->strftime('%F %T %z');
}

sub pad_zero_zip {
    my ($zip) = @_;
    while ( length($zip) < 5 ) {
        $zip = '0' . $zip;
    }
    return $zip;
}

sub floatify {
    my ($hmsm) = @_;
    my ( $hour, $min, $sec, $mill )
        = ( $hmsm =~ m/^(\d+):(\d+):(\d+)\.(\d+)$/ );
    return
        sprintf( "%d.%d", ( ( $hour * 3600 ) + ( $min * 60 ) + $sec ),
        $mill );
}

sub normalize {
    my ( $row, $headers ) = @_;
    my $i = 0;
    my %row_hash;
    for my $cell (@$row) {
        $row_hash{ $headers->[$i] } = utf8ify($cell);
        $i++;
    }

    # if any field is undef, it was not able to be encoded as UTF-8,
    # so just warn and skip this row by returning undef
    if ( grep { !defined $row_hash{$_} } keys %row_hash ) {
        warn "Invalid encoding in row '$row'";
        return undef;
    }

    $row_hash{Timestamp}   = iso8601ify( $row_hash{Timestamp} );
    $row_hash{ZIP}         = pad_zero_zip( $row_hash{ZIP} );
    $row_hash{FullName}    = uc( $row_hash{FullName} );
    $row_hash{FooDuration} = floatify( $row_hash{FooDuration} );
    $row_hash{BarDuration} = floatify( $row_hash{BarDuration} );
    $row_hash{TotalDuration}
        = $row_hash{FooDuration} + $row_hash{BarDuration};

    return \%row_hash;
}

sub main {
    my $csv
        = Text::CSV_XS->new(
        { binary => 1, auto_diag => 1, decode_utf8 => 0, } );

    # in OO mode, we must parse headers ourselves.
    my $headers;

    # we always output utf8
    binmode STDOUT, ':utf8';

    while ( my $row = $csv->getline(*STDIN) ) {
        unless ($headers) {
            $headers = [@$row];    # dereference and re-reference in one line
            $DEBUG and warn "HEADERS: " . dump($headers);
        }
        else {
            $DEBUG and warn dump $row;

            my $normed_row = normalize( $row, $headers );
            next unless $normed_row;    # skip invalid rows

            $DEBUG and warn dump $normed_row;

            # re-assemble in proper order.
            my @new_row = map { $normed_row->{$_} } @$headers;

            $csv->say( *STDOUT, \@new_row );

        }
    }

}

# run it, C style
main();
