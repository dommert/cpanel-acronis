## Copyright 2002-2016 Acronis International GmbH

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

package AcronisAPI::Client;
use strict;

use lib "/root/AcronisBackup-OBAS/lib/";
use Util::RestClient;
use JSON::XS;  
use Data::Dumper;

sub new {
	my $class = shift;
	my $params = {
		url => undef,
		username => undef,
		password => undef,
		cockies => undef,
	@_
	};

	my $cockies = $params->{cockies} or die "Path to cockies file is not specified.";
	my $rest_client = Util::RestClient->new(cockies => $cockies);
	
	my $self = {
		_rest_client => $rest_client,
		_url => $params->{url},
		_username => $params->{username},
		_password => $params->{password},
		_cockies_path => $params->{cockies}
	};
	bless $self, $class;
	return $self;
}

sub rest_client {
	my $self = shift;
	return $self->{_rest_client};
}

sub relogin {
	my $self = shift;
	my $rest_client = Util::RestClient->new(
		url => $self->{_url},
		username => $self->{_username},
		password => $self->{_password},
	);
	my $jar = $rest_client->cockies();
	$jar->save($self->{_cockies_path});
	print "Logged in successfully\n";
	$self->{_rest_client} = $rest_client;
	
}

sub request {
	my $self = shift;
	my $request = {
		method => undef,
		path => {},
		query => {},
		body => {},
		@_
	};
	
	my $rest_client = $self->rest_client();
	my $method = $request->{method};
	my $result = {};
	eval {
		my $response = $rest_client->$method(
			path => $request->{path},
			query => $request->{query},
			body => $request->{body}
		);
		print Dumper($response);
		if ($response->is_success()) {
			$result = {
				is_success => 1,
				response => JSON::XS->new->utf8->decode($response->content()) 
			};
		} else {
			if ($response->code() == 401) {
				print "Session expired\n";
				$self->relogin();
				$result = $self->request(%{$request});
			} else {
				$result = {
					message => $response->message() . '. ' . $response->content,
					is_success => 0
				};
			}
		}
	};
	if ($@) {
		$result = {
			message => $@,
			is_success => 0
		}
	}
	return $result;
}

sub get_group {
	my $self = shift;
	my $params = {
		group_id => undef,
		@_
	};

	my $result = {};
	my $response = $self->request(
		method => 'get',
		path => 'groups/' . $params->{group_id} . '/'
	);
	if ($response->{is_success}) {
		$result = {
			is_success => 1,
                        response => $response->{response}
                };
        } else {
                $result = $response;
        }

	return $result;
}

sub create_group {
	my $self = shift;
	my $params = {
		data => {},
		@_
	};

	my $response = $self->request(
		method => 'post',
		path => 'groups/self/children/',
		body => $params->{data} 
	);
	my $result = {};
	if ($response->{is_success}) {
		$result = {
			is_success => 1,
			group_id => $response->{response}->{id},
			version => $response->{response}->{version}
		};
	} else {
		$result = $response;
	}

	return $result;
}

sub update_group {
	my $self = shift;
	my $params = {
		group_id => undef,
		version => undef,
		data => {},
	        @_
	};
	my $response = $self->request(
		method => 'put',
		path => 'groups/' . $params->{group_id} . '/',
		query => {version => $params->{version}},
		body => $params->{data}
	);

	my $result = {};
	if ($response->{is_success}) {
		$result = {
			is_success => 1,
			version => $response->{response}->{version}
		};
	} else {
		$result = $response;
	}

	return $result;
}

sub delete_group {
	my $self = shift;
	my $params = {
		group_id => undef,
		@_
	};

	my $result = {};
	my $response = $self->request(
		method => 'delete',
		path => 'groups/' . $params->{group_id} . '/',
		query => {version => $params->{version}}
	);
	if ($response->{is_success}) {
		$result = {
			is_success => 1,
                };
	} else {
		$result = $response;
	}
	return $response;
}

sub get_storages_list {
	my $self = shift;
	my $response = $self->request(
		method => 'get',
		path => 'groups/self/storages/'
	);
	my $result = {};
	if ($response->{is_success}) {
		$result = {
			is_success => 1,
			storages => $response->{response}->{items}
		};
	} else {
		$result = $response;
	}
	return $result;
}

1;	
