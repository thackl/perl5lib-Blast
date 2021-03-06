package Blast::Parser;

use warnings;
use strict;

use Blast::Hsp;

our $VERSION = '0.2.0';

=head1 NAME

Blast::Parser.pm

=head1 DESCRIPTION

Parser module for Blast tsv files.

=cut

=head1 SYNOPSIS

=cut

=head1 Class Attributes

=cut

my $BUFFER; # line buffer

=head1 Constructor METHOD

=head2 new

Initialize a gff parser object. Takes parameters in key => value format.

  fh => \*STDIN,
  file => undef,
  is => undef,
  mode => '<',   # read,
                 # '+>': read+write (clobber file first)
                 # '+<': read+write (append)
                 # '>' : write (clobber file first)
                 # '>>': write (append)
=back

=cut

sub new{
    my $class = shift;

    my $self = {
        # defaults
        fh => \*STDIN,
        file => undef,
        mode => '<',
        fields => [qw(qseqid sseqid pident length mismatch
                     gapopen qstart qend sstart send evalue
                     bitscore)],  # default fields -outfmt 6/7
        # overwrite defaults
        @_,
    };

    # open file in read/write mode
    if ($self->{file}) {
        my $fh;
        open ( $fh , $self->{mode}, $self->{file}) or die sprintf("%s: %s, %s",(caller 0)[3],$self->{file}, $!);
        $self->{fh} = $fh;
    }

    bless $self, $class;

    Blast::Hsp->Fields(@{$self->{fields}});

    return $self;

}

sub DESTROY{
    # just to be sure :D
    my $self = shift;
    close $self->fh if $self->fh;
}








############################################################################


=head1 Object METHODS

=cut

=head2 next_hsp

Return next HSP (meeting conditions).

=cut

sub next_hsp{
    my ($self) = @_;
    my $fh = $self->{fh};

    while ( my $l = _read_buffer() // <$fh> ) {
        next if $l =~ /^#/;

        # return gff hsp object
        my $hsp = Blast::Hsp->new($l);
        $self->eval_hsp($hsp) || next;
        return $hsp;
    }
    return;
}

=head2 next_query_hsp

Return next HSP from same query (meeting conditions).

NOTE: currently only works on -outfmt 7 derivates.

=cut

sub next_query_hsp{
    my ($self) = @_;
    my $fh = $self->{fh};

    while ( my $l = _read_buffer() // <$fh> ) {
        if ($l =~ /^#/){
            $BUFFER = $l;
            return;
        }

        # return gff hsp object
        my $hsp = Blast::Hsp->new($l);
        $self->eval_hsp($hsp) || next;
        return $hsp;
    }
    return;
}


=head2 next_query

NOTE: only works on outfmt 7

=cut

sub next_query{
    my ($self) = @_;
    my $fh = $self->{fh};
    my $head = undef;
    OUTER: while (my $l = _read_buffer() // <$fh>) {
        next unless $l =~ /^#/;
        $head = $l;
        while (<$fh>) {
            if (/^#/) {
                $head.=$_
            }else {
                $BUFFER = $_;
                last OUTER;
            }
        }
    }
    #eof
    return $head;
}


=head2 tell

Return the byte offset of the current append filehandle position

=cut

sub tell{
    return tell($_[0]->{fh});
}


############################################################################

=head1 Accessor METHODS

=head2 fh

Get/Set the file handle.

=cut

sub fh{
    my ($self, $fh) = @_;
    $self->{fh} = $fh if $fh;
    return $self->{fh};
}


=head2 seek

Set the filehandle to the specified byte offset. Takes two
optional arguments POSITION (default 0), WHENCE (default 0), see perl "seek" for more.
Returns 'true' on success.

NOTE: this operation only works on real files, not on STDIN.

=cut

sub seek{
	my ($self, $offset, $whence) = (@_, 0, 0);
	return seek($self->fh, $offset, $whence);
}


=head2 add_condition/reset_conditions

Only return hsps from parser satisfying custom condition using a predefined
function. The function is called with the hsp object as first
parameter. Only hsps that evaluate to TRUE are returned by the parser.

  # customize parser to only return 'gene' hsps from '-' strand.
  $gp->add_condition(sub{
             my $hsp = $_[0];
             return $hsp->type eq 'gene' && $hsp->strand eq '-';
         });


  # deactivate conditions
  $gp->reset_conditions();

=cut

sub add_condition{
    my ($self, $cond) = @_;

    if ($cond && ref($cond) eq 'CODE') {
        $self->{cond} ||= [];
        push @{$self->{cond}}, $cond;
    } else {
        die (((caller 0)[3])." requires condition as CODE reference!\n");
    }
    return $self->{cond};
}

sub reset_conditions{
    my ($self, $cond) = @_;
    $self->{cond} = [];
}

=head2 eval_hsp

Returns TRUE if hsp matches "conditions" set for parser.

  $gp->eval_hsp($hsp)

=cut

sub eval_hsp{
    my ($self, $hsp) = @_;
    if ($self->{cond}) {
        foreach ( @{$self->{cond}} ){ $_->($hsp, $self) || return; }
    }
    return 1;
}

##----------------------------------------------------------------------------##

=head1 Private METHODS

=head2 _read_buffer

Get buffer content, clear buffer

=cut

sub _read_buffer{
    if ( defined($BUFFER) ){
        my $buffer = $BUFFER;
        $BUFFER = undef;
        return $buffer;
    }else {
        return;
    }
}

=head1 AUTHOR

Thomas Hackl S<thomas.hackl@uni-wuerzburg.de>

=cut



1;
