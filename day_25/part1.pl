#!/usr/bin/env perl

use strict;
use warnings;

sub read_input {
    # read input as a 2d array of characters
    open my $fh, '<', 'input.txt' or die "Can't open input.txt: $!";
    my @grid;
    while (<$fh>) {
        chomp;
        push @grid, [split //];
    }
    close $fh;
    return @grid;
}

# Step the grid by one iteration
sub step {
    my @grid = @_;
    my $width = scalar @{$grid[0]};
    my $height = scalar @grid;

    # copy the grid
    my @new_grid;
    for my $row (@grid) {
        push @new_grid, [@$row];
    }

    # step eastward first
    for my $i (0..$height-1) {
        # move all except last normally
        for my $j (0..$width-2) {
            # can only move if next cell is not occupied
            if ($grid[$i][$j] eq '>' && $grid[$i][$j+1] eq '.') {
                $new_grid[$i][$j+1] = '>';
                $new_grid[$i][$j] = '.';
            }
        }
        # for the last, check if the first was occupied
        if ($grid[$i][$width-1] eq '>' && $grid[$i][0] eq '.') {
            $new_grid[$i][$width-1] = '.';
            $new_grid[$i][0] = '>';
        }
    }

    # update the grid after a round of eastward movement
    @grid = ();
    for my $row (@new_grid) {
        push @grid, [@$row];
    }

    # step southward
    for my $j (0..$width-1) {
        # move all except last normally
        for my $i (0..$height-2) {
            # can only move if next cell is not occupied
            if ($grid[$i][$j] eq 'v' && $grid[$i+1][$j] eq '.') {
                $new_grid[$i+1][$j] = 'v';
                $new_grid[$i][$j] = '.';
            }
        }
        # for the last, check if the first was occupied
        if ($grid[$height-1][$j] eq 'v' && $grid[0][$j] eq '.') {
            $new_grid[$height-1][$j] = '.';
            $new_grid[0][$j] = 'v';
        }
    }

    return @new_grid;
}

sub grid_eq {
    my ($grid1_ref, $grid2_ref) = @_;
    my @grid1 = @$grid1_ref;
    my @grid2 = @$grid2_ref;
    my $width = scalar @{$grid1[0]};
    my $height = scalar @grid1;
    for my $i (0..$height-1) {
        for my $j (0..$width-1) {
            return 0 if $grid1[$i][$j] ne $grid2[$i][$j];
        }
    }
    return 1;
}

sub print_grid {
    my @grid = @_;
    for my $row (@grid) {
        print join '', @$row;
        print "\n";
    }
    print "\n";

}

my @grid = read_input();
my @old_grid = step(@grid);
my $count = 0;
while (!grid_eq(\@grid, \@old_grid)) {
    @old_grid = @grid;
    @grid = step(@grid);
    $count++;
}
print $count, "\n";
