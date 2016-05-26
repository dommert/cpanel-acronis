#!/usr/local/cpanel/3rdparty/bin/perl
# cpanel - whostmgr/docroot/cgi/easyapache.pl     Copy$
#                                                     $
# copyright@cpanel.net                                $
# This code is subject to the cPanel license. Unauthor$

BEGIN { unshift @INC, '/usr/local/cpanel'; }

use strict;
use warnings;

# Commented out stuff I"m pretty sure we won't need
# but not 100%, so it's just commented out

# use Cpanel::App             ();
# use Cpanel::Config          ();
# use Cpanel::Config::Httpd   ();
# use Cpanel::Encoder::Tiny   ();
# use Cpanel::FileUtils       ();
use Cpanel::Form::Param     ();
# use Cpanel::Locale          ('lh');
# use Cpanel::SafeRun         ();
use Cpanel::Template        ();
use JSON                    ();
use Whostmgr::ACLS          ();
use Whostmgr::HTMLInterface ();

Whostmgr::ACLS::init_acls();

sub run {
    my $prm    = Cpanel::Form::Param->new();
#    my $cpconf = Cpanel::Config::loadcpconf();
    my $conf;
    {
        local $/;
        open( my $fh, '<',
            '/usr/local/cpanel/3rdparty/etc/acronis//acronisbackupwhm.conf' );
        $conf = JSON::decode_json(<$fh>);
    }

    if ( !Whostmgr::ACLS::hasroot() ) {
        print "Content-type: text/plain\r\n\r\n";
        print "Access Denied";
        exit;
    }

if ( !caller() ) {
    my $result = __PACKAGE__->run();
    if ( !$result ) {
        exit 1;
    }
}

sub run {
    my $prm    = Cpanel::Form::Param->new();
#    my $cpconf = Cpanel::Config::loadcpconf();
    my $conf;
    {
        local $/;
        open( my $fh, '<',
            '/usr/local/cpanel/3rdparty/etc/acronis//acronisbackupwhm.conf' );
        $conf = JSON::decode_json(<$fh>);
    }

    if ( !Whostmgr::ACLS::hasroot() ) {
        print "Content-type: text/plain\r\n\r\n";
        print "Access Denied";
        exit;
    }

    print "Content-type: text/html\r\n\r\n";
    Cpanel::Template::process_template(
        'whostmgr',
        {
            'template_file' => 'acronisbackup.tmpl',
            'data'          => {
                'version' => "Acronis Backup Manager .$
            },
            'form'    => $prm,
            'options' => $conf,
        },
    );

    exit;
}

1;
