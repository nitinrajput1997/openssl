#! /usr/bin/env perl
# Copyright 2015-2023 The OpenSSL Project Authors. All Rights Reserved.
#
# Licensed under the Apache License 2.0 (the "License").  You may not use
# this file except in compliance with the License.  You can obtain a copy
# in the file LICENSE in the source distribution or at
# https://www.openssl.org/source/license.html

use strict;
use OpenSSL::Test qw/:DEFAULT cmdstr srctop_file srctop_dir bldtop_dir/;
use OpenSSL::Test::Utils;
use File::Temp qw(tempfile);
use TLSProxy::Proxy;
use checkhandshake qw(checkhandshake @handmessages @extensions);

my $test_name = "test_tls13messages";
setup($test_name);

plan skip_all => "TLSProxy isn't usable on $^O"
    if $^O =~ /^(VMS)$/;

plan skip_all => "$test_name needs the dynamic engine feature enabled"
    if disabled("engine") || disabled("dynamic-engine");

plan skip_all => "$test_name needs the sock feature enabled"
    if disabled("sock");

plan skip_all => "$test_name needs EC enabled"
    if disabled("ec");

@handmessages = (
    [TLSProxy::Message::MT_CLIENT_HELLO,
        checkhandshake::ALL_HANDSHAKES],
    [TLSProxy::Message::MT_SERVER_HELLO,
        checkhandshake::HRR_HANDSHAKE | checkhandshake::HRR_RESUME_HANDSHAKE],
    [TLSProxy::Message::MT_CLIENT_HELLO,
        checkhandshake::HRR_HANDSHAKE | checkhandshake::HRR_RESUME_HANDSHAKE],
    [TLSProxy::Message::MT_SERVER_HELLO,
        checkhandshake::ALL_HANDSHAKES],
    [TLSProxy::Message::MT_ENCRYPTED_EXTENSIONS,
        checkhandshake::ALL_HANDSHAKES],
    [TLSProxy::Message::MT_CERTIFICATE_REQUEST,
        checkhandshake::CLIENT_AUTH_HANDSHAKE],
    [TLSProxy::Message::MT_CERTIFICATE,
        checkhandshake::ALL_HANDSHAKES & ~(checkhandshake::RESUME_HANDSHAKE | checkhandshake::HRR_RESUME_HANDSHAKE)],
    [TLSProxy::Message::MT_CERTIFICATE_VERIFY,
        checkhandshake::ALL_HANDSHAKES & ~(checkhandshake::RESUME_HANDSHAKE | checkhandshake::HRR_RESUME_HANDSHAKE)],
    [TLSProxy::Message::MT_FINISHED,
        checkhandshake::ALL_HANDSHAKES],
    [TLSProxy::Message::MT_CERTIFICATE,
        checkhandshake::CLIENT_AUTH_HANDSHAKE],
    [TLSProxy::Message::MT_CERTIFICATE_VERIFY,
        checkhandshake::CLIENT_AUTH_HANDSHAKE],
    [TLSProxy::Message::MT_FINISHED,
        checkhandshake::ALL_HANDSHAKES],
    [0, 0]
);

@extensions = (
    [TLSProxy::Message::MT_CLIENT_HELLO, TLSProxy::Message::EXT_SERVER_NAME,
        TLSProxy::Message::CLIENT,
        checkhandshake::SERVER_NAME_CLI_EXTENSION],
    [TLSProxy::Message::MT_CLIENT_HELLO, TLSProxy::Message::EXT_STATUS_REQUEST,
        TLSProxy::Message::CLIENT,
        checkhandshake::STATUS_REQUEST_CLI_EXTENSION],
    [TLSProxy::Message::MT_CLIENT_HELLO, TLSProxy::Message::EXT_SUPPORTED_GROUPS,
        TLSProxy::Message::CLIENT,
        checkhandshake::DEFAULT_EXTENSIONS],
    [TLSProxy::Message::MT_CLIENT_HELLO, TLSProxy::Message::EXT_EC_POINT_FORMATS,
        TLSProxy::Message::CLIENT,
        checkhandshake::DEFAULT_EXTENSIONS],
    [TLSProxy::Message::MT_CLIENT_HELLO, TLSProxy::Message::EXT_SIG_ALGS,
        TLSProxy::Message::CLIENT,
        checkhandshake::DEFAULT_EXTENSIONS],
    [TLSProxy::Message::MT_CLIENT_HELLO, TLSProxy::Message::EXT_ALPN,
        TLSProxy::Message::CLIENT,
        checkhandshake::ALPN_CLI_EXTENSION],
    [TLSProxy::Message::MT_CLIENT_HELLO, TLSProxy::Message::EXT_SCT,
        TLSProxy::Message::CLIENT,
        checkhandshake::SCT_CLI_EXTENSION],
    [TLSProxy::Message::MT_CLIENT_HELLO, TLSProxy::Message::EXT_ENCRYPT_THEN_MAC,
        TLSProxy::Message::CLIENT,
        checkhandshake::DEFAULT_EXTENSIONS],
    [TLSProxy::Message::MT_CLIENT_HELLO, TLSProxy::Message::EXT_EXTENDED_MASTER_SECRET,
        TLSProxy::Message::CLIENT,
        checkhandshake::DEFAULT_EXTENSIONS],
    [TLSProxy::Message::MT_CLIENT_HELLO, TLSProxy::Message::EXT_SESSION_TICKET,
        TLSProxy::Message::CLIENT,
        checkhandshake::DEFAULT_EXTENSIONS],
    [TLSProxy::Message::MT_CLIENT_HELLO, TLSProxy::Message::EXT_KEY_SHARE,
        TLSProxy::Message::CLIENT,
        checkhandshake::DEFAULT_EXTENSIONS],
    [TLSProxy::Message::MT_CLIENT_HELLO, TLSProxy::Message::EXT_SUPPORTED_VERSIONS,
        TLSProxy::Message::CLIENT,
        checkhandshake::DEFAULT_EXTENSIONS],
    [TLSProxy::Message::MT_CLIENT_HELLO, TLSProxy::Message::EXT_PSK_KEX_MODES,
        TLSProxy::Message::CLIENT,
        checkhandshake::DEFAULT_EXTENSIONS],
    [TLSProxy::Message::MT_CLIENT_HELLO, TLSProxy::Message::EXT_PSK,
        TLSProxy::Message::CLIENT,
        checkhandshake::PSK_CLI_EXTENSION],
    [TLSProxy::Message::MT_CLIENT_HELLO, TLSProxy::Message::EXT_POST_HANDSHAKE_AUTH,
        TLSProxy::Message::CLIENT,
        checkhandshake::POST_HANDSHAKE_AUTH_CLI_EXTENSION],
    [TLSProxy::Message::MT_CLIENT_HELLO, TLSProxy::Message::EXT_RENEGOTIATE,
        TLSProxy::Message::CLIENT,
        checkhandshake::DEFAULT_EXTENSIONS],

    [TLSProxy::Message::MT_SERVER_HELLO, TLSProxy::Message::EXT_SUPPORTED_VERSIONS,
        TLSProxy::Message::SERVER,
        checkhandshake::DEFAULT_EXTENSIONS],
    [TLSProxy::Message::MT_SERVER_HELLO, TLSProxy::Message::EXT_KEY_SHARE,
        TLSProxy::Message::SERVER,
        checkhandshake::KEY_SHARE_HRR_EXTENSION],

    [TLSProxy::Message::MT_CLIENT_HELLO, TLSProxy::Message::EXT_SERVER_NAME,
        TLSProxy::Message::CLIENT,
        checkhandshake::SERVER_NAME_CLI_EXTENSION],
    [TLSProxy::Message::MT_CLIENT_HELLO, TLSProxy::Message::EXT_STATUS_REQUEST,
        TLSProxy::Message::CLIENT,
        checkhandshake::STATUS_REQUEST_CLI_EXTENSION],
    [TLSProxy::Message::MT_CLIENT_HELLO, TLSProxy::Message::EXT_SUPPORTED_GROUPS,
        TLSProxy::Message::CLIENT,
        checkhandshake::DEFAULT_EXTENSIONS],
    [TLSProxy::Message::MT_CLIENT_HELLO, TLSProxy::Message::EXT_EC_POINT_FORMATS,
        TLSProxy::Message::CLIENT,
        checkhandshake::DEFAULT_EXTENSIONS],
    [TLSProxy::Message::MT_CLIENT_HELLO, TLSProxy::Message::EXT_SIG_ALGS,
        TLSProxy::Message::CLIENT,
        checkhandshake::DEFAULT_EXTENSIONS],
    [TLSProxy::Message::MT_CLIENT_HELLO, TLSProxy::Message::EXT_ALPN,
        TLSProxy::Message::CLIENT,
        checkhandshake::ALPN_CLI_EXTENSION],
    [TLSProxy::Message::MT_CLIENT_HELLO, TLSProxy::Message::EXT_SCT,
        TLSProxy::Message::CLIENT,
        checkhandshake::SCT_CLI_EXTENSION],
    [TLSProxy::Message::MT_CLIENT_HELLO, TLSProxy::Message::EXT_ENCRYPT_THEN_MAC,
        TLSProxy::Message::CLIENT,
        checkhandshake::DEFAULT_EXTENSIONS],
    [TLSProxy::Message::MT_CLIENT_HELLO, TLSProxy::Message::EXT_EXTENDED_MASTER_SECRET,
        TLSProxy::Message::CLIENT,
        checkhandshake::DEFAULT_EXTENSIONS],
    [TLSProxy::Message::MT_CLIENT_HELLO, TLSProxy::Message::EXT_SESSION_TICKET,
        TLSProxy::Message::CLIENT,
        checkhandshake::DEFAULT_EXTENSIONS],
    [TLSProxy::Message::MT_CLIENT_HELLO, TLSProxy::Message::EXT_KEY_SHARE,
        TLSProxy::Message::CLIENT,
        checkhandshake::DEFAULT_EXTENSIONS],
    [TLSProxy::Message::MT_CLIENT_HELLO, TLSProxy::Message::EXT_SUPPORTED_VERSIONS,
        TLSProxy::Message::CLIENT,
        checkhandshake::DEFAULT_EXTENSIONS],
    [TLSProxy::Message::MT_CLIENT_HELLO, TLSProxy::Message::EXT_PSK_KEX_MODES,
        TLSProxy::Message::CLIENT,
        checkhandshake::DEFAULT_EXTENSIONS],
    [TLSProxy::Message::MT_CLIENT_HELLO, TLSProxy::Message::EXT_PSK,
        TLSProxy::Message::CLIENT,
        checkhandshake::PSK_CLI_EXTENSION],
    [TLSProxy::Message::MT_CLIENT_HELLO, TLSProxy::Message::EXT_POST_HANDSHAKE_AUTH,
        TLSProxy::Message::CLIENT,
        checkhandshake::POST_HANDSHAKE_AUTH_CLI_EXTENSION],
    [TLSProxy::Message::MT_CLIENT_HELLO, TLSProxy::Message::EXT_RENEGOTIATE,
        TLSProxy::Message::CLIENT,
        checkhandshake::DEFAULT_EXTENSIONS],

    [TLSProxy::Message::MT_SERVER_HELLO, TLSProxy::Message::EXT_SUPPORTED_VERSIONS,
        TLSProxy::Message::SERVER,
        checkhandshake::DEFAULT_EXTENSIONS],
    [TLSProxy::Message::MT_SERVER_HELLO, TLSProxy::Message::EXT_KEY_SHARE,
        TLSProxy::Message::SERVER,
        checkhandshake::DEFAULT_EXTENSIONS],
    [TLSProxy::Message::MT_SERVER_HELLO, TLSProxy::Message::EXT_PSK,
        TLSProxy::Message::SERVER,
        checkhandshake::PSK_SRV_EXTENSION],

    [TLSProxy::Message::MT_ENCRYPTED_EXTENSIONS, TLSProxy::Message::EXT_SERVER_NAME,
        TLSProxy::Message::SERVER,
        checkhandshake::SERVER_NAME_SRV_EXTENSION],
    [TLSProxy::Message::MT_ENCRYPTED_EXTENSIONS, TLSProxy::Message::EXT_ALPN,
        TLSProxy::Message::SERVER,
        checkhandshake::ALPN_SRV_EXTENSION],
    [TLSProxy::Message::MT_ENCRYPTED_EXTENSIONS, TLSProxy::Message::EXT_SUPPORTED_GROUPS,
        TLSProxy::Message::SERVER,
        checkhandshake::SUPPORTED_GROUPS_SRV_EXTENSION],

    [TLSProxy::Message::MT_CERTIFICATE_REQUEST, TLSProxy::Message::EXT_SIG_ALGS,
        TLSProxy::Message::SERVER,
        checkhandshake::DEFAULT_EXTENSIONS],

    [TLSProxy::Message::MT_CERTIFICATE, TLSProxy::Message::EXT_STATUS_REQUEST,
        TLSProxy::Message::SERVER,
        checkhandshake::STATUS_REQUEST_SRV_EXTENSION],
    [TLSProxy::Message::MT_CERTIFICATE, TLSProxy::Message::EXT_SCT,
        TLSProxy::Message::SERVER,
        checkhandshake::SCT_SRV_EXTENSION],

    [0,0,0,0]
);

my $testcount = 17;

plan tests => 2 * $testcount;

SKIP: {
    skip "TLS 1.3 is disabled", $testcount if disabled("tls1_3");
    # Run tests with TLS
    run_tests(0);
}

SKIP: {
    skip "DTLS 1.3 is disabled", $testcount if disabled("dtls1_3");
    skip "DTLSProxy does not work on Windows", $testcount if $^O =~ /^(MSWin32)$/;
    run_tests(1);
}

sub run_tests
{
    my $run_test_as_dtls = shift;
    my $proxy_start_success = 0;

    (undef, my $session) = tempfile();
    my $proxy;
    if ($run_test_as_dtls == 1) {
        $proxy = TLSProxy::Proxy->new_dtls(
            undef,
            cmdstr(app([ "openssl" ]), display => 1),
            srctop_file("apps", "server.pem"),
            (!$ENV{HARNESS_ACTIVE} || $ENV{HARNESS_VERBOSE})
        );
    }
    else {
        $proxy = TLSProxy::Proxy->new(
            undef,
            cmdstr(app([ "openssl" ]), display => 1),
            srctop_file("apps", "server.pem"),
            (!$ENV{HARNESS_ACTIVE} || $ENV{HARNESS_VERBOSE})
        );
    }

    $proxy->clear();

    SKIP: {
        skip "TODO(DTLSv1.3): When enabling sessionfile and dtls TLSProxy hangs"
            ." after the handshake.", 2 if $run_test_as_dtls == 1;
        #Test 1: Check we get all the right messages for a default handshake
        $proxy->serverconnects(2);
        $proxy->clientflags("-no_rx_cert_comp -sess_out " . $session);
        $proxy->sessionfile($session);
        $proxy_start_success = $proxy->start();
        skip "TLSProxy did not start correctly", $testcount if $proxy_start_success == 0;
        checkhandshake($proxy, checkhandshake::DEFAULT_HANDSHAKE,
            checkhandshake::DEFAULT_EXTENSIONS,
            "Default handshake test");

        #Test 2: Resumption handshake
        $proxy->clearClient();
        $proxy->clientflags("-no_rx_cert_comp -sess_in " . $session);
        $proxy->clientstart();
        checkhandshake($proxy, checkhandshake::RESUME_HANDSHAKE,
            (checkhandshake::DEFAULT_EXTENSIONS
                | checkhandshake::PSK_CLI_EXTENSION
                | checkhandshake::PSK_SRV_EXTENSION),
            "Resumption handshake test");
    }

    SKIP: {
        skip "No OCSP support in this OpenSSL build", 4
            if disabled("ct") || disabled("ec") || disabled("ocsp");
        #Test 3: A status_request handshake (client request only)
        $proxy->clear();
        $proxy->clientflags("-no_rx_cert_comp -status");
        $proxy_start_success = $proxy->start();
        skip "TLSProxy did not start correctly", 4 if $proxy_start_success == 0;
        checkhandshake($proxy, checkhandshake::DEFAULT_HANDSHAKE,
            checkhandshake::DEFAULT_EXTENSIONS
                | checkhandshake::STATUS_REQUEST_CLI_EXTENSION,
            "status_request handshake test (client)");

        #Test 4: A status_request handshake (server support only)
        $proxy->clear();
        $proxy->clientflags("-no_rx_cert_comp");
        $proxy->serverflags("-no_rx_cert_comp -status_file "
            . srctop_file("test", "recipes", "ocsp-response.der"));
        $proxy->start();
        checkhandshake($proxy, checkhandshake::DEFAULT_HANDSHAKE,
            checkhandshake::DEFAULT_EXTENSIONS,
            "status_request handshake test (server)");

        SKIP: {
            skip "TLSProxy does not support partial messages for dtls", 2
                if $run_test_as_dtls == 1;
            #Test 5: A status_request handshake (client and server)
            $proxy->clear();
            $proxy->clientflags("-no_rx_cert_comp -status");
            $proxy->serverflags("-no_rx_cert_comp -status_file "
                . srctop_file("test", "recipes", "ocsp-response.der"));
            $proxy->start();
            checkhandshake($proxy, checkhandshake::DEFAULT_HANDSHAKE,
                checkhandshake::DEFAULT_EXTENSIONS
                    | checkhandshake::STATUS_REQUEST_CLI_EXTENSION
                    | checkhandshake::STATUS_REQUEST_SRV_EXTENSION,
                "status_request handshake test");

            #Test 6: A status_request handshake (client and server) with client auth
            $proxy->clear();
            $proxy->clientflags("-no_rx_cert_comp -status -enable_pha -cert "
                . srctop_file("apps", "server.pem"));
            $proxy->serverflags("-no_rx_cert_comp -Verify 5 -status_file "
                . srctop_file("test", "recipes", "ocsp-response.der"));
            $proxy->start();
            checkhandshake($proxy, checkhandshake::CLIENT_AUTH_HANDSHAKE,
                checkhandshake::DEFAULT_EXTENSIONS
                    | checkhandshake::STATUS_REQUEST_CLI_EXTENSION
                    | checkhandshake::STATUS_REQUEST_SRV_EXTENSION
                    | checkhandshake::POST_HANDSHAKE_AUTH_CLI_EXTENSION,
                "status_request handshake with client auth test");
        }
    }

    SKIP: {
        skip "TLSProxy does not support partial messages for dtls", 1
            if $run_test_as_dtls == 1;
        #Test 7: A client auth handshake
        $proxy->clear();
        $proxy->clientflags("-no_rx_cert_comp -enable_pha -cert " . srctop_file("apps", "server.pem"));
        $proxy->serverflags("-no_rx_cert_comp -Verify 5");
        $proxy_start_success = $proxy->start();
        skip "TLSProxy did not start correctly", $testcount - 6 if $proxy_start_success == 0;
        checkhandshake($proxy, checkhandshake::CLIENT_AUTH_HANDSHAKE,
            checkhandshake::DEFAULT_EXTENSIONS |
                checkhandshake::POST_HANDSHAKE_AUTH_CLI_EXTENSION,
            "Client auth handshake test");
    }

    #Test 8: Server name handshake (no client request)
    $proxy->clear();
    $proxy->clientflags("-no_rx_cert_comp -noservername");
    $proxy->start();
    checkhandshake($proxy, checkhandshake::DEFAULT_HANDSHAKE,
        checkhandshake::DEFAULT_EXTENSIONS
            & ~checkhandshake::SERVER_NAME_CLI_EXTENSION,
        "Server name handshake test (client)");

    #Test 9: Server name handshake (server support only)
    $proxy->clear();
    $proxy->clientflags("-no_rx_cert_comp -noservername");
    $proxy->serverflags("-no_rx_cert_comp -servername testhost");
    $proxy->start();
    checkhandshake($proxy, checkhandshake::DEFAULT_HANDSHAKE,
        checkhandshake::DEFAULT_EXTENSIONS
            & ~checkhandshake::SERVER_NAME_CLI_EXTENSION,
        "Server name handshake test (server)");

    #Test 10: Server name handshake (client and server)
    $proxy->clear();
    $proxy->clientflags("-no_rx_cert_comp -servername testhost");
    $proxy->serverflags("-no_rx_cert_comp -servername testhost");
    $proxy->start();
    checkhandshake($proxy, checkhandshake::DEFAULT_HANDSHAKE,
        checkhandshake::DEFAULT_EXTENSIONS
            | checkhandshake::SERVER_NAME_SRV_EXTENSION,
        "Server name handshake test");

    #Test 11: ALPN handshake (client request only)
    $proxy->clear();
    $proxy->clientflags("-no_rx_cert_comp -alpn test");
    $proxy->start();
    checkhandshake($proxy, checkhandshake::DEFAULT_HANDSHAKE,
        checkhandshake::DEFAULT_EXTENSIONS
            | checkhandshake::ALPN_CLI_EXTENSION,
        "ALPN handshake test (client)");

    #Test 12: ALPN handshake (server support only)
    $proxy->clear();
    $proxy->clientflags("-no_rx_cert_comp");
    $proxy->serverflags("-no_rx_cert_comp -alpn test");
    $proxy->start();
    checkhandshake($proxy, checkhandshake::DEFAULT_HANDSHAKE,
        checkhandshake::DEFAULT_EXTENSIONS,
        "ALPN handshake test (server)");

    #Test 13: ALPN handshake (client and server)
    $proxy->clear();
    $proxy->clientflags("-no_rx_cert_comp -alpn test");
    $proxy->serverflags("-no_rx_cert_comp -alpn test");
    $proxy->start();
    checkhandshake($proxy, checkhandshake::DEFAULT_HANDSHAKE,
        checkhandshake::DEFAULT_EXTENSIONS
            | checkhandshake::ALPN_CLI_EXTENSION
            | checkhandshake::ALPN_SRV_EXTENSION,
        "ALPN handshake test");

    SKIP: {
        skip "No CT, EC or OCSP support in this OpenSSL build", 1
            if disabled("ct") || disabled("ec") || disabled("ocsp");
        skip "TLSProxy does not support partial messages for dtls", 1
            if $run_test_as_dtls == 1;

        #Test 14: SCT handshake (client request only)
        $proxy->clear();
        #Note: -ct also sends status_request
        $proxy->clientflags("-no_rx_cert_comp -ct");
        $proxy->serverflags("-no_rx_cert_comp -status_file "
            . srctop_file("test", "recipes", "ocsp-response.der")
            . " -serverinfo " . srctop_file("test", "serverinfo2.pem"));
        $proxy->start();
        checkhandshake($proxy, checkhandshake::DEFAULT_HANDSHAKE,
            checkhandshake::DEFAULT_EXTENSIONS
                | checkhandshake::SCT_CLI_EXTENSION
                | checkhandshake::SCT_SRV_EXTENSION
                | checkhandshake::STATUS_REQUEST_CLI_EXTENSION
                | checkhandshake::STATUS_REQUEST_SRV_EXTENSION,
            "SCT handshake test");
    }

    SKIP: {
        skip "TLSProxy does not support partial messages for dtls", 1
            if $run_test_as_dtls == 1;
        #Test 15: HRR Handshake
        $proxy->clear();
        $proxy->clientflags("-no_rx_cert_comp");
        $proxy->serverflags("-no_rx_cert_comp -curves P-384");
        $proxy->start();
        checkhandshake($proxy, checkhandshake::HRR_HANDSHAKE,
            checkhandshake::DEFAULT_EXTENSIONS
                | checkhandshake::KEY_SHARE_HRR_EXTENSION,
            "HRR handshake test");
    }

    SKIP: {
        skip "TODO(DTLSv1.3): When enabling sessionfile and dtls TLSProxy hangs"
            . " after the handshake.", 1 if $run_test_as_dtls == 1;
        #Test 16: Resumption handshake with HRR
        $proxy->clear();
        $proxy->clientflags("-no_rx_cert_comp -sess_in " . $session);
        $proxy->serverflags("-no_rx_cert_comp -curves P-384");
        $proxy->start();
        checkhandshake($proxy, checkhandshake::HRR_RESUME_HANDSHAKE,
            (checkhandshake::DEFAULT_EXTENSIONS
                | checkhandshake::KEY_SHARE_HRR_EXTENSION
                | checkhandshake::PSK_CLI_EXTENSION
                | checkhandshake::PSK_SRV_EXTENSION),
            "Resumption handshake with HRR test");
    }


    SKIP: {
        skip "TLSProxy does not support partial messages for dtls", 1
            if $run_test_as_dtls == 1;
        #Test 17: Acceptable but non preferred key_share
        $proxy->clear();
        $proxy->clientflags("-no_rx_cert_comp -curves P-384");
        $proxy->start();
        checkhandshake($proxy, checkhandshake::DEFAULT_HANDSHAKE,
            checkhandshake::DEFAULT_EXTENSIONS
                | checkhandshake::SUPPORTED_GROUPS_SRV_EXTENSION,
            "Acceptable but non preferred key_share");
    }

    unlink $session;
}
