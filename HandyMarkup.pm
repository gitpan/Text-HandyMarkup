### //////////////////////////////////////////////////////////////////////////
#
#	TOP
#

=head1 NAME

Text::HandyMarkup - Handy markup parser & rewriter

 #------------------------------------------------------
 # (C) Daniel Peder & Infoset s.r.o., all rights reserved
 # http://www.infoset.com, Daniel.Peder@infoset.com
 #------------------------------------------------------

=cut

###													###
###	size of <TAB> in this document is 4 characters	###
###													###

### //////////////////////////////////////////////////////////////////////////
#
#	SECTION: package
#

    package Text::HandyMarkup;


### //////////////////////////////////////////////////////////////////////////
#
#	SECTION: version
#

	use vars qw( $VERSION $VERSION_LABEL $REVISION $REVISION_DATETIME $REVISION_LABEL $PROG_LABEL );

	$VERSION           = '0.10';
	
	$REVISION          = (qw$Revision: 1.2 $)[1];
	$REVISION_DATETIME = join(' ',(qw$Date: 2005/01/10 13:34:31 $)[1,2]);
	$REVISION_LABEL    = '$Id: HandyMarkup.pm,v 1.2 2005/01/10 13:34:31 root Exp root $';
	$VERSION_LABEL     = "$VERSION (rev. $REVISION $REVISION_DATETIME)";
	$PROG_LABEL        = __PACKAGE__." - ver. $VERSION_LABEL";

=pod

 $Revision: 1.2 $
 $Date: 2005/01/10 13:34:31 $

=cut


### //////////////////////////////////////////////////////////////////////////
#
#	SECTION: debug
#

	# use vars qw( $DEBUG ); $DEBUG=0;
	

### //////////////////////////////////////////////////////////////////////////
#
#	SECTION: constants
#

	# use constant	name		=> 'value';
	

### //////////////////////////////////////////////////////////////////////////
#
#	SECTION: modules use
#

	require 5.005_62;

	use strict                  ;
	use warnings                ;
	

### //////////////////////////////////////////////////////////////////////////
#
#	SECTION: class properties
#

#	our	$config	= 
#	{
#	};
	

### //////////////////////////////////////////////////////////////////////////
#
#	SECTION: methods
#

=head1 METHODS

=over 4

=cut



### //////////////////////////////////////////////////////////////////////////

=item	new ( [ $templates ] ) : blessed

=cut

### --------------------------------------------------------------------------
sub		new
### --------------------------------------------------------------------------
{
	my( $proto, $templates ) = @_;
	
	my	$self = {
		stack	=> [],
		names	=> {},
		defs	=> {},
		result	=> '',
	};
	
	bless( $self, (ref( $proto ) || $proto ));
	
	# OPTIONS
	
	$self->set_templates(  $templates );
	
	# RESULT
	
	return $self;
		
}


### //////////////////////////////////////////////////////////////////////////

=item	set_template ( $tag_name, $beg_template, $end_template ) : true

=cut

### --------------------------------------------------------------------------
sub set_template {
### --------------------------------------------------------------------------
	my(	$self, $tag_name, $beg_template, $end_template ) = @_;
	
	$self->{defs}{$tag_name} = { beg => $beg_template, end => $end_template };
	
	return 1;
}

### //////////////////////////////////////////////////////////////////////////

=item	set_templates ( $templates_hashref ) : true

=cut

### --------------------------------------------------------------------------
sub set_templates {
### --------------------------------------------------------------------------
	my(	$self, $templates_hashref ) = @_;
	
	while( my($key,$val)=each(%$templates_hashref)) {
		$self->{defs}{$key} = $val;
	}
	
	return 1;
}

### //////////////////////////////////////////////////////////////////////////

=item	tag_open ( $tag_name [, $params ] ) : true

=cut

### --------------------------------------------------------------------------
sub tag_open {
### --------------------------------------------------------------------------
	my(	$self, $tag_name, $params ) = @_;
	
	$self->push_tag( $tag_name, $params );
	my $tag_string = $self->tag_rewrite( beg => $tag_name, $params );
	$self->result_append( $tag_string );
	return 1;
}

### //////////////////////////////////////////////////////////////////////////

=item	tag_close ( $tag_name ) : true

=cut

### --------------------------------------------------------------------------
sub tag_close {
### --------------------------------------------------------------------------
	my(	$self, $tag_name ) = @_;
	
	if( defined( $tag_name ) && length( $tag_name ) ) {
		# pop named tag
		if( $self->is_open_tag( $tag_name )) {
			my $pop_tag;
			do {
				$pop_tag = $self->pop_tag();
				my $tag_string = $self->tag_rewrite( end => $pop_tag );
				$self->result_append( $tag_string );
			}	while $tag_name ne $pop_tag;
		}
	}
	else {
		# pop un-named tag
		$tag_name = $self->pop_tag();
		my $tag_string = $self->tag_rewrite( end => $tag_name );
		$self->result_append( $tag_string );
	}
	
	return 1;
}

### //////////////////////////////////////////////////////////////////////////

=item	text_insert ( $text_body ) : true

=cut

### --------------------------------------------------------------------------
sub text_insert {
### --------------------------------------------------------------------------
	my(	$self, $text_body ) = @_;
	
	$self->result_append( $text_body );
	
	return 1;
}

### //////////////////////////////////////////////////////////////////////////

=item	tag_rewrite ( $template_name, $tag_name [, $params] ) : string

=cut

### --------------------------------------------------------------------------
sub tag_rewrite {
### --------------------------------------------------------------------------
	my(	$self, $template_name, $tag_name, $params ) = @_;
	
	return undef unless defined( $tag_name ) && length( $tag_name );
	$params = '' unless defined( $params ) && length( $params );
	
#	my	$template = $self->get_template( $tag_name, $template_name );
	my	$template;
	if( exists $self->{defs}{$tag_name} ) {	# tag template
		$template = $self->{defs}{$tag_name}{$template_name};
	}
	elsif( exists $self->{defs}{'~'} ){ 	# default template
		$template = $self->{defs}{'~'}{$template_name};
	}
	unless( defined $template ) {
		if( 'beg' eq $template_name ) {
			$template = '[%t%p:';
		}
		elsif( 'end' eq $template_name ) {
			$template = ':%t]';
		}
		else {
			$template = '';
		}
	}
	else {
		unless( $params	=~ s{^(['"])(.*)\1$}{$2}s ) {	# drop lead/trail quotes pair
			$params =~ s{\s+$}{}s;						# or drop trailing spaces
		}
	}
	if( $template && $template =~ /%[%tp]/ ) {	# if there is anything to replace
		$template =~ s{%t}{$tag_name}gs;
		$template =~ s{%p}{$params}gs ;
		$template =~ s{%%}{%}gs;
	}
	
	return $template;
}


### //////////////////////////////////////////////////////////////////////////

=item	push_tag ( $tag_name ) : number

Return number of times B< $tag_name > was pushed.

=cut

### --------------------------------------------------------------------------
sub push_tag {
### --------------------------------------------------------------------------
	my(	$self, $tag_name ) = @_;
	
	return 0 unless defined( $tag_name ) && length( $tag_name );
	push @{$self->{stack}}, $tag_name;
	$self->{names}{$tag_name}++;
	return $self->{names}{$tag_name};
}

### //////////////////////////////////////////////////////////////////////////

=item	pop_tag (  ) : string

Return tag name or undef if there was no pushed tag.

=cut

### --------------------------------------------------------------------------
sub pop_tag {
### --------------------------------------------------------------------------
	my(	$self ) = @_;
	
	my $tag_name = pop @{$self->{stack}};
	if( $tag_name ) {
		$self->{names}{$tag_name}--;
		delete $self->{names}{$tag_name} if $self->{names}{$tag_name} <= 0;
	}
	
	return $tag_name;
}

### //////////////////////////////////////////////////////////////////////////

=item	get_top_tag (  ) : string

Return name of last pushed tag or ''.

=cut

### --------------------------------------------------------------------------
sub get_top_tag {
### --------------------------------------------------------------------------
	my(	$self ) = @_;
	
	return $self->{stack}[-1] if @{$self->{stack}};
	return '';
}

### //////////////////////////////////////////////////////////////////////////

=item	is_open_tag ( [ $tag_name ] ) : bool

With B< $tag_name > - number of times was specified tag open.

Without B< $tag_name > - number of all tag open.

=cut

### --------------------------------------------------------------------------
sub is_open_tag {
### --------------------------------------------------------------------------
	my(	$self, $tag_name ) = @_;
	
	return scalar @{$self->{names}} unless defined($tag_name);
	return 0 unless exists( $self->{names}{$tag_name} );
	return $self->{names}{$tag_name};
}

### //////////////////////////////////////////////////////////////////////////

=item	result_append ( $text ) : true

=cut

### --------------------------------------------------------------------------
sub result_append {
### --------------------------------------------------------------------------
	my(	$self, $text ) = @_;
	
	$self->{result} .= $text if defined $text;
	
	return 1;
}

### //////////////////////////////////////////////////////////////////////////

=item	parse ( $data ) : string

Return string with tags rewritten according to defined templates.

 - beg-tag without parameters :
   [tag_name:
 
 - beg-tag with parameters :
   [tag_name=parameter_value_without_whitespaces :
   [tag_name="parameter value with spaces and single quotes ' inside":
   [tag_name='parameter value with spaces and double quotes " inside':
   
 - end-tag un-named :
   :]

 - end-tag named :
   :tag_name]
 

=cut

### --------------------------------------------------------------------------
sub parse {
### --------------------------------------------------------------------------
	my(	$self, $data ) = @_;

	# predefined regex - symbolic description: (leading-text)?(beg-tag|end-tag)|trailing-text
	#
		# my $re = qr{(.*?)(?:\[(\w+)(?:=((?:".*?")|(?:'.*?')|\S+\s+)\s*|\s*):|:(\w*)\])|(.+)}s;
		my $re = qr{

			# $1 # leading text followed by beg/end tag
			(.*?)
			
			(?:
			
				# $2,$3 # beg-tag with optional parameter
				\[(\w+)(?:=((?:".*?")|(?:'.*?')|\S+\s+)\s*|\s*):
				
				|
				
				# $4 # end-tag
				:(\w*)\]
			)
			
			|
			
			# $5 # trailing text, unless beg/end tag found
			(.+)
			
		}sx;

	while( $data =~ /$re/cgos ) {

		my( $content, $beg_tag, $param, $end_tag, $content2 )=($1,$2,$3,$4,$5);
	
		if( $content ) {
			$self->text_insert( $content );
		}
		if( $content2 ) {
			$self->text_insert( $content2 );
		}
		if( defined $beg_tag ){
			$self->tag_open( $beg_tag, $param );
		}
		elsif( defined $end_tag ){
			$self->tag_close( $end_tag );
		}
	}
	
	$self->tag_close() while $self->get_top_tag();
	
	return $self->{result};
}


=back

=cut

1;

__DATA__

__END__

### //////////////////////////////////////////////////////////////////////////
#
#	SECTION: TODO
#


=head1 TODO	

=cut

