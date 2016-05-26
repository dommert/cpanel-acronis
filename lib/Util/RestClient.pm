## Copyright 2002-2016 Acronis International GmbH
##
## Licensed under the Apache License, Version 2.0 (the "License");
## you may not use this file except in compliance with the License.
## You may obtain a copy of the License at
##
##     http://www.apache.org/licenses/LICENSE-2.0
##
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS,
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
## See the License for the specific language governing permissions and
## limitations under the License.

package Util::RestClient;
use strict;

use LWP::UserAgent;
use URI;
use HTTP::Headers;
use HTTP::Cookies;
use HTTP::Request::Common;
use JSON::XS;

use Data::Dumper;

use constant API_URI => '/api/1/';
use constant CONTENT_TYPE => 'application/json';

sub new {
	my $class = shift;
	my $params = {
		url => undef,
		username => undef,
		password => undef,
		cockies => undef,	
		@_
	};

	my $self = {};
  
	if ($params->{cockies}) {
		my $jar = HTTP::Cookies->new(file => $params->{cockies});
		my @urls = keys %{$jar->{COOKIES}};
		$self = {
			_cockies => $jar,
			_server_url => 'https://' . $urls[0]
		};
	} else {
		my $url = $params->{url} or die 'Connection URL is not defined.';
		my $username = $params->{username} or die 'Username is not defined.';
		my $password = $params->{password} or die 'Password is not defined';

		my $headers = HTTP::Headers->new('Content-Type' => &CONTENT_TYPE);
		my $ua = LWP::UserAgent->new(
			cookie_jar => {},
			default_headers => $headers
		);
		my $uri = URI->new($url . &API_URI);
		$uri->path($uri->path . 'accounts/');
		$uri->query_form('login' => $username);

		my $response = $ua->get($uri);
		die $response->message() unless ($response->is_success());

		my $content = JSON::XS->new->utf8->decode($response->content());
		my $server_url = $content->{server_url};

		$uri = URI->new($server_url . &API_URI);
		$uri->path($uri->path . '/login/');;
		$response = $ua->post($uri, Content_Type => &CONTENT_TYPE, 'Content' => JSON::XS->new->utf8->encode({username => $username, password => $password}));
		die $response->message() unless ($response->is_success());

		$self = {
			_cockies => $ua->cookie_jar,
			_server_url => $server_url
		};
	}
	
	bless $self, $class;
	return $self;
}

sub server_url {
	my $self = shift;
	return $self->{_server_url}  . &API_URI;
}

sub cockies {
	my $self = shift;
	return $self->{_cockies};
}

sub get {
	my $self = shift;
	my $params = {
		path => undef,
		@_	
	};

	my $uri = URI->new($self->server_url());
	$uri->path($uri->path . $params->{path});

	my $headers = HTTP::Headers->new('Content-Type' => &CONTENT_TYPE);
	my $ua = LWP::UserAgent->new(
		cookie_jar => $self->cockies(),
		default_headers => $headers
	);
	my $response = $ua->get($uri);
	return $response;	
}

sub post {
	my $self = shift;
	my $params = {
		path => undef,
		body => undef,
		@_
	};
	my $uri = URI->new($self->server_url());
	$uri->path($uri->path . $params->{path});
	my $ua = LWP::UserAgent->new(
		cookie_jar => $self->cockies(),
	);
	my $response = $ua->post($uri, Content_Type => &CONTENT_TYPE, 'Content' => JSON::XS->new->utf8->encode($params->{body}));
	return $response;
}

sub delete {
	my $self = shift;
	my $params = {
		path => undef,
		query => {},
		@_
	};
	my $uri = URI->new($self->server_url());
	$uri->path($uri->path . $params->{path});
	$uri->query_form($params->{query});
	my $request = HTTP::Request::Common::DELETE($uri, Content_Type => &CONTENT_TYPE);
	my $ua = LWP::UserAgent->new(
		cookie_jar => $self->cockies(),
	);
	my $response = $ua->request($request);
	return $response;
}

sub put {
        my $self = shift;
	my $params = {
		path => undef,
		body => {},
		query => {},
		@_
	};
	my $uri = URI->new($self->server_url());
	$uri->path($uri->path . $params->{path});
	$uri->query_form($params->{query});
	my $request = HTTP::Request::Common::PUT($uri, Content_Type => &CONTENT_TYPE, 'Content' => JSON::XS->new->utf8->encode($params->{body}));
	my $ua = LWP::UserAgent->new(
		cookie_jar => $self->cockies(),
	);
	my $response = $ua->request($request);
	return $response;
}

1;
