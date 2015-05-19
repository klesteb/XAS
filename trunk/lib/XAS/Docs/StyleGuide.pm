package XAS::Docs::StyleGuide;

use strict;
use warnings;

our $VERSION = '0.01';

1;

__END__
  
=head1 NAME

XAS::Docs::StyleGuide - How to write new code

=head1 STYLE

All programmers develop a style for their code. It has been suggested that
this style can even be used to determine who contributed what, for any given
project. Interesting if true. 

Code should be easy to read and have a nice flow. Any programmer should be
able to sit down and figure out what it does in a realitivly short time. This
means all the nice Perl tricks should be kept to a minimun. Remember you
may not be the only person the needs to read and understand your code.

The style that I perfer has been developed over the past 25 years. It has been 
succefully used with different languages and environments. I first started 
using it with BASICPLUS 2 on the PDP 11/70 running RSTS/E. Yeah, I have been 
around that long.

=head1 WHITESPACE

Whitespace is your friend. It is there to help you read the code. Compilers and
interperters don't care about whitespace, you should. I find the following
code hard to read.

    if($something==$this){
        do_this();
    }

A more condensed version would be like this.

    if($something==$this){do_this();}

 or

    do_this()if($something==$this);

 or that BASICPLUS 2

    10 if something = this then \
       call do_this             \
       end if
 
 or the more condensed version of that BASICPLUS 2

    10 if something = this then:call do_this:end if

Perfectly valid code for the compiler, but extremely hard for the programmer to
read. I find this much easier to read.

    if ($something == $this) {
        
        do_this();
        
    }

Which leads into the next topic.

=head1 BRACING

There are many ways to do bracing. Most of it originated in the C world and
migrated to other environments. I perfer the bracing on the same line as the 
statement with the trailing brace in the starting column of that block. Here 
are some examples.

    while ($this != $done) {
        
    }

 or

    do {
       
    } while ($this == $running);

 or

    foreach my $a (@array) {
      
    }

 or

    if ($something == $that) {
        
    } elsif {
        
    } else {
        
    }

 or even this

    {
        # some additonal code here
    }

Notice how I like to but parens around the conditional for the if 
statements. To me, it is easier to read.

=head1 INDENTION

Indenting code makes for readable code. This is a good thing. Just ask the
Python guys. Indentions should be 4 spaces. I know that some people think 
this should be handled as tabs. With the terminals tab spacing set to whatever
so the code lines up nicely. That may have been true when the Teletype 33 was 
dying and the vt100 was king. But with modern terminal emulators and fancy 
IDE editors, the tab spacing just never matchs up. Especially when two people
are using both syles in the same file. 

=head1 FORMATTING

With the usage of whitespace and indention, you can have fairly readable code.
For example a subroutine would be written like this.

    sub routine {
        my $p1 = shift;
        my $p2 = shift;
        
        if ($p1 == $p2) {
            
            do_something();
            
        }
        
    }

Which is straight forward and easy on the eyes. 

=head1 LINEWRAPPING

As everyone knows, god created the 80 by 24 character terminal and you
shall use it. I don't care if you have a 32" monitor and want to run your IDE 
in full screen mode. Line wrap will happen at character 75, unless the line 
makes sense going farther. 

=head1 VARIABLE NAMES

Variable names should make sense. A one character variable name makes sense
when used as an incremental. They should be lowercase and use "_" to denote
meaning. No CamelCase or Hungarian Notation here. Variables should be 
declared at the beginning of the routine unless there scope needs to be 
limited. For example.

    sub routine {
        my $p1 = shift;

        for (my $x = 0; $x < $p1; $x++) {
            
            do_something($x);
            
        }
        
    }
    
There is no need to declare $x for the entire routine, as it is the increment
for the loop.

=head1 SUBROUTINES

Remember that 80 by 24 terminal. Size matters. Your subroutine should fit 
within a terminal screen. If bigger, consider breaking it up.  

=head1 SUBROUTINE NAMES

Function, method, subroutine or whatever you call them, should be lowercase 
and use "_" to denote meaning. Once again, no CamelCase here. 

A leading "_" indicates a private method. Due to the nature of Perl. It is 
not easy to truly have private methods. If somebody abuses your code and 
uses your private methods, including me. It is their problem, should they 
get bitten by code changes. 

If you really thing you need them, may I suggest C#. It is a nice little 
bondage language, that will let you do all the Computer Science stuff, that 
your professors thought were important. Hey, it would even run on Linux...

=head1 PARAMETERS

If you pass parameters to your subroutines, they should be validated if they
are a public interface. A validation method is supplied and uses 
Params::Validate as the validation engine. If more the two parameters are 
passed they need to be named and the parameter name must start with a "-".
For example:

    sub routine {
        my $self = shift;
        my ($p1, $p2) = $self->validate_params(\@_, [1,1]);

    }

 or with named parameters

    sub routine {
        my $self = shift;
        my $p = $self->validate_params(\@_, {
            -p1 => 1,
            -p2 => 1,
        });

        my $p1 = $p->{p1};
        my $p2 = $p->{p2};
        
    }

 or as plain package routine

    sub routine {
        my $p = XAS::Base->validate_params(\@_, {
            -p1 => 1,
            -p2 => 1,
        });

        my $p1 = $p->{p1};
        my $p2 = $p->{p2};
        
    }
  
=head1 COMMENTS

I don't believe in excessive comments. They clutter the code and are 
usually wrong. Comments should only be used when something out of the ordinary
is about to happen. Otherwise the actual code should be sufficient. It's all
that whitespace and indenting, it really works.

=head1 DOCUMENTATION

Documentation is good. It should be at the end of the file after the code. I 
find pod intertwined with the code to be hard to read. 

=head1 TEMPLATES

There are several templates provided to help write code. Use them, they are 
boiler plate, where you just fill in the blanks and start coding. 

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2015 Kevin L. Esteb

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

