#***********************************************************************
#
# Name: csv_column_object.pm
#
# $Revision: 1498 $
# $URL: svn://10.36.148.185/Open_Data/Tools/csv_column_object.pm $
# $Date: 2019-09-17 11:57:26 -0400 (Tue, 17 Sep 2019) $
#
# Description:
#
#   This file defines an object to handle a CSV file column information
# (e.g. heading, content type, row counts). The object contains methods
# to set and read the object attributes.
#
# Public functions:
#     Set_CSV_Column_Object_Debug
#
# Class Methods
#    new - create new object instance
#    consistent_value_table - get the consistent value table
#    first_data - set/get the first data cell value
#    heading - get/set csv column heading
#    increment_non_blank_cell_count - increment non_blank_cell_count value
#    max - get/set maximum value (for numeric and date columns only)
#    min - get/set minimum value (for numeric and date columns only)
#    non_blank_cell_count - get/set non_blank_cell_count value
#    sum - get or add to the column sum (for numeric and date columns only)
#    type - get/set column content type value
#    valid_heading - get/set flag if this column has a valid
#      data dictionary heading
#
# Terms and Conditions of Use
# 
# Unless otherwise noted, this computer program source code
# is covered under Crown Copyright, Government of Canada, and is 
# distributed under the MIT License.
# 
# MIT License
# 
# Copyright (c) 2017 Government of Canada
# 
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense, 
# and/or sell copies of the Software, and to permit persons to whom the 
# Software is furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
# OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR 
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR 
# OTHER DEALINGS IN THE SOFTWARE.
# 
#***********************************************************************

package csv_column_object;

use strict;
use warnings;

#***********************************************************************
#
# Export package globals
#
#***********************************************************************
BEGIN {
    use Exporter   ();
    use vars qw($VERSION @ISA @EXPORT);

    @ISA     = qw(Exporter);
    @EXPORT  = qw(Set_CSV_Column_Object_Debug);
    $VERSION = "1.0";
}

#***********************************************************************
#
# File Local variable declarations
#
#***********************************************************************

my ($debug) = 0;

#********************************************************
#
# Name: Set_CSV_Column_Object_Debug
#
# Parameters: this_debug - debug flag
#
# Description:
#
#   This function sets the package debug flag.
#
#********************************************************
sub Set_CSV_Column_Object_Debug {
    my ($this_debug) = @_;

    #
    # Copy debug flag to global
    #
    $debug = $this_debug;
}

#********************************************************
#
# Name: new
#
# Parameters: heading - column heading
#
# Description:
#
#   This function creates a new csv_column_object item and
# initializes its data items.
#
#********************************************************
sub new {
    my ($class, $heading) = @_;
    
    my ($self) = {};
    my (%consistent_value_table);

    #
    # Bless the reference as a csv_column_object class item
    #
    bless $self, $class;
    
    #
    # Save arguments as object data items and initialize
    # other object data.
    #
    $self->{"consistent_value_table"} = \%consistent_value_table;
    $self->{"first_data"} = 1;
    $self->{"heading"} = $heading;
    $self->{"max"} = undef;
    $self->{"min"} = undef;
    $self->{"non_blank_cell_count"} = 0;
    $self->{"sum"} = 0;
    $self->{"type"} = "";
    $self->{"valid_heading"} = 1;
    
    #
    # Print object details
    #
    print "New CSV column object, Heading: $heading\n" if $debug;

    #
    # Return reference to object.
    #
    return($self);
}
    
#********************************************************
#
# Name: consistent_value_table
#
# Parameters: self - class reference
#
# Description:
#
#   This function returns the address of the consistent value
# table for this column object.
#
#********************************************************
sub consistent_value_table {
    my ($self) = @_;

    #
    # Return address of hash table
    #
    return($self->{"consistent_value_table"});
}

#********************************************************
#
# Name: first_data
#
# Parameters: self - class reference
#             value - value (optional)
#
# Description:
#
#   This function either sets or returns the first_data
# attribute of the object. If a value is supplied,
# it is saved in the object. If no value is supplied,
# the current value is returned.
#
#********************************************************
sub first_data {
    my ($self, $value) = @_;
   
    #
    # Was a value supplied ?
    #
    if ( defined($value) ) {
        $self->{"first_data"} = $value;
    }
    else {
        return($self->{"first_data"});
    }
}

#********************************************************
#
# Name: heading
#
# Parameters: self - class reference
#             heading - column heading (optional)
#
# Description:
#
#   This function either sets or returns the heading
# attribute of the object. If a value is supplied,
# it is saved in the object. If no value is supplied,
# the current value is returned.
#
#********************************************************
sub heading {
    my ($self, $heading) = @_;

    #
    # Was a value supplied ?
    #
    if ( defined($heading) ) {
        $self->{"heading"} = $heading;
    }
    else {
        return($self->{"heading"});
    }
}

#********************************************************
#
# Name: increment_non_blank_cell_count
#
# Parameters: self - class reference
#
# Description:
#
#   This function increments the non-blank cell
# count attribute of the object.
#
#********************************************************
sub increment_non_blank_cell_count {
    my ($self) = @_;

    #
    # Increment the value
    #
    $self->{"non_blank_cell_count"}++;
}

#********************************************************
#
# Name: max
#
# Parameters: self - class reference
#             value - cell value (optional)
#
# Description:
#
#   This function either sets or returns the maximum column
# value attribute of the object. If a value is supplied,
# it is saved in the object. If no value is supplied,
# the current value is returned.
#
#********************************************************
sub max {
    my ($self, $value) = @_;

    #
    # Was a value supplied ?
    #
    if ( defined($value) ) {
        $self->{"max"} = $value;
    }
    else {
        return($self->{"max"});
    }
}

#********************************************************
#
# Name: min
#
# Parameters: self - class reference
#             value - cell value (optional)
#
# Description:
#
#   This function either sets or returns the minimum column
# value attribute of the object. If a value is supplied,
# it is saved in the object. If no value is supplied,
# the current value is returned.
#
#********************************************************
sub min {
    my ($self, $value) = @_;

    #
    # Was a value supplied ?
    #
    if ( defined($value) ) {
        $self->{"min"} = $value;
    }
    else {
        return($self->{"min"});
    }
}

#********************************************************
#
# Name: non_blank_cell_count
#
# Parameters: self - class reference
#             non_blank_cell_count - cell count (optional)
#
# Description:
#
#   This function either sets or returns the non-blank cell
# count attribute of the object. If a value is supplied,
# it is saved in the object. If no value is supplied,
# the current value is returned.
#
#********************************************************
sub non_blank_cell_count {
    my ($self, $non_blank_cell_count) = @_;

    #
    # Was a value supplied ?
    #
    if ( defined($non_blank_cell_count) ) {
        $self->{"non_blank_cell_count"} = $non_blank_cell_count;
    }
    else {
        return($self->{"non_blank_cell_count"});
    }
}

#********************************************************
#
# Name: sum
#
# Parameters: self - class reference
#             value - number (optional)
#
# Description:
#
#   This function either adds to the column sumation value
# or returns the column sum attribute of the object. This
# method only applies to numeric column types, if the type
# is not numeric, no action is taken.
# If a value is supplied, it is added to the current sum.
# If no value is supplied, the current value is returned.
#
#********************************************************
sub sum {
    my ($self, $value) = @_;

    #
    # Is the column type numeric?
    #
    if ( $self->{"type"} eq "numeric" ) {
        #
        # Was a value supplied ?
        #
        if ( defined($value) ) {
            $self->{"sum"} += $value;
        }
        else {
            return($self->{"sum"});
        }
    }
    else {
        return(0);
    }
}

#********************************************************
#
# Name: type
#
# Parameters: self - class reference
#             type - column type (optional)
#
# Description:
#
#   This function either sets or returns the content type
# attribute of the object. If a value is supplied,
# it is saved in the object. If no value is supplied,
# the current value is returned.
#
#********************************************************
sub type {
    my ($self, $type) = @_;

    #
    # Was a value supplied ?
    #
    if ( defined($type) ) {
        $self->{"type"} = $type;
    }
    else {
        return($self->{"type"});
    }
}

#********************************************************
#
# Name: valid_heading
#
# Parameters: self - class reference
#             value - value (optional)
#
# Description:
#
#   This function either sets or returns the valid_heading
# attribute of the object. If a value is supplied,
# it is saved in the object. If no value is supplied,
# the current value is returned.
#
#********************************************************
sub valid_heading {
    my ($self, $value) = @_;

    #
    # Was a value supplied ?
    #
    if ( defined($value) ) {
        $self->{"valid_heading"} = $value;
    }
    else {
        return($self->{"valid_heading"});
    }
}

#***********************************************************************
#
# Mainline
#
#***********************************************************************

#
# Return true to indicate we loaded successfully
#
return 1;

