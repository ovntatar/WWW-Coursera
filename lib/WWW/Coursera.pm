package WWW::Coursera;

use 5.006;
use strict;
use warnings;

use WWW::Mechanize;
use HTTP::Cookies;
use WWW::Mechanize::Link;
use Carp qw(croak);

=head1 NAME

WWW::Coursera - Downloading material (video, text, pdf ...) from Coursera.org online classes.

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

It scrapes the course index page to get lecture names, and then downloads the related
materials.

Code snippet.

 use WWW::Coursera;
 my $initial = WWW::Coursera->new( username => 'xxxxx', password => 'xxxx', course => 'xxxx');
 $initial->set_localdir("/home/xxxxx/Perl/Coursera/tmp");
 $initial->get_all();

=head1 SUBROUTINES/METHODS

=head2 new

Object construction with user authorization and course name parameter. 

=cut

sub new {
    my $class = shift;
    croak "Illegal parameter list has odd number of values" if @_ % 3;
    my %params = @_;
    my $self = { %params, @_ };
    bless $self, $class;

    for my $required (qw{ username password course  }) {
	croak "Required parameter '$required' missing in constructor" unless exists $params{$required};  
    }    
    return $self;
}

=head2 set_localdir

Set download folder by set $inizial->set_localdir("OS_FOLDER");

=cut

sub set_localdir {
    
    my( $self, $set_localdir) = @_;
    
    if (-d "$set_localdir") {
		$self->{set_localdir}=$set_localdir;
		return $self->{set_localdir};
	} else {
		croak "Directory $set_localdir does'n exist";
	}
}


=head2 set_cookie

In the source code below, will create a cookie named cookie.txt to store header information.

=cut

sub set_cookie {
	
    my( $self) = @_;
  
    my $bot = WWW::Mechanize->new();
    $bot->agent_alias( 'Linux Mozilla' );
    $bot->cookie_jar( HTTP::Cookies->new(file => "cookie.txt", autosave => 1, ignore_discard => 1 ) );
    $self->{bot}=$bot;
    
    croak "Mechanize object does'n exist!" unless $self->{bot};
    return $self->{bot};
}

=head2 set_csrftoken

Filter csrf_token key from the cookie.txt file.

=cut

sub set_csrftoken {
    my( $self) = @_;
    
    my $response = $self->{bot}->post("https://class.coursera.org/$self->{course}/lecture/index");
    my $key=$self->{bot}->cookie_jar()-> {"COOKIES"}-> {"class.coursera.org"}-> {"/$self->{course}"}-> {"csrf_token"}->[1];
    $self->{key}=$key;
    
    croak "COOKIES key does'n exist!" unless $self->{key};
    return $self->{key};
}

=head2 get_session

Send a new html request to get session cokkie token and save session key in global variable.

=cut

sub get_session {
	
    my( $self) = @_;
		
    $self->{bot}->add_header('Cookie' => "csrftoken=$self->{key}");
    $self->{bot}->add_header('Referer' => 'https://www.coursera.org');
    $self->{bot}->add_header('X-CSRFToken' => "$self->{key}");
    $self->{bot}->add_header('X-Requested-With' => 'XMLHttpRequest' );
    
    my $response=$self->{bot}->post('https://www.coursera.org/maestro/api/user/login', [ email_address => "$self->{username}",  password => "$self->{password}"]);
    $self->{bot}->get("https://class.coursera.org/$self->{course}/auth/auth_redirector?type=login&subtype=normal&email=&visiting=index");
    my $session=$self->{bot}->cookie_jar()-> {"COOKIES"}-> {"class.coursera.org"}-> {"/$self->{course}"}-> {"session"}->[1];
    $self->{session}=$session;
    
    croak "Session key does'n exist!" unless $self->{session};
    return $self->{session};
}

=head2 get_links

Extract links from course index page.

=cut

sub get_links {
    my( $self) = @_;
    
    $self->{bot}->get("https://class.coursera.org/$self->{course}/auth/auth_redirector?type=login&subtype=normal&email=&visiting=index");
    my $session=$self->{bot}->cookie_jar()-> {"COOKIES"}-> {"class.coursera.org"}-> {"/$self->{course}"}-> {"session"}->[1];
    $self->{bot}->add_header("Cookie" => "csrf_token=$self->{key}");
    $self->{bot}->add_header("session" => "$self->{session}");
    my $response = $self->{bot}->post("https://class.coursera.org/$self->{course}/lecture/index");
    
    $self->{response}=$response;
    return $self->{bot}->links();
}

=head2 download

Download lectures.

=cut

sub download {
	
  my( $self) = @_;
  
	my @extentions=("mp4","txt","pdf","pptx","srt");
	foreach my $items ($self->get_links()) {
		
		foreach my $ext (@extentions) {
			
			if ( $items->[0] =~ /$ext/i) {
				
				my $st=$items->[1];
				
				if ($st =~ /for\s+/i) {
				my $st2=$';
				$st2 =~ s/^ //;
				$st2 =~s/\W+/_/g;
				
					if ( $self->{set_localdir} ) {
						print "Downloading class: " . $items->[1] . "\n" ;
						$self->{bot}->get( "$items->[0]", ":content_file" => "$self->{set_localdir}/$st2.$ext" );
					} else {
						print "Downloading class: " . $items->[1] . "\n"  ;
						$self->{bot}->get( "$items->[0]", ":content_file" => "$st2.$ext" );
					}
					
				}	
				
			}
			
		}	
		
		
	}			
}

=head2 get_all

Main, which marks the entry point of the program.

=cut

sub get_all {
	
    my( $self) = @_;
    
    $self->set_cookie();
    $self->set_csrftoken();
    $self->get_session();
    return $self->download();
	
}



=head1 AUTHOR

Ovidiu Nita Tatar, C<< <ovn.tatar at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-coursera at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Coursera>. 
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Coursera
    
    or
   
    https://github.com/ovntatar/WWW-Coursera/issues


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Coursera>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Coursera>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Coursera>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Coursera/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Ovidiu Nita Tatar.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of WWW::Coursera







