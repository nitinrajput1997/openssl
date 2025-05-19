package OpenSSL::safe::installdata;

use strict;
use warnings;
use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(
    $PREFIX
    $libdir
    $BINDIR $BINDIR_REL_PREFIX
    $LIBDIR $LIBDIR_REL_PREFIX
    $INCLUDEDIR $INCLUDEDIR_REL_PREFIX
    $APPLINKDIR $APPLINKDIR_REL_PREFIX
    $ENGINESDIR $ENGINESDIR_REL_LIBDIR
    $MODULESDIR $MODULESDIR_REL_LIBDIR
    $PKGCONFIGDIR $PKGCONFIGDIR_REL_LIBDIR
    $CMAKECONFIGDIR $CMAKECONFIGDIR_REL_LIBDIR
    $VERSION @LDLIBS
);

our $PREFIX                     = '/home/master/lakshya/WORKSPACE/openssl';
our $libdir                     = '/home/master/lakshya/WORKSPACE/openssl';
our $BINDIR                     = '/home/master/lakshya/WORKSPACE/openssl/apps';
our $BINDIR_REL_PREFIX          = 'apps';
our $LIBDIR                     = '/home/master/lakshya/WORKSPACE/openssl';
our $LIBDIR_REL_PREFIX          = '.';
our $INCLUDEDIR                 = '/home/master/lakshya/WORKSPACE/openssl/include';
our $INCLUDEDIR_REL_PREFIX      = 'include';
our $APPLINKDIR                 = '/home/master/lakshya/WORKSPACE/openssl/ms';
our $APPLINKDIR_REL_PREFIX      = 'ms';
our $ENGINESDIR                 = '/home/master/lakshya/WORKSPACE/openssl/engines';
our $ENGINESDIR_REL_LIBDIR      = 'engines';
our $MODULESDIR                 = '/home/master/lakshya/WORKSPACE/openssl/providers';
our $MODULESDIR_REL_LIBDIR      = 'providers';
our $PKGCONFIGDIR               = '/home/master/lakshya/WORKSPACE/openssl';
our $PKGCONFIGDIR_REL_LIBDIR    = '.';
our $CMAKECONFIGDIR             = '/home/master/lakshya/WORKSPACE/openssl';
our $CMAKECONFIGDIR_REL_LIBDIR  = '.';
our $VERSION                    = '3.4.0-dev';
our @LDLIBS                     =
    # Unix and Windows use space separation, VMS uses comma separation
    split(/ +| *, */, '-ldl -pthread -lm');

1;
