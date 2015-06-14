package Blast::Hsp;

use warnings;
use strict;

use overload '""' => \&string;

# preference libs in same folder over @INC
use lib '../';

our $VERSION = '0.1.0';

=head1 NAME

Blast::Hsp.pm

=head1 DESCRIPTION

Class for handling blast features.

=cut

=head1 SYNOPSIS

  use Blast::Hsp;

=cut


##----------------------------------------------------------------------------##

=head1 Class ATTRIBUTES

=cut

# attributes is composite field and treated specially
our @FIELDS = qw(qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore);

##----------------------------------------------------------------------------##

=head1 Class METHODS

=head1 Constructor METHOD

=head2 new

Create a blast hsp object. Takes either a blast line or a key => value
 representation of the blast fields.

=cut

sub new{
    my $class = shift;
    my $self;

    if (@_ == 1) {              # input is string to split
        my $blast = $_[0];
        chomp($blast);
        my %blast;
        @blast{@FIELDS} = split("\t",$blast);
        $self = \%blast;
    } else {                    # input is key -> hash structure
        $self = {@_};
    }

    bless $self, $class;

    return $self;
}


=head1 Object METHODS

=cut

=head1 Accessor METHODS

Get/Set the field values.

  my $qseqid = $hsp->qseqid(); # get
  $hsp->qseqid("Some_ID"); # set
  $hsp->qseqid(undef, 1); # reset

=cut

# autodefine standard accessors for @FIELDS
foreach my $attr ( @FIELDS ) {
    my $acc = __PACKAGE__ . "::$attr";
    no strict "refs";          # So symbolic ref to typeglob works.
    
    *$acc = sub {
        my ($self, $v, $force) = @_;
        if (defined $v || $force) {
            $self->{$attr} = $v;
        }
        return $self->{$attr};
    }
}


=head2 string

Get stringified alignment. Overload for "".

=cut

# alias for backward comp.
*raw = \&string;

sub string{
    my ($self) = @_;
    my $s = join("\t", @$self{@FIELDS});
    return $s."\n";
}




##----------------------------------------------------------------------------##

=head1 AUTHOR

Thomas Hackl S<thomas.hackl@uni-wuerzburg.de>

=cut



1;
