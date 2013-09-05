#***********************************************************************
#
# Name:   interop_testcases.pm
#
# $Revision: 6311 $
# $URL: svn://10.36.20.226/trunk/Web_Checks/Interop_Check/Tools/interop_testcases.pm $
# $Date: 2013-06-26 11:04:08 -0400 (Wed, 26 Jun 2013) $
#
# Description:
#
#   This file contains routines that handle Interoperability
# testcase descriptions.
#
# Public functions:
#     Interop_Testcase_Language
#     Interop_Testcase_Debug
#     Interop_Testcase_Description
#     Interop_Testcase_Read_URL_Help_File
#     Interop_Testcase_URL
#
# Terms and Conditions of Use
#
# Unless otherwise noted, this computer program source code
# is covered under Crown Copyright, Government of Canada, and is
# distributed under the MIT License.
#
# MIT License
#
# Copyright (c) 2011 Government of Canada
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

package interop_testcases;

use strict;

#***********************************************************************
#
# Export package globals
#
#***********************************************************************
BEGIN {
    use Exporter   ();
    use vars qw($VERSION @ISA @EXPORT);

    @ISA     = qw(Exporter);
    @EXPORT  = qw(Interop_Testcase_Language
                  Interop_Testcase_Debug
                  Interop_Testcase_Description
                  Interop_Testcase_Read_URL_Help_File
                  Interop_Testcase_URL
                  );
    $VERSION = "1.0";
}

#***********************************************************************
#
# File Local variable declarations
#
#***********************************************************************

my ($debug) = 0;

#
#******************************************************************
#
# String table for testcase help URLs
#
#******************************************************************
#

my (%testcase_url_en, %testcase_url_fr);

#
# Default URLs to English
#
my ($url_table) = \%testcase_url_en;

#
# String tables for testcase ID to testcase descriptions
#
my (%testcase_description_en) = (
#
# Standard on Web Interoperability checkpoints
#
"SWI_B",     "SWI_B: Web feed requirements",
"SWI_C",     "SWI_C: Character Encoding Requirements",
"SWI_D",     "SWI_D: Mark-up Language Requirements",
);

my (%testcase_description_fr) = (
#
# Standard on Web Interoperability checkpoints
#
"SWI_B",     "SWI_B: Exigences relatives aux fils de nouvelles",
"SWI_C",     "SWI_C: Exigences relatives � l'encodage des caract�res",
"SWI_D",     "SWI_D: Exigences relatives au langage de balisage",
);

#
# Create reverse table, indexed by description
#
my (%reverse_testcase_description_en) = reverse %testcase_description_en;
my (%reverse_testcase_description_fr) = reverse %testcase_description_fr;
my ($reverse_testcase_description_table) = \%reverse_testcase_description_en;

#
# Default messages to English
#
my ($testcase_description_table) = \%testcase_description_en;

#***********************************************************************
#
# Name: Interop_Testcase_Debug
#
# Parameters: this_debug - debug flag
#
# Description:
#
#   This function sets the package global debug flag.
#
#***********************************************************************
sub Interop_Testcase_Debug {
    my ($this_debug) = @_;

    #
    # Copy debug value to global variable
    #
    $debug = $this_debug;
}

#**********************************************************************
#
# Name: Interop_Testcase_Language
#
# Parameters: language
#
# Description:
#
#   This function sets the language of error messages generated
# by this module.
#
#***********************************************************************
sub Interop_Testcase_Language {
    my ($language) = @_;

    #
    # Check for French language
    #
    if ( $language =~ /^fr/i ) {
        print "Interop_Testcase_Language, language = French\n" if $debug;
        $testcase_description_table = \%testcase_description_fr;
        $reverse_testcase_description_table = \%reverse_testcase_description_fr;
        $url_table = \%testcase_url_fr;
    }
    else {
        #
        # Default language is English
        #
        print "Interop_Testcase_Language, language = English\n" if $debug;
        $testcase_description_table = \%testcase_description_en;
        $reverse_testcase_description_table = \%reverse_testcase_description_en;
        $url_table = \%testcase_url_en;
    }
}

#**********************************************************************
#
# Name: Interop_Testcase_Read_URL_Help_File
#
# Parameters: filename - path to help file
#
# Description:
#
#   This function reads a testcase help file.  The file contains
# a list of testcases and the URL of a help page or standard that
# relates to the testcase.  A language field allows for English & French
# URLs for the testcase.
#
#**********************************************************************
sub Interop_Testcase_Read_URL_Help_File {
    my ($filename) = @_;

    my (@fields, $tcid, $lang, $url);

    #
    # Clear out any existing testcase/url information
    #
    %testcase_url_en = ();
    %testcase_url_fr = ();

    #
    # Check to see that the help file exists
    #
    if ( !-f "$filename" ) {
        print "Error: Missing URL help file\n" if $debug;
        print " --> $filename\n" if $debug;
        return;
    }

    #
    # Open configuration file at specified path
    #
    print "Interop_Testcase_Read_URL_Help_File Openning file $filename\n" if $debug;
    if ( ! open(HELP_FILE, "$filename") ) {
        print "Failed to open file\n" if $debug;
        return;
    }

    #
    # Read file looking for testcase, language and URL
    #
    while (<HELP_FILE>) {
        #
        # Ignore comment and blank lines.
        #
        chop;
        if ( /^#/ ) {
            next;
        }
        elsif ( /^$/ ) {
            next;
        }

        #
        # Split the line into fields.
        #
        @fields = split(/\s+/, $_, 3);

        #
        # Did we get 3 fields ?
        #
        if ( @fields == 3 ) {
            $tcid = $fields[0];
            $lang = $fields[1];
            $url  = $fields[2];

            #
            # Do we have a testcase to match the ID ?
            #
            if ( defined($testcase_description_en{$tcid}) ) {
                print "Add Testcase/URL mapping $tcid, $lang, $url\n" if $debug;

                #
                # Do we have an English URL ?
                #
                if ( $lang =~ /eng/i ) {
                    $testcase_url_en{$tcid} = $url;
                    $reverse_testcase_description_en{$url} = $tcid;
                }
                #
                # Do we have a French URL ?
                #
                elsif ( $lang =~ /fra/i ) {
                    $testcase_url_fr{$tcid} = $url;
                    $reverse_testcase_description_fr{$url} = $tcid;
                }
                else {
                    print "Unknown language $lang\n" if $debug;
                }
            }
        }
        else {
            print "Line does not contain 3 fields, ignored: \"$_\"\n" if $debug;
        }
    }

    #
    # Close configuration file
    #
    close(HELP_FILE);
}

#**********************************************************************
#
# Name: Interop_Testcase_URL
#
# Parameters: key - testcase id
#
# Description:
#
#   This function returns the value in the testcase URL
# table for the specified key.
#
#**********************************************************************
sub Interop_Testcase_URL {
    my ($key) = @_;

    #
    # Do we have a string table entry for this key ?
    #
    print "Interop_Testcase_URL, key = $key\n" if $debug;
    if ( defined($$url_table{$key}) ) {
        #
        # return value
        #
        print "value = " . $$url_table{$key} . "\n" if $debug;
        return ($$url_table{$key});
    }
    #
    # Was the testcase description provided rather than the testcase
    # identifier ?
    #
    elsif ( defined($$reverse_testcase_description_table{$key}) ) {
        #
        # return value
        #
        $key = $$reverse_testcase_description_table{$key};
        print "value = " . $$url_table{$key} . "\n" if $debug;
        return ($$url_table{$key});
    }
    else {
        #
        # No string table entry, either we are missing a string or
        # we have a typo in the key name.
        #
        return;
    }
}

#**********************************************************************
#
# Name: Interop_Testcase_Description
#
# Parameters: key - testcase id
#
# Description:
#
#   This function returns the value in the testcase description
# table for the specified key.  If there is no entry in the table an error
# string is returned.
#
#**********************************************************************
sub Interop_Testcase_Description {
    my ($key) = @_;

    #
    # Do we have a string table entry for this key ?
    #
    if ( defined($$testcase_description_table{$key}) ) {
        #
        # return value
        #
        return ($$testcase_description_table{$key});
    }
    else {
        #
        # No string table entry, either we are missing a string or
        # we have a typo in the key name.
        #
        return ("*** No string for $key ***");
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


