package ProFTPD::Tests::Modules::mod_proxy;

use lib qw(t/lib);
use base qw(ProFTPD::TestSuite::Child);
use strict;

use File::Copy;
use File::Path qw(mkpath);
use File::Spec;
use IO::Handle;
use Time::HiRes qw(usleep);

use ProFTPD::TestSuite::FTP;
use ProFTPD::TestSuite::Utils qw(:auth :config :running :test :testsuite);

$| = 1;

my $order = 0;

my $TESTS = {
  proxy_reverse_connect => {
    order => ++$order,
    test_class => [qw(forking reverse)],
  },

  proxy_reverse_connect_failed_bad_dst_addr => {
    order => ++$order,
    test_class => [qw(forking reverse)],
  },

  proxy_reverse_connect_failed_non2xx => {
    order => ++$order,
    test_class => [qw(forking mod_wrap2 mod_wrap2_file reverse)],
  },

  proxy_reverse_login => {
    order => ++$order,
    test_class => [qw(forking reverse)],
  },

  proxy_reverse_login_failed => {
    order => ++$order,
    test_class => [qw(forking reverse)],
  },

  proxy_reverse_login_chrooted => {
    order => ++$order,
    test_class => [qw(forking reverse rootprivs)],
  },

  proxy_reverse_feat => {
    order => ++$order,
    test_class => [qw(forking reverse)],
  },

  proxy_reverse_list_pasv => {
    order => ++$order,
    test_class => [qw(forking reverse)],
  },

  proxy_reverse_list_port => {
    order => ++$order,
    test_class => [qw(forking reverse)],
  },

  proxy_reverse_list_pasv_enoent => {
    order => ++$order,
    test_class => [qw(forking reverse)],
  },

  proxy_reverse_list_port_enoent => {
    order => ++$order,
    test_class => [qw(forking reverse)],
  },

  proxy_reverse_epsv => {
    order => ++$order,
    test_class => [qw(forking reverse)],
  },

  # TODO: proxy_reverse_epsv_all

  proxy_reverse_eprt_ipv4 => {
    order => ++$order,
    test_class => [qw(forking reverse)],
  },

  proxy_reverse_eprt_ipv6 => {
    order => ++$order,
    test_class => [qw(feature_ipv6 forking reverse)],
  },

  proxy_reverse_retr_pasv_ascii => {
    order => ++$order,
    test_class => [qw(forking reverse)],
  },

  proxy_reverse_retr_pasv_binary => {
    order => ++$order,
    test_class => [qw(forking reverse)],
  },

  # This needs to handle chunks larger than the transfer buffer size;
  # maybe use SocketOptions to tune them differently; handle short writes
  # via outer/inner loops in data_send().

  proxy_reverse_retr_large_file => {
    order => ++$order,
    test_class => [qw(forking reverse slow)],
  },

  proxy_reverse_retr_empty_file => {
    order => ++$order,
    test_class => [qw(forking reverse)],
  },

  proxy_reverse_retr_abort => {
    order => ++$order,
    test_class => [qw(forking reverse)],
  },

  proxy_reverse_stor_pasv => {
    order => ++$order,
    test_class => [qw(forking reverse)],
  },

  proxy_reverse_stor_port => {
    order => ++$order,
    test_class => [qw(forking reverse)],
  },

  proxy_reverse_stor_large_file => {
    order => ++$order,
    test_class => [qw(forking reverse slow)],
  },

  proxy_reverse_stor_empty_file => {
    order => ++$order,
    test_class => [qw(forking reverse)],
  },

  proxy_reverse_stor_eperm => {
    order => ++$order,
    test_class => [qw(forking reverse)],
  },

  proxy_reverse_stor_abort => {
    order => ++$order,
    test_class => [qw(forking reverse)],
  },

  proxy_reverse_rest_retr => {
    order => ++$order,
    test_class => [qw(forking reverse)],
  },

  proxy_reverse_rest_stor => {
    order => ++$order,
    test_class => [qw(forking reverse)],
  },

  proxy_reverse_unknown_cmd => {
    order => ++$order,
    test_class => [qw(forking reverse)],
  },

  proxy_reverse_config_passiveports_pasv => {
    order => ++$order,
    test_class => [qw(forking reverse)],
  },

  proxy_reverse_config_passiveports_epsv => {
    order => ++$order,
    test_class => [qw(forking reverse)],
  },

  # MasqueradeAddress only really applies to PASV
  proxy_reverse_config_masqueradeaddress => {
    order => ++$order,
    test_class => [qw(forking reverse)],
  },

  proxy_reverse_config_allowforeignaddress_port => {
    order => ++$order,
    test_class => [qw(forking reverse)],
  },

  proxy_reverse_config_allowforeignaddress_eprt => {
    order => ++$order,
    test_class => [qw(forking reverse)],
  },

  # Normal TimeoutIdle, honored by mod_proxy (frontend and backend)
  proxy_reverse_config_timeoutidle_frontend => {
    order => ++$order,
    test_class => [qw(forking reverse)],
  },

  proxy_reverse_config_timeoutidle_backend => {
    order => ++$order,
    test_class => [qw(forking reverse)],
  },

  proxy_reverse_config_timeoutlogin_frontend => {
    order => ++$order,
    test_class => [qw(forking reverse)],
  },

  # Normal TimeoutNoTransfer, honored by mod_proxy (frontend and backend)
  proxy_reverse_config_timeoutnoxfer_frontend => {
    order => ++$order,
    test_class => [qw(forking reverse)],
  },

  proxy_reverse_config_timeoutnoxfer_backend => {
    order => ++$order,
    test_class => [qw(forking reverse)],
  },

  # Normal TimeoutStalled, honored by mod_proxy (frontend and backend)
  proxy_reverse_config_timeoutstalled_frontend => {
    order => ++$order,
    test_class => [qw(forking reverse)],
  },

  proxy_reverse_config_timeoutstalled_backend => {
    order => ++$order,
    test_class => [qw(forking reverse)],
  },

  # XXX What about TimeoutSession, TimeoutLinger?

  proxy_reverse_config_datatransferpolicy_pasv_list_pasv => {
    order => ++$order,
    test_class => [qw(forking reverse)],
  },

  proxy_reverse_config_datatransferpolicy_pasv_list_port => {
    order => ++$order,
    test_class => [qw(forking reverse)],
  },

  proxy_reverse_config_datatransferpolicy_port_list_pasv => {
    order => ++$order,
    test_class => [qw(forking reverse)],
  },

  proxy_reverse_config_datatransferpolicy_port_list_port => {
    order => ++$order,
    test_class => [qw(forking reverse)],
  },

  proxy_reverse_config_datatransferpolicy_epsv_list_pasv => {
    order => ++$order,
    test_class => [qw(forking reverse)],
  },

  proxy_reverse_config_datatransferpolicy_epsv_list_port => {
    order => ++$order,
    test_class => [qw(forking reverse)],
  },

  proxy_reverse_config_datatransferpolicy_eprt_list_pasv => {
    order => ++$order,
    test_class => [qw(forking reverse)],
  },

  proxy_reverse_config_datatransferpolicy_eprt_list_port => {
    order => ++$order,
    test_class => [qw(forking reverse)],
  },

  proxy_reverse_config_datatransferpolicy_active_list_pasv => {
    order => ++$order,
    test_class => [qw(forking reverse)],
  },

  proxy_reverse_config_datatransferpolicy_active_list_port => {
    order => ++$order,
    test_class => [qw(forking reverse)],
  },

  proxy_reverse_config_datatransferpolicy_passive_list_pasv => {
    order => ++$order,
    test_class => [qw(forking reverse)],
  },

  proxy_reverse_config_datatransferpolicy_passive_list_port => {
    order => ++$order,
    test_class => [qw(forking reverse)],
  },

  proxy_reverse_config_datatransferpolicy_client => {
    order => ++$order,
    test_class => [qw(forking reverse)],
  },

  # backend selection: random, roundrobin, shuffle, per-user, leastconns...?
  proxy_reverse_config_selection_random => {
    order => ++$order,
    test_class => [qw(forking reverse)],
  },

  proxy_reverse_config_reverseservers_file => {
    order => ++$order,
    test_class => [qw(forking reverse)],
  },

  # TransferLog entries (binary/ascii, upload/download, complete/aborted)
  # Note that TransferLog, as supported by mod_proxy, CANNOT have the absolute
  # path of the file transferred; we can only know path as requested by
  # the client.

  proxy_reverse_xferlog_retr_ascii_ok => {
    order => ++$order,
    test_class => [qw(forking reverse)],
  },

  proxy_reverse_xferlog_retr_binary_ok => {
    order => ++$order,
    test_class => [qw(forking reverse)],
  },

  proxy_reverse_xferlog_stor_ascii_ok => {
    order => ++$order,
    test_class => [qw(forking reverse)],
  },

  proxy_reverse_xferlog_stor_binary_ok => {
    order => ++$order,
    test_class => [qw(forking reverse)],
  },

  # ExtendedLog entries.  The most affected will be %D/%d and %F/%f.
  proxy_reverse_extlog_retr_var_F_f => {
    order => ++$order,
    test_class => [qw(forking reverse)],
  },

  proxy_reverse_extlog_stor_var_F_f => {
    order => ++$order,
    test_class => [qw(forking reverse)],
  },

  proxy_reverse_extlog_list_var_D_d => {
    order => ++$order,
    test_class => [qw(forking reverse)],
  },

  # LastLog?  WtmpLog?

  # HiddenStore? (should have no effect)
  # TransferPriority?
  # TransferRate?

  proxy_reverse_proxy_protocol_ipv4 => {
    order => ++$order,
    test_class => [qw(forking mod_proxy_protocol reverse)],
  },

  proxy_reverse_proxy_protocol_ipv6 => {
    order => ++$order,
    test_class => [qw(feature_ipv6 forking mod_proxy_protocol reverse)],
  },

  # proxy_reverse_proxy_protocol_ipv6_useipv6_off
  # proxy_reverse_proxy_protocol_unknown

  proxy_tls_reverse_login => {
    order => ++$order,
    test_class => [qw(forking mod_tls reverse)],
  },

  proxy_tls_reverse_login_failed => {
    order => ++$order,
    test_class => [qw(forking mod_tls reverse)],
  },

  proxy_tls_reverse_login_tlslogin => {
    order => ++$order,
    test_class => [qw(forking mod_tls reverse)],
  },

#  proxy_tls_reverse_list_pasv => {
#    order => ++$order,
#    test_class => [qw(forking mod_tls reverse)],
#  },

  proxy_forward_connect => {
    order => ++$order,
    test_class => [qw(forking forward)],
  },

  proxy_forward_noproxyauth_login => {
    order => ++$order,
    test_class => [qw(forking forward)],
  },

  proxy_forward_noproxyauth_login_netftp_fw_type_1 => {
    order => ++$order,
    test_class => [qw(forking forward)],
  },

  proxy_forward_noproxyauth_login_failed_bad_dst_addr => {
    order => ++$order,
    test_class => [qw(forking forward)],
  },

  proxy_forward_noproxyauth_login_failed_non2xx => {
    order => ++$order,
    test_class => [qw(forking forward mod_wrap2 mod_wrap2_file)],
  },

  proxy_forward_noproxyauth_login_failed_login_limit => {
    order => ++$order,
    test_class => [qw(forking forward)],
  },

  proxy_forward_noproxyauth_login_failed_bad_sequence => {
    order => ++$order,
    test_class => [qw(forking forward)],
  },

  proxy_forward_noproxyauth_login_failed_bad_dst_passwd => {
    order => ++$order,
    test_class => [qw(forking forward)],
  },

  proxy_forward_login_feat_first => {
    order => ++$order,
    test_class => [qw(forking forward)],
  },

  proxy_forward_list_pasv => {
    order => ++$order,
    test_class => [qw(forking forward)],
  },

  proxy_forward_list_port => {
    order => ++$order,
    test_class => [qw(forking forward)],
  },

  proxy_forward_epsv => {
    order => ++$order,
    test_class => [qw(forking forward)],
  },

  proxy_forward_eprt_ipv4 => {
    order => ++$order,
    test_class => [qw(forking forward)],
  },

  proxy_forward_eprt_ipv6 => {
    order => ++$order,
    test_class => [qw(feature_ipv6 forking forward)],
  },

  proxy_forward_stor_pasv => {
    order => ++$order,
    test_class => [qw(forking forward)],
  },

  proxy_forward_userwithproxyauth_login => {
    order => ++$order,
    test_class => [qw(forking forward)],
  },

  proxy_forward_userwithproxyauth_login_user_incl_at_symbol => {
    order => ++$order,
    test_class => [qw(forking forward)],
  },

  # Note: The following test is disabled because Net::FTP has a bug in the
  # handling of a FTP_FIREWALL_TYPE=2.  Specifically, in its login() method,
  # it does not properly construct the $fwuser variable unless there is a
  # ~/.netrc file -- and such a file cannot be used for tests like this.
  #
  # proxy_forward_userwithproxyauth_login_netftp_fw_type_2

  proxy_forward_userwithproxyauth_login_failed_bad_dst_addr => {
    order => ++$order,
    test_class => [qw(forking forward)],
  },

  proxy_forward_userwithproxyauth_login_failed_non2xx => {
    order => ++$order,
    test_class => [qw(forking forward)],
  },

  proxy_forward_userwithproxyauth_login_failed_limit_login => {
    order => ++$order,
    test_class => [qw(forking forward)],
  },

  proxy_forward_userwithproxyauth_login_failed_bad_sequence => {
    order => ++$order,
    test_class => [qw(forking forward)],
  },

  proxy_forward_userwithproxyauth_login_failed_bad_proxy_passwd => {
    order => ++$order,
    test_class => [qw(forking forward)],
  },

  proxy_forward_userwithproxyauth_login_failed_bad_dst_passwd => {
    order => ++$order,
    test_class => [qw(forking forward)],
  },

  proxy_forward_userwithproxyauth_bad_sequence_no_dst_login => {
    order => ++$order,
    test_class => [qw(forking forward)],
  },

  proxy_forward_proxyuserwithproxyauth_login => {
    order => ++$order,
    test_class => [qw(forking forward)],
  },

  proxy_forward_proxyuserwithproxyauth_login_user_incl_at_symbol => {
    order => ++$order,
    test_class => [qw(forking forward)],
  },

  # Note: The following test is disabled because Net::FTP has a bug in the
  # handling of a FTP_FIREWALL_TYPE=6.  Specifically, in its login() method,
  # it does not properly construct the $fwuser variable unless there is a
  # ~/.netrc file -- and such a file cannot be used for tests like this.
  #
  # proxy_forward_proxyuserwithproxyauth_login_netftp_fw_type6

  proxy_forward_proxyuserwithproxyauth_login_failed_bad_dst_addr => {
    order => ++$order,
    test_class => [qw(forking forward)],
  },

  proxy_forward_proxyuserwithproxyauth_login_failed_non2xx => {
    order => ++$order,
    test_class => [qw(forking forward)],
  },

  proxy_forward_proxyuserwithproxyauth_login_failed_limit_login => {
    order => ++$order,
    test_class => [qw(forking forward)],
  },

  proxy_forward_proxyuserwithproxyauth_login_failed_bad_sequence => {
    order => ++$order,
    test_class => [qw(forking forward)],
  },

  proxy_forward_proxyuserwithproxyauth_login_failed_bad_proxy_passwd => {
    order => ++$order,
    test_class => [qw(forking forward)],
  },

  proxy_forward_proxyuserwithproxyauth_login_failed_bad_dst_passwd => {
    order => ++$order,
    test_class => [qw(forking forward)],
  },

  proxy_forward_proxyuserwithproxyauth_bad_sequence_no_dst_login => {
    order => ++$order,
    test_class => [qw(forking forward)],
  },

  # proxy_forward_config_displayconnect
  # proxy_forward_config_filter
  # proxy_forward_config_timeoutlogin_frontend
  # proxy_forward_config_timeoutlogin_backend
  # proxy_forward_config_maxloginattempts
};

sub new {
  return shift()->SUPER::new(@_);
}

sub list_tests {
  return testsuite_get_runnable_tests($TESTS);
}

sub get_reverse_proxy_config {
  my $tmpdir = shift;
  my $log_file = shift;
  my $vhost_port = shift;

  my $table_dir = File::Spec->rel2abs("$tmpdir/var/proxy");

  my $config = {
    ProxyEngine => 'on',
    ProxyLog => $log_file,
    ProxyReverseServers => "ftp://127.0.0.1:$vhost_port",
    ProxyRole => 'reverse',
    ProxyTables => $table_dir,
  };

  return $config;
}

sub get_forward_proxy_config {
  my $tmpdir = shift;
  my $log_file = shift;
  my $vhost_port = shift;

  my $table_dir = File::Spec->rel2abs("$tmpdir/var/proxy");

  # XXX Provide necessary <Proxy>/<Limit> section?

  my $config = {
    ProxyEngine => 'on',
    ProxyLog => $log_file,
    ProxyRole => 'forward',
    ProxyTables => $table_dir,
  };

  return $config;
}

sub proxy_reverse_connect {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 12;

  my $proxy_config = get_reverse_proxy_config($tmpdir, $log_file, $vhost_port);

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20',

    AuthUserFile => $auth_user_file,
    AuthGroupFile => $auth_group_file,
    SocketBindTight => 'on',

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },
  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  WtmpLog off
  TransferLog none
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      my $client = ProFTPD::TestSuite::FTP->new('127.0.0.1', $port);

      my $resp_code = $client->response_code();
      my $resp_msg = $client->response_msg();

      $client->quit();

      my $expected;

      $expected = 220;
      $self->assert($expected == $resp_code,
        test_msg("Expected response code $expected, got $resp_code"));

      $expected = 'Real Server';
      $self->assert(qr/$expected/, $resp_msg,
        test_msg("Expected response message '$expected', got '$resp_msg'"));
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_reverse_connect_failed_bad_dst_addr {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 12;

  my $proxy_config = get_reverse_proxy_config($tmpdir, $log_file, $vhost_port);
  $proxy_config->{ProxyReverseServers} = 'ftp://1.2.3.4:5678';

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20',

    AuthUserFile => $auth_user_file,
    AuthGroupFile => $auth_group_file,
    SocketBindTight => 'on',

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },
  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  WtmpLog off
  TransferLog none
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      eval { ProFTPD::TestSuite::FTP->new('127.0.0.1', $port, 0, 1) };
      unless ($@) {
        die("Unexpectedly connected successfully");
      }
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_reverse_connect_failed_non2xx {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 12;

  my $proxy_config = get_reverse_proxy_config($tmpdir, $log_file, $vhost_port);

  my $allow_file = File::Spec->rel2abs("$tmpdir/wrap2.allow");
  if (open(my $fh, "> $allow_file")) {
    unless (close($fh)) {
      die("Can't write $allow_file: $!");
    }

  } else {
    die("Can't open $allow_file: $!");
  }

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20',

    AuthUserFile => $auth_user_file,
    AuthGroupFile => $auth_group_file,
    SocketBindTight => 'on',

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },
  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  AuthUserFile $auth_user_file
  AuthGroupFile $auth_group_file
  AuthOrder mod_auth_file.c

  AllowOverride off
  WtmpLog off
  TransferLog none

  <IfModule mod_wrap2_file.c>
    WrapEngine on
    WrapLog $log_file
    WrapTables file:$allow_file builtin:all
    WrapOptions CheckOnConnect
  </IfModule>
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      eval { ProFTPD::TestSuite::FTP->new('127.0.0.1', $port, 0, 1) };
      unless ($@) {
        die("Unexpectedly connected successfully");
      }
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_reverse_login {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 12;

  my $proxy_config = get_reverse_proxy_config($tmpdir, $log_file, $vhost_port);

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20',

    AuthUserFile => $auth_user_file,
    AuthGroupFile => $auth_group_file,
    SocketBindTight => 'on',

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },

    Limit => {
      LOGIN => {
        DenyUser => $user,
      },
    },

  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  AuthUserFile $auth_user_file
  AuthGroupFile $auth_group_file
  AuthOrder mod_auth_file.c

  AllowOverride off
  WtmpLog off
  TransferLog none
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      my $client = ProFTPD::TestSuite::FTP->new('127.0.0.1', $port);
      $client->login($user, $passwd);
      $client->quit();
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_reverse_login_failed {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 12;

  my $proxy_config = get_reverse_proxy_config($tmpdir, $log_file, $vhost_port);

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20',

    AuthUserFile => $auth_user_file,
    AuthGroupFile => $auth_group_file,
    SocketBindTight => 'on',

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },

    Limit => {
      LOGIN => {
        DenyUser => $user,
      },
    },

  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  AuthUserFile $auth_user_file
  AuthGroupFile $auth_group_file
  AuthOrder mod_auth_file.c

  AllowOverride off
  WtmpLog off
  TransferLog none
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      my $client = ProFTPD::TestSuite::FTP->new('127.0.0.1', $port);
      eval { $client->login($user, 'foobar') };
      unless ($@) {
        die("Login succeeded unexpectedly");
      }

      my $resp_code = $client->response_code();
      my $resp_msg = $client->response_msg();

      my $expected = 530;
      $self->assert($expected == $resp_code,
        test_msg("Expected response code $expected, got $resp_code"));

      $expected = 'Login incorrect.';
      $self->assert($expected eq $resp_msg,
        test_msg("Expected response message '$expected', got '$resp_msg'"));
      $client->quit();
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_reverse_login_chrooted {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 12;

  my $proxy_config = get_reverse_proxy_config($tmpdir, $log_file, $vhost_port);

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20',

    AuthUserFile => $auth_user_file,
    AuthGroupFile => $auth_group_file,
    SocketBindTight => 'on',

    # For dropping privs
    User => 'nobody',
    Group => 'nobody',

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },
  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  AuthUserFile $auth_user_file
  AuthGroupFile $auth_group_file
  AuthOrder mod_auth_file.c

  AllowOverride off
  WtmpLog off
  TransferLog none
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      my $client = ProFTPD::TestSuite::FTP->new('127.0.0.1', $port);
      $client->login($user, $passwd);
      $client->quit();
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_reverse_feat {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 12;

  my $proxy_config = get_reverse_proxy_config($tmpdir, $log_file, $vhost_port);

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20',

    AuthUserFile => $auth_user_file,
    AuthGroupFile => $auth_group_file,
    SocketBindTight => 'on',

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },
  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  AuthUserFile $auth_user_file
  AuthGroupFile $auth_group_file
  AuthOrder mod_auth_file.c

  AllowOverride off
  WtmpLog off
  TransferLog none
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      my $client = ProFTPD::TestSuite::FTP->new('127.0.0.1', $port);
      $client->login($user, $passwd);

      $client->feat();
      my $resp_code = $client->response_code();
      my $resp_msgs = $client->response_msgs();

      my $expected = 211;
      $self->assert($expected == $resp_code,
        test_msg("Expected response code $expected, got $resp_code"));

      $expected = 'Features:';
      $self->assert($expected eq $resp_msgs->[0],
        test_msg("Expected first response message '$expected', got '$resp_msgs->[0]'"));

      $client->quit();
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_reverse_list_pasv {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 12;

  my $proxy_config = get_reverse_proxy_config($tmpdir, $log_file, $vhost_port);

  my $timeout_idle = 10;

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20',

    AuthUserFile => $auth_user_file,
    AuthGroupFile => $auth_group_file,
    SocketBindTight => 'on',
    TimeoutIdle => $timeout_idle,

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },

    Limit => {
      LOGIN => {
        DenyUser => $user,
      },
    },

  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  AuthUserFile $auth_user_file
  AuthGroupFile $auth_group_file
  AuthOrder mod_auth_file.c

  AllowOverride off
  TimeoutIdle $timeout_idle

  TransferLog none
  WtmpLog off
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      my $client = ProFTPD::TestSuite::FTP->new('127.0.0.1', $port);
      $client->login($user, $passwd);

      my $conn = $client->list_raw();
      unless ($conn) {
        die("Failed to LIST: " . $client->response_code() . ' ' .
          $client->response_msg());
      }

      my $buf;
      $conn->read($buf, 8192, 10);
      eval { $conn->close() };

      my $resp_code = $client->response_code();
      my $resp_msg = $client->response_msg();
      $self->assert_transfer_ok($resp_code, $resp_msg);

      ($resp_code, $resp_msg) = $client->quit();

      my $expected = 221;
      $self->assert($expected == $resp_code,
        test_msg("Expected response code $expected, got $resp_code"));

      $expected = 'Goodbye.';
      $self->assert($expected eq $resp_msg,
        test_msg("Expected response message '$expected', got '$resp_msg'"));
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh, $timeout_idle + 2) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_reverse_list_port {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 12;

  my $proxy_config = get_reverse_proxy_config($tmpdir, $log_file, $vhost_port);

  my $timeout_idle = 10;

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20',

    AuthUserFile => $auth_user_file,
    AuthGroupFile => $auth_group_file,
    SocketBindTight => 'on',
    TimeoutIdle => $timeout_idle,

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },

    Limit => {
      LOGIN => {
        DenyUser => $user,
      },
    },

  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  AuthUserFile $auth_user_file
  AuthGroupFile $auth_group_file
  AuthOrder mod_auth_file.c

  AllowOverride off
  TimeoutIdle $timeout_idle

  TransferLog none
  WtmpLog off
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      my $client = ProFTPD::TestSuite::FTP->new('127.0.0.1', $port, 1);
      $client->login($user, $passwd);

      my $conn = $client->list_raw();
      unless ($conn) {
        die("Failed to LIST: " . $client->response_code() . ' ' .
          $client->response_msg());
      }

      my $buf;
      $conn->read($buf, 8192, 10);
      eval { $conn->close() };

      my $resp_code = $client->response_code();
      my $resp_msg = $client->response_msg();
      $self->assert_transfer_ok($resp_code, $resp_msg);

      ($resp_code, $resp_msg) = $client->quit();

      my $expected = 221;
      $self->assert($expected == $resp_code,
        test_msg("Expected response code $expected, got $resp_code"));

      $expected = 'Goodbye.';
      $self->assert($expected eq $resp_msg,
        test_msg("Expected response message '$expected', got '$resp_msg'"));
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh, $timeout_idle + 2) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_reverse_list_pasv_enoent {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 12;

  my $proxy_config = get_reverse_proxy_config($tmpdir, $log_file, $vhost_port);

  my $timeout_idle = 10;

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20',

    AuthUserFile => $auth_user_file,
    AuthGroupFile => $auth_group_file,
    SocketBindTight => 'on',
    TimeoutIdle => $timeout_idle,

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },

    Limit => {
      LOGIN => {
        DenyUser => $user,
      },
    },

  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  AuthUserFile $auth_user_file
  AuthGroupFile $auth_group_file
  AuthOrder mod_auth_file.c

  AllowOverride off
  TimeoutIdle $timeout_idle

  TransferLog none
  WtmpLog off
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      my $client = ProFTPD::TestSuite::FTP->new('127.0.0.1', $port);
      $client->login($user, $passwd);

      my $enoent_dir = '/foo/bar/baz';

      eval { $client->list($enoent_dir) };
      unless ($@) {
        die("LIST succeeded unexpectedly");
      }

      my $resp_code = $client->response_code();
      my $resp_msg = $client->response_msg();

      my $expected = 450;
      $self->assert($expected == $resp_code,
        test_msg("Expected response code $expected, got $resp_code"));

      $expected = "$enoent_dir: No such file or directory";
      $self->assert($expected eq $resp_msg,
        test_msg("Expected response message '$expected', got '$resp_msg'"));

      ($resp_code, $resp_msg) = $client->quit();

      $expected = 221;
      $self->assert($expected == $resp_code,
        test_msg("Expected response code $expected, got $resp_code"));

      $expected = 'Goodbye.';
      $self->assert($expected eq $resp_msg,
        test_msg("Expected response message '$expected', got '$resp_msg'"));
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh, $timeout_idle + 2) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_reverse_list_port_enoent {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 12;

  my $proxy_config = get_reverse_proxy_config($tmpdir, $log_file, $vhost_port);

  my $timeout_idle = 10;

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20',

    AuthUserFile => $auth_user_file,
    AuthGroupFile => $auth_group_file,
    SocketBindTight => 'on',
    TimeoutIdle => $timeout_idle,

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },

    Limit => {
      LOGIN => {
        DenyUser => $user,
      },
    },

  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  AuthUserFile $auth_user_file
  AuthGroupFile $auth_group_file
  AuthOrder mod_auth_file.c

  AllowOverride off
  TimeoutIdle $timeout_idle

  TransferLog none
  WtmpLog off
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      my $client = ProFTPD::TestSuite::FTP->new('127.0.0.1', $port, 1);
      $client->login($user, $passwd);

      my $enoent_dir = '/foo/bar/baz';
      eval { $client->list($enoent_dir) };
      unless ($@) {
        die("LIST succeeded unexpectedly");
      }

      my $resp_code = $client->response_code();
      my $resp_msg = $client->response_msg();

      my $expected = 450;
      $self->assert($expected == $resp_code,
        test_msg("Expected response code $expected, got $resp_code"));

      $expected = "$enoent_dir: No such file or directory";
      $self->assert($expected eq $resp_msg,
        test_msg("Expected response message '$expected', got '$resp_msg'"));

      ($resp_code, $resp_msg) = $client->quit();

      $expected = 221;
      $self->assert($expected == $resp_code,
        test_msg("Expected response code $expected, got $resp_code"));

      $expected = 'Goodbye.';
      $self->assert($expected eq $resp_msg,
        test_msg("Expected response message '$expected', got '$resp_msg'"));
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh, $timeout_idle + 2) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_reverse_epsv {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 12;

  my $proxy_config = get_reverse_proxy_config($tmpdir, $log_file, $vhost_port);

  my $timeout_idle = 10;

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20',

    AuthUserFile => $auth_user_file,
    AuthGroupFile => $auth_group_file,
    SocketBindTight => 'on',
    TimeoutIdle => $timeout_idle,

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },

    Limit => {
      LOGIN => {
        DenyUser => $user,
      },
    },

  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  AuthUserFile $auth_user_file
  AuthGroupFile $auth_group_file
  AuthOrder mod_auth_file.c

  AllowOverride off
  TimeoutIdle $timeout_idle

  TransferLog none
  WtmpLog off
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      my $client = ProFTPD::TestSuite::FTP->new('127.0.0.1', $port);
      $client->login($user, $passwd);

      my ($resp_code, $resp_msg) = $client->epsv();

      my $expected = 229;
      $self->assert($expected == $resp_code,
        test_msg("Expected response code $expected, got $resp_code"));

      $expected = '^Entering Extended Passive Mode \(\|\|\|\d+\|\)';
      $self->assert(qr/$expected/, $resp_msg,
        test_msg("Expected response message '$expected', got '$resp_msg'"));
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh, $timeout_idle + 2) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_reverse_eprt_ipv4 {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 12;

  my $proxy_config = get_reverse_proxy_config($tmpdir, $log_file, $vhost_port);

  my $timeout_idle = 10;

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20',

    AuthUserFile => $auth_user_file,
    AuthGroupFile => $auth_group_file,
    SocketBindTight => 'on',
    TimeoutIdle => $timeout_idle,

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },

    Limit => {
      LOGIN => {
        DenyUser => $user,
      },
    },

  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  AuthUserFile $auth_user_file
  AuthGroupFile $auth_group_file
  AuthOrder mod_auth_file.c

  AllowOverride off
  TimeoutIdle $timeout_idle

  TransferLog none
  WtmpLog off
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      my $client = ProFTPD::TestSuite::FTP->new('127.0.0.1', $port);
      $client->login($user, $passwd);

      my ($resp_code, $resp_msg) = $client->eprt('|1|127.0.0.1|4856|');

      my $expected;

      $expected = 200;
      $self->assert($expected == $resp_code,
        test_msg("Expected $expected, got $resp_code"));

      $expected = "EPRT command successful";
      $self->assert($expected eq $resp_msg,
        test_msg("Expected '$expected', got '$resp_msg'"));

      $client->quit();
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh, $timeout_idle + 2) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_reverse_eprt_ipv6 {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 12;

  my $proxy_config = get_reverse_proxy_config($tmpdir, $log_file, $vhost_port);

  my $timeout_idle = 10;

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20',

    AuthUserFile => $auth_user_file,
    AuthGroupFile => $auth_group_file,
    SocketBindTight => 'on',
    TimeoutIdle => $timeout_idle,
    UseIPv6 => 'on',

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },

    Limit => {
      LOGIN => {
        DenyUser => $user,
      },
    },

  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  AuthUserFile $auth_user_file
  AuthGroupFile $auth_group_file
  AuthOrder mod_auth_file.c

  AllowOverride off
  TimeoutIdle $timeout_idle

  TransferLog none
  WtmpLog off
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      my $client = ProFTPD::TestSuite::FTP->new('127.0.0.1', $port);
      $client->login($user, $passwd);

      my ($resp_code, $resp_msg) = $client->eprt('|2|::ffff:127.0.0.1|4856|');

      my $expected;

      $expected = 200;
      $self->assert($expected == $resp_code,
        test_msg("Expected $expected, got $resp_code"));

      $expected = "EPRT command successful";
      $self->assert($expected eq $resp_msg,
        test_msg("Expected '$expected', got '$resp_msg'"));

      $client->quit();
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh, $timeout_idle + 2) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_reverse_retr_pasv_ascii {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  my $test_data = "Hello, Proxying World!\n";
  my $test_file = File::Spec->rel2abs("$tmpdir/test.txt");
  if (open(my $fh, "> $test_file")) {
    print $fh $test_data;

    unless (close($fh)) {
      die("Unable to write $test_file: $!");
    }

  } else {
    die("Unable to open $test_file: $!");
  }

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 12;

  my $proxy_config = get_reverse_proxy_config($tmpdir, $log_file, $vhost_port);

  my $timeout_idle = 10;

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20',

    AuthUserFile => $auth_user_file,
    AuthGroupFile => $auth_group_file,
    SocketBindTight => 'on',
    TimeoutIdle => $timeout_idle,
    UseIPv6 => 'on',

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },

    Limit => {
      LOGIN => {
        DenyUser => $user,
      },
    },

  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  AuthUserFile $auth_user_file
  AuthGroupFile $auth_group_file
  AuthOrder mod_auth_file.c

  AllowOverride off
  TimeoutIdle $timeout_idle

  TransferLog none
  WtmpLog off
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      my $client = ProFTPD::TestSuite::FTP->new('127.0.0.1', $port);
      $client->login($user, $passwd);
      $client->type('ascii');

      my $conn = $client->retr_raw($test_file);
      unless ($conn) {
        die("RETR failed: " . $client->response_code() . " " .
          $client->response_msg());
      }

      my $buf;
      $conn->read($buf, 8192, 30);
      my $size = $conn->bytes_read();
      eval { $conn->close() };

      my $resp_code = $client->response_code();
      my $resp_msg = $client->response_msg();
      $self->assert_transfer_ok($resp_code, $resp_msg);

      $client->quit();

      # The length of 'Hello, Proxying World!\n' is 23, but we expect 24
      # here because of the ASCII conversion of the bare LF to a CRLF.
      my $expected = length($test_data) + 1;
      $self->assert($expected == $size,
        test_msg("Expected $expected, got $size"));
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh, $timeout_idle + 2) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_reverse_retr_pasv_binary {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  my $test_data = "Hello, Proxying World!\n";
  my $test_file = File::Spec->rel2abs("$tmpdir/test.txt");
  if (open(my $fh, "> $test_file")) {
    print $fh $test_data;

    unless (close($fh)) {
      die("Unable to write $test_file: $!");
    }

  } else {
    die("Unable to open $test_file: $!");
  }

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 12;

  my $proxy_config = get_reverse_proxy_config($tmpdir, $log_file, $vhost_port);

  my $timeout_idle = 10;

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20',

    AuthUserFile => $auth_user_file,
    AuthGroupFile => $auth_group_file,
    SocketBindTight => 'on',
    TimeoutIdle => $timeout_idle,
    UseIPv6 => 'on',

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },

    Limit => {
      LOGIN => {
        DenyUser => $user,
      },
    },

  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  AuthUserFile $auth_user_file
  AuthGroupFile $auth_group_file
  AuthOrder mod_auth_file.c

  AllowOverride off
  TimeoutIdle $timeout_idle

  TransferLog none
  WtmpLog off
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      my $client = ProFTPD::TestSuite::FTP->new('127.0.0.1', $port);
      $client->login($user, $passwd);
      $client->type('binary');

      my $conn = $client->retr_raw($test_file);
      unless ($conn) {
        die("RETR failed: " . $client->response_code() . " " .
          $client->response_msg());
      }

      my $buf;
      $conn->read($buf, 8192, 30);
      my $size = $conn->bytes_read();
      eval { $conn->close() };

      my $resp_code = $client->response_code();
      my $resp_msg = $client->response_msg();
      $self->assert_transfer_ok($resp_code, $resp_msg);

      $client->quit();

      # The length of 'Hello, Proxying World!\n' is 23, so that is what
      # we expect here; no ASCII conversion to change things.
      my $expected = length($test_data);
      $self->assert($expected == $size,
        test_msg("Expected $expected, got $size"));
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh, $timeout_idle + 2) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_reverse_retr_large_file {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  my $test_datalen = (4 * 1024 * 1024);
  my $test_file = File::Spec->rel2abs("$tmpdir/test.txt");
  if (open(my $fh, "> $test_file")) {
    print $fh 'R' x $test_datalen;

    unless (close($fh)) {
      die("Unable to write $test_file: $!");
    }

  } else {
    die("Unable to open $test_file: $!");
  }

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 12;

  my $proxy_config = get_reverse_proxy_config($tmpdir, $log_file, $vhost_port);

  my $timeout_idle = 120;

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20',

    AuthUserFile => $auth_user_file,
    AuthGroupFile => $auth_group_file,
    SocketBindTight => 'on',
    TimeoutIdle => $timeout_idle,
    UseIPv6 => 'on',

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },

    Limit => {
      LOGIN => {
        DenyUser => $user,
      },
    },

  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  AuthUserFile $auth_user_file
  AuthGroupFile $auth_group_file
  AuthOrder mod_auth_file.c

  AllowOverride off
  TimeoutIdle $timeout_idle

  TransferLog none
  WtmpLog off
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      my $client = ProFTPD::TestSuite::FTP->new('127.0.0.1', $port);
      $client->login($user, $passwd);
      $client->type('binary');

      my $conn = $client->retr_raw($test_file);
      unless ($conn) {
        die("RETR failed: " . $client->response_code() . " " .
          $client->response_msg());
      }

      my $buf;
      while ($conn->read($buf, 32768, 30)) {
        # Delay a little between reads, to try to force mod_proxy to deal
        # with a slow consumer (thus leading to short writes).

        my $sleep_ms = 150;
        my $sleep_usecs = ($sleep_ms * 1000);
        usleep($sleep_usecs);
      }
      my $size = $conn->bytes_read();
      eval { $conn->close() };

      my $resp_code = $client->response_code();
      my $resp_msg = $client->response_msg();
      $self->assert_transfer_ok($resp_code, $resp_msg);

      $client->quit();

      my $expected = $test_datalen;
      $self->assert($expected == $size,
        test_msg("Expected $expected, got $size"));
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh, $timeout_idle + 2) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_reverse_retr_empty_file {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  my $test_datalen = 0;
  my $test_file = File::Spec->rel2abs("$tmpdir/test.txt");
  if (open(my $fh, "> $test_file")) {
    unless (close($fh)) {
      die("Unable to write $test_file: $!");
    }

  } else {
    die("Unable to open $test_file: $!");
  }

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 12;

  my $proxy_config = get_reverse_proxy_config($tmpdir, $log_file, $vhost_port);

  my $timeout_idle = 120;

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20',

    AuthUserFile => $auth_user_file,
    AuthGroupFile => $auth_group_file,
    SocketBindTight => 'on',
    TimeoutIdle => $timeout_idle,
    UseIPv6 => 'on',

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },

    Limit => {
      LOGIN => {
        DenyUser => $user,
      },
    },

  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  AuthUserFile $auth_user_file
  AuthGroupFile $auth_group_file
  AuthOrder mod_auth_file.c

  AllowOverride off
  TimeoutIdle $timeout_idle

  TransferLog none
  WtmpLog off
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      my $client = ProFTPD::TestSuite::FTP->new('127.0.0.1', $port);
      $client->login($user, $passwd);
      $client->type('binary');

      my $conn = $client->retr_raw($test_file);
      unless ($conn) {
        die("RETR failed: " . $client->response_code() . " " .
          $client->response_msg());
      }

      my $buf;
      while ($conn->read($buf, 32768, 30)) {
        # Delay a little between reads, to try to force mod_proxy to deal
        # with a slow consumer (thus leading to short writes).

        my $sleep_ms = 150;
        my $sleep_usecs = ($sleep_ms * 1000);
        usleep($sleep_usecs);
      }
      my $size = $conn->bytes_read();
      eval { $conn->close() };

      my $resp_code = $client->response_code();
      my $resp_msg = $client->response_msg();
      $self->assert_transfer_ok($resp_code, $resp_msg);

      $client->quit();

      my $expected = $test_datalen;
      $self->assert($expected == $size,
        test_msg("Expected $expected, got $size"));
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh, $timeout_idle + 2) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_reverse_retr_abort {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  my $test_datalen = (4 * 1024 * 1024);
  my $test_file = File::Spec->rel2abs("$tmpdir/test.txt");
  if (open(my $fh, "> $test_file")) {
    print $fh 'R' x $test_datalen;

    unless (close($fh)) {
      die("Unable to write $test_file: $!");
    }

  } else {
    die("Unable to open $test_file: $!");
  }

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 12;

  my $proxy_config = get_reverse_proxy_config($tmpdir, $log_file, $vhost_port);

  my $timeout_idle = 10;

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20',

    AuthUserFile => $auth_user_file,
    AuthGroupFile => $auth_group_file,
    SocketBindTight => 'on',
    TimeoutIdle => $timeout_idle,
    UseIPv6 => 'on',

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },

    Limit => {
      LOGIN => {
        DenyUser => $user,
      },
    },

  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  AuthUserFile $auth_user_file
  AuthGroupFile $auth_group_file
  AuthOrder mod_auth_file.c

  AllowOverride off
  TimeoutIdle $timeout_idle

  TransferLog none
  WtmpLog off
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      my $client = ProFTPD::TestSuite::FTP->new('127.0.0.1', $port);
      $client->login($user, $passwd);
      $client->type('binary');

      my $conn = $client->retr_raw($test_file);
      unless ($conn) {
        die("RETR failed: " . $client->response_code() . " " .
          $client->response_msg());
      }

      my $buf;
      $conn->read($buf, 8192, 30);
      eval { $conn->close() };

      my $resp_code = $client->response_code();
      my $resp_msg = $client->response_msg();
      $self->assert_transfer_ok($resp_code, $resp_msg, 1);

      $client->quit();
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh, $timeout_idle + 2) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_reverse_stor_pasv {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  my $test_data = "Hello, Proxying World!\n";
  my $test_file = File::Spec->rel2abs("$tmpdir/test.txt");

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 12;

  my $proxy_config = get_reverse_proxy_config($tmpdir, $log_file, $vhost_port);

  my $timeout_idle = 10;

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20',

    AuthUserFile => $auth_user_file,
    AuthGroupFile => $auth_group_file,
    SocketBindTight => 'on',
    TimeoutIdle => $timeout_idle,
    UseIPv6 => 'on',

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },

    Limit => {
      LOGIN => {
        DenyUser => $user,
      },
    },

  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  AuthUserFile $auth_user_file
  AuthGroupFile $auth_group_file
  AuthOrder mod_auth_file.c

  AllowOverride off
  TimeoutIdle $timeout_idle

  TransferLog none
  WtmpLog off
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      my $client = ProFTPD::TestSuite::FTP->new('127.0.0.1', $port);
      $client->login($user, $passwd);

      my $conn = $client->stor_raw($test_file);
      unless ($conn) {
        die("STOR failed: " . $client->response_code() . " " .
          $client->response_msg());
      }

      my $buf = $test_data;
      $conn->write($buf, length($buf), 30);
      eval { $conn->close() };

      my $resp_code = $client->response_code();
      my $resp_msg = $client->response_msg();
      $self->assert_transfer_ok($resp_code, $resp_msg);

      $client->quit();

      $self->assert(-f $test_file,
        test_msg("File $test_file does not exist as expected"));

      my $expected = length($test_data);
      my $size = -s $test_file;
      $self->assert($expected == $size,
        test_msg("Expected size $expected, got $size"));
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh, $timeout_idle + 2) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_reverse_stor_port {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  my $test_data = "Hello, Proxying World!\n";
  my $test_file = File::Spec->rel2abs("$tmpdir/test.txt");

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 12;

  my $proxy_config = get_reverse_proxy_config($tmpdir, $log_file, $vhost_port);

  my $timeout_idle = 10;

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20',

    AuthUserFile => $auth_user_file,
    AuthGroupFile => $auth_group_file,
    SocketBindTight => 'on',
    TimeoutIdle => $timeout_idle,
    UseIPv6 => 'on',

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },

    Limit => {
      LOGIN => {
        DenyUser => $user,
      },
    },

  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  AuthUserFile $auth_user_file
  AuthGroupFile $auth_group_file
  AuthOrder mod_auth_file.c

  AllowOverride off
  TimeoutIdle $timeout_idle

  TransferLog none
  WtmpLog off
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      my $client = ProFTPD::TestSuite::FTP->new('127.0.0.1', $port, 1);
      $client->login($user, $passwd);

      my $conn = $client->stor_raw($test_file);
      unless ($conn) {
        die("STOR failed: " . $client->response_code() . " " .
          $client->response_msg());
      }

      my $buf = $test_data;
      $conn->write($buf, length($buf), 30);
      eval { $conn->close() };

      my $resp_code = $client->response_code();
      my $resp_msg = $client->response_msg();
      $self->assert_transfer_ok($resp_code, $resp_msg);

      $client->quit();

      $self->assert(-f $test_file,
        test_msg("File $test_file does not exist as expected"));

      my $expected = length($test_data);
      my $size = -s $test_file;
      $self->assert($expected == $size,
        test_msg("Expected size $expected, got $size"));
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh, $timeout_idle + 2) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_reverse_stor_large_file {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  my $test_datalen = (4 * 1024 * 1024);
  my $test_file = File::Spec->rel2abs("$tmpdir/test.txt");

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 12;

  my $proxy_config = get_reverse_proxy_config($tmpdir, $log_file, $vhost_port);

  my $timeout_idle = 120;

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20',

    AuthUserFile => $auth_user_file,
    AuthGroupFile => $auth_group_file,
    SocketBindTight => 'on',
    TimeoutIdle => $timeout_idle,
    UseIPv6 => 'on',

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },

    Limit => {
      LOGIN => {
        DenyUser => $user,
      },
    },

  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  AuthUserFile $auth_user_file
  AuthGroupFile $auth_group_file
  AuthOrder mod_auth_file.c

  AllowOverride off
  TimeoutIdle $timeout_idle

  TransferLog none
  WtmpLog off
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      my $client = ProFTPD::TestSuite::FTP->new('127.0.0.1', $port);
      $client->login($user, $passwd);
      $client->type('binary');

      my $conn = $client->stor_raw($test_file);
      unless ($conn) {
        die("STOR failed: " . $client->response_code() . " " .
          $client->response_msg());
      }

      my $buf = 'R' x $test_datalen;
      my $size = $conn->write($buf, length($buf), 30);
      eval { $conn->close() };

      my $resp_code = $client->response_code();
      my $resp_msg = $client->response_msg();
      $self->assert_transfer_ok($resp_code, $resp_msg);

      $client->quit();

      my $expected = $test_datalen;
      $self->assert($expected == $size,
        test_msg("Expected sent size $expected, got $size"));

      $self->assert(-f $test_file,
        test_msg("File $test_file does not exist as expected"));

      my $filesize = -s $test_file;
      $self->assert($expected == $filesize,
        test_msg("Expected file size $expected, got $filesize"));
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh, $timeout_idle + 2) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_reverse_stor_empty_file {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  my $test_datalen = 0;
  my $test_file = File::Spec->rel2abs("$tmpdir/test.txt");

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 12;

  my $proxy_config = get_reverse_proxy_config($tmpdir, $log_file, $vhost_port);

  my $timeout_idle = 120;

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20',

    AuthUserFile => $auth_user_file,
    AuthGroupFile => $auth_group_file,
    SocketBindTight => 'on',
    TimeoutIdle => $timeout_idle,
    UseIPv6 => 'on',

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },

    Limit => {
      LOGIN => {
        DenyUser => $user,
      },
    },

  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  AuthUserFile $auth_user_file
  AuthGroupFile $auth_group_file
  AuthOrder mod_auth_file.c

  AllowOverride off
  TimeoutIdle $timeout_idle

  TransferLog none
  WtmpLog off
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      my $client = ProFTPD::TestSuite::FTP->new('127.0.0.1', $port);
      $client->login($user, $passwd);
      $client->type('binary');

      my $conn = $client->stor_raw($test_file);
      unless ($conn) {
        die("STOR failed: " . $client->response_code() . " " .
          $client->response_msg());
      }

      eval { $conn->close() };

      my $resp_code = $client->response_code();
      my $resp_msg = $client->response_msg();
      $self->assert_transfer_ok($resp_code, $resp_msg);

      $client->quit();

      $self->assert(-f $test_file,
        test_msg("File $test_file does not exist as expected"));

      my $expected = $test_datalen;
      my $filesize = -s $test_file;
      $self->assert($expected == $filesize,
        test_msg("Expected file size $expected, got $filesize"));
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh, $timeout_idle + 2) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_reverse_stor_eperm {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  my $test_data = "Hello, Proxying World!\n";
  my $test_datalen = length($test_data);
  my $test_file = File::Spec->rel2abs("$tmpdir/test.txt");
  if (open(my $fh, "> $test_file")) {
    print $fh $test_data;

    unless (close($fh)) {
      die("Unable to write $test_file: $!");
    }

  } else {
    die("Unable to open $test_file: $!");
  }

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 12;

  my $proxy_config = get_reverse_proxy_config($tmpdir, $log_file, $vhost_port);

  my $timeout_idle = 10;

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20',

    AuthUserFile => $auth_user_file,
    AuthGroupFile => $auth_group_file,
    SocketBindTight => 'on',
    TimeoutIdle => $timeout_idle,
    UseIPv6 => 'on',

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },

    Limit => {
      LOGIN => {
        DenyUser => $user,
      },
    },

  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  AuthUserFile $auth_user_file
  AuthGroupFile $auth_group_file
  AuthOrder mod_auth_file.c

  AllowOverride off
  TimeoutIdle $timeout_idle

  TransferLog none
  WtmpLog off
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      my $client = ProFTPD::TestSuite::FTP->new('127.0.0.1', $port);
      $client->login($user, $passwd);
      $client->type('binary');

      my $conn = $client->stor_raw($test_file);
      if ($conn) {
        die("STOR succeeded unexpectedly");
      }

      my $resp_code = $client->response_code();
      my $resp_msg = $client->response_msg();

      $client->quit();

      my $expected = 550;
      $self->assert($expected == $resp_code,
        test_msg("Expected response code $expected, got $resp_code"));

      $expected = "$test_file: Overwrite permission denied";
      $self->assert($expected eq $resp_msg,
        test_msg("Expected response message '$expected', got '$resp_msg'"));
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh, $timeout_idle + 2) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_reverse_stor_abort {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  my $test_datalen = (4 * 1024 * 1024);
  my $test_file = File::Spec->rel2abs("$tmpdir/test.txt");

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 12;

  my $proxy_config = get_reverse_proxy_config($tmpdir, $log_file, $vhost_port);

  my $timeout_idle = 10;

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20',

    AuthUserFile => $auth_user_file,
    AuthGroupFile => $auth_group_file,
    SocketBindTight => 'on',
    TimeoutIdle => $timeout_idle,
    UseIPv6 => 'on',

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },

    Limit => {
      LOGIN => {
        DenyUser => $user,
      },
    },

  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  AuthUserFile $auth_user_file
  AuthGroupFile $auth_group_file
  AuthOrder mod_auth_file.c

  AllowOverride off
  TimeoutIdle $timeout_idle

  TransferLog none
  WtmpLog off
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      my $client = ProFTPD::TestSuite::FTP->new('127.0.0.1', $port);
      $client->login($user, $passwd);
      $client->type('binary');

      my $conn = $client->stor_raw($test_file);
      unless ($conn) {
        die("STOR failed: " . $client->response_code() . " " .
          $client->response_msg());
      }

      my $buf = 'R' x $test_datalen;
      $conn->write($buf, 8192, 30);
      eval { $conn->abort() };

      my $resp_code = $client->response_code();
      my $resp_msg = $client->response_msg();
      $self->assert_transfer_ok($resp_code, $resp_msg, 1);

      $client->quit();
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh, $timeout_idle + 2) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_reverse_rest_retr {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  my $test_data = "Hello, Proxying World!\n";
  my $test_datalen = length($test_data);
  my $test_file = File::Spec->rel2abs("$tmpdir/test.txt");
  if (open(my $fh, "> $test_file")) {
    print $fh $test_data;

    unless (close($fh)) {
      die("Unable to write $test_file: $!");
    }

  } else {
    die("Unable to open $test_file: $!");
  }

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 12;

  my $proxy_config = get_reverse_proxy_config($tmpdir, $log_file, $vhost_port);

  my $timeout_idle = 10;

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20',

    AuthUserFile => $auth_user_file,
    AuthGroupFile => $auth_group_file,
    SocketBindTight => 'on',
    TimeoutIdle => $timeout_idle,
    UseIPv6 => 'on',

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },

    Limit => {
      LOGIN => {
        DenyUser => $user,
      },
    },

  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  AuthUserFile $auth_user_file
  AuthGroupFile $auth_group_file
  AuthOrder mod_auth_file.c

  AllowOverride off
  TimeoutIdle $timeout_idle

  TransferLog none
  WtmpLog off
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      my $client = ProFTPD::TestSuite::FTP->new('127.0.0.1', $port);
      $client->login($user, $passwd);
      $client->type('binary');

      my $rest_len = $test_datalen - 1;
      my ($resp_code, $resp_msg) = $client->rest($rest_len);

      my $expected = 350;
      $self->assert($expected == $resp_code,
        test_msg("Expected response code $expected, got $resp_code"));

      $expected = "Restarting at $rest_len. Send STORE or RETRIEVE to initiate transfer";
      $self->assert($expected eq $resp_msg,
        test_msg("Expected response message '$expected', got '$resp_msg'"));

      my $conn = $client->retr_raw($test_file);
      unless ($conn) {
        die("RETR failed: " . $client->response_code() . " " .
          $client->response_msg());
      }

      my $buf;
      $conn->read($buf, 8192, 30);
      my $size = $conn->bytes_read();
      eval { $conn->close() };

      $resp_code = $client->response_code();
      $resp_msg = $client->response_msg();
      $self->assert_transfer_ok($resp_code, $resp_msg);

      $client->quit();

      my $expected = 1;
      $self->assert($expected == $size,
        test_msg("Expected received size $expected, got $size"));
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh, $timeout_idle + 2) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_reverse_rest_stor {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  my $test_data = "Hello, Proxying World!\n";
  my $test_datalen = length($test_data);
  my $test_file = File::Spec->rel2abs("$tmpdir/test.txt");
  if (open(my $fh, "> $test_file")) {
    print $fh $test_data;

    unless (close($fh)) {
      die("Unable to write $test_file: $!");
    }

  } else {
    die("Unable to open $test_file: $!");
  }

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 12;

  my $proxy_config = get_reverse_proxy_config($tmpdir, $log_file, $vhost_port);

  my $timeout_idle = 10;

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20',

    AuthUserFile => $auth_user_file,
    AuthGroupFile => $auth_group_file,
    SocketBindTight => 'on',
    TimeoutIdle => $timeout_idle,
    UseIPv6 => 'on',

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },

    Limit => {
      LOGIN => {
        DenyUser => $user,
      },
    },

  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  AuthUserFile $auth_user_file
  AuthGroupFile $auth_group_file
  AuthOrder mod_auth_file.c

  AllowOverride off
  AllowOverwrite on
  AllowStoreRestart on
  TimeoutIdle $timeout_idle

  TransferLog none
  WtmpLog off
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      my $client = ProFTPD::TestSuite::FTP->new('127.0.0.1', $port);
      $client->login($user, $passwd);
      $client->type('binary');

      my $rest_len = $test_datalen;
      my ($resp_code, $resp_msg) = $client->rest($rest_len);

      my $expected = 350;
      $self->assert($expected == $resp_code,
        test_msg("Expected response code $expected, got $resp_code"));

      $expected = "Restarting at $rest_len. Send STORE or RETRIEVE to initiate transfer";
      $self->assert($expected eq $resp_msg,
        test_msg("Expected response message '$expected', got '$resp_msg'"));

      my $conn = $client->stor_raw($test_file);
      unless ($conn) {
        die("STOR failed: " . $client->response_code() . " " .
          $client->response_msg());
      }

      my $buf = $test_data;
      my $size = $conn->write($buf, length($buf), 30);
      eval { $conn->close() };

      $resp_code = $client->response_code();
      $resp_msg = $client->response_msg();
      $self->assert_transfer_ok($resp_code, $resp_msg);

      $client->quit();

      my $expected = 2 * $test_datalen;
      my $size = -s $test_file;
      $self->assert($expected == $size,
        test_msg("Expected file size $expected, got $size"));
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh, $timeout_idle + 2) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_reverse_unknown_cmd {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 12;

  my $proxy_config = get_reverse_proxy_config($tmpdir, $log_file, $vhost_port);

  my $timeout_idle = 10;

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20',

    AuthUserFile => $auth_user_file,
    AuthGroupFile => $auth_group_file,
    SocketBindTight => 'on',
    TimeoutIdle => $timeout_idle,

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },

    Limit => {
      LOGIN => {
        DenyUser => $user,
      },
    },

  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  AuthUserFile $auth_user_file
  AuthGroupFile $auth_group_file
  AuthOrder mod_auth_file.c

  AllowOverride off
  TimeoutIdle $timeout_idle

  TransferLog none
  WtmpLog off
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      my $client = ProFTPD::TestSuite::FTP->new('127.0.0.1', $port);
      $client->login($user, $passwd);

      my $unknown_cmd = 'FOOBAR';
      eval { $client->quote($unknown_cmd, "BAZ") };
      unless ($@) {
        die("Unknown FTP command '$unknown_cmd' succeeded unexpectedly");
      }

      my $resp_code = $client->response_code();
      my $resp_msg = $client->response_msg();

      my $expected = 500;
      $self->assert($expected == $resp_code,
        test_msg("Expected response code $expected, got $resp_code"));

      $expected = "$unknown_cmd not understood";
      $self->assert($expected eq $resp_msg,
        test_msg("Expected response message '$expected', got '$resp_msg'"));
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh, $timeout_idle + 2) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_reverse_config_passiveports_pasv {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 12;

  my $proxy_config = get_reverse_proxy_config($tmpdir, $log_file, $vhost_port);

  my $timeout_idle = 10;

  my $min_port = 49152;
  my $max_port = 49652;

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20',

    AuthUserFile => $auth_user_file,
    AuthGroupFile => $auth_group_file,
    SocketBindTight => 'on',
    TimeoutIdle => $timeout_idle,

    PassivePorts => "$min_port $max_port",

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },
  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  AuthUserFile $auth_user_file
  AuthGroupFile $auth_group_file
  AuthOrder mod_auth_file.c

  AllowOverride off
  TimeoutIdle $timeout_idle

  TransferLog none
  WtmpLog off
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      my $client = ProFTPD::TestSuite::FTP->new('127.0.0.1', $port);
      $client->login($user, $passwd);

      my ($resp_code, $resp_msg) = $client->pasv();

      my $expected;
      $expected = 227;
      $self->assert($expected == $resp_code,
        test_msg("Expected response code $expected, got $resp_code"));

      $expected = '^Entering Passive Mode \(\d+,\d+,\d+,\d+,\d+,\d+\)';
      $self->assert(qr/$expected/, $resp_msg,
        test_msg("Expected response message '$expected', got '$resp_msg'"));

      # Make sure that the chosen port is within our configured PassivePorts
      # range.
      if ($resp_msg =~ /^Entering Passive Mode \(\d+,\d+,\d+,\d+,(\d+),(\d+)\)/) {
        my $p1 = $1;
        my $p2 = $2;

        my $port = ($p1 * 256) + $p2;
        $self->assert($port >= $min_port && $port <= $max_port,
          test_msg("Selected port $port not within PassivePorts $min_port $max_port"));

      } else {
        die("PASV response message '$resp_msg' not matched");
      }

      ($resp_code, $resp_msg) = $client->quit();

      $expected = 221;
      $self->assert($expected == $resp_code,
        test_msg("Expected response code $expected, got $resp_code"));

      $expected = 'Goodbye.';
      $self->assert($expected eq $resp_msg,
        test_msg("Expected response message '$expected', got '$resp_msg'"));
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh, $timeout_idle + 2) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_reverse_config_passiveports_epsv {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 12;

  my $proxy_config = get_reverse_proxy_config($tmpdir, $log_file, $vhost_port);

  my $timeout_idle = 10;

  my $min_port = 49152;
  my $max_port = 49652;

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20',

    AuthUserFile => $auth_user_file,
    AuthGroupFile => $auth_group_file,
    SocketBindTight => 'on',
    TimeoutIdle => $timeout_idle,

    PassivePorts => "$min_port $max_port",

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },
  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  AuthUserFile $auth_user_file
  AuthGroupFile $auth_group_file
  AuthOrder mod_auth_file.c

  AllowOverride off
  TimeoutIdle $timeout_idle

  TransferLog none
  WtmpLog off
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      my $client = ProFTPD::TestSuite::FTP->new('127.0.0.1', $port);
      $client->login($user, $passwd);

      my ($resp_code, $resp_msg) = $client->epsv();

      my $expected;
      $expected = 229;
      $self->assert($expected == $resp_code,
        test_msg("Expected response code $expected, got $resp_code"));

      $expected = '^Entering Extended Passive Mode \(\|\|\|\d+\|\)';
      $self->assert(qr/$expected/, $resp_msg,
        test_msg("Expected response message '$expected', got '$resp_msg'"));

      # Make sure that the chosen port is within our configured PassivePorts
      # range.
      if ($resp_msg =~ /^Entering Extended Passive Mode \(\|\|\|(\d+)\|\)/) {
        my $port = $1;
        $self->assert($port >= $min_port && $port <= $max_port,
          test_msg("Selected port $port not within PassivePorts $min_port $max_port"));

      } else {
        die("EPSV response message '$resp_msg' not matched");
      }

      ($resp_code, $resp_msg) = $client->quit();

      $expected = 221;
      $self->assert($expected == $resp_code,
        test_msg("Expected response code $expected, got $resp_code"));

      $expected = 'Goodbye.';
      $self->assert($expected eq $resp_msg,
        test_msg("Expected response message '$expected', got '$resp_msg'"));
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh, $timeout_idle + 2) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_reverse_config_masqueradeaddress {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 12;

  my $proxy_config = get_reverse_proxy_config($tmpdir, $log_file, $vhost_port);

  my $timeout_idle = 10;

  my $masq_addr = '1.2.3.4';

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20',

    AuthUserFile => $auth_user_file,
    AuthGroupFile => $auth_group_file,
    SocketBindTight => 'on',
    TimeoutIdle => $timeout_idle,

    MasqueradeAddress => $masq_addr,

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },
  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  AuthUserFile $auth_user_file
  AuthGroupFile $auth_group_file
  AuthOrder mod_auth_file.c

  AllowOverride off
  TimeoutIdle $timeout_idle

  TransferLog none
  WtmpLog off
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      my $client = ProFTPD::TestSuite::FTP->new('127.0.0.1', $port);
      $client->login($user, $passwd);

      my ($resp_code, $resp_msg) = $client->pasv();

      my $expected;
      $expected = 227;
      $self->assert($expected == $resp_code,
        test_msg("Expected response code $expected, got $resp_code"));

      $expected = '^Entering Passive Mode \(\d+,\d+,\d+,\d+,\d+,\d+\)';
      $self->assert(qr/$expected/, $resp_msg,
        test_msg("Expected response message '$expected', got '$resp_msg'"));

      # Make sure that the reported address is our MasqueradeAddress.
      if ($resp_msg =~ /^Entering Passive Mode \((\d+,\d+,\d+,\d+),\d+,\d+\)/) {
        my $addr = $1;
        $addr =~ s/,/./g;

        $self->assert($addr eq $masq_addr,
          test_msg("Expected address '$masq_addr', got '$addr'"));

      } else {
        die("PASV response message '$resp_msg' not matched");
      }

      ($resp_code, $resp_msg) = $client->quit();

      $expected = 221;
      $self->assert($expected == $resp_code,
        test_msg("Expected response code $expected, got $resp_code"));

      $expected = 'Goodbye.';
      $self->assert($expected eq $resp_msg,
        test_msg("Expected response message '$expected', got '$resp_msg'"));
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh, $timeout_idle + 2) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_reverse_config_allowforeignaddress_port {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 12;

  my $proxy_config = get_reverse_proxy_config($tmpdir, $log_file, $vhost_port);

  my $timeout_idle = 10;

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20',

    AuthUserFile => $auth_user_file,
    AuthGroupFile => $auth_group_file,
    SocketBindTight => 'on',
    TimeoutIdle => $timeout_idle,

    AllowForeignAddress => 'on',

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },
  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  AuthUserFile $auth_user_file
  AuthGroupFile $auth_group_file
  AuthOrder mod_auth_file.c

  AllowOverride off
  TimeoutIdle $timeout_idle

  TransferLog none
  WtmpLog off
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      my $client = ProFTPD::TestSuite::FTP->new('127.0.0.1', $port);
      $client->login($user, $passwd);

      my ($resp_code, $resp_msg) = $client->port('1,2,3,4,192,168');

      my $expected;
      $expected = 200;
      $self->assert($expected == $resp_code,
        test_msg("Expected response code $expected, got $resp_code"));

      $expected = 'PORT command successful';
      $self->assert($expected eq $resp_msg,
        test_msg("Expected response message '$expected', got '$resp_msg'"));

      ($resp_code, $resp_msg) = $client->quit();

      $expected = 221;
      $self->assert($expected == $resp_code,
        test_msg("Expected response code $expected, got $resp_code"));

      $expected = 'Goodbye.';
      $self->assert($expected eq $resp_msg,
        test_msg("Expected response message '$expected', got '$resp_msg'"));
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh, $timeout_idle + 2) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_reverse_config_allowforeignaddress_eprt {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 12;

  my $proxy_config = get_reverse_proxy_config($tmpdir, $log_file, $vhost_port);

  my $timeout_idle = 10;

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20',

    AuthUserFile => $auth_user_file,
    AuthGroupFile => $auth_group_file,
    SocketBindTight => 'on',
    TimeoutIdle => $timeout_idle,

    AllowForeignAddress => 'on',

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },
  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  AuthUserFile $auth_user_file
  AuthGroupFile $auth_group_file
  AuthOrder mod_auth_file.c

  AllowOverride off
  TimeoutIdle $timeout_idle

  TransferLog none
  WtmpLog off
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      my $client = ProFTPD::TestSuite::FTP->new('127.0.0.1', $port);
      $client->login($user, $passwd);

      my ($resp_code, $resp_msg) = $client->eprt('|1|1.2.3.4|49152|');

      my $expected;
      $expected = 200;
      $self->assert($expected == $resp_code,
        test_msg("Expected response code $expected, got $resp_code"));

      $expected = 'EPRT command successful';
      $self->assert($expected eq $resp_msg,
        test_msg("Expected response message '$expected', got '$resp_msg'"));

      ($resp_code, $resp_msg) = $client->quit();

      $expected = 221;
      $self->assert($expected == $resp_code,
        test_msg("Expected response code $expected, got $resp_code"));

      $expected = 'Goodbye.';
      $self->assert($expected eq $resp_msg,
        test_msg("Expected response message '$expected', got '$resp_msg'"));
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh, $timeout_idle + 2) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_reverse_config_timeoutidle_frontend {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 12;

  my $proxy_config = get_reverse_proxy_config($tmpdir, $log_file, $vhost_port);

  my $frontend_timeoutidle = 4;
  my $frontend_timeout_delay = $frontend_timeoutidle + 2;
  my $backend_timeoutidle = 10;

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20',

    AuthUserFile => $auth_user_file,
    AuthGroupFile => $auth_group_file,
    SocketBindTight => 'on',

    TimeoutIdle => $frontend_timeoutidle,

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },
  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  AuthUserFile $auth_user_file
  AuthGroupFile $auth_group_file
  AuthOrder mod_auth_file.c

  AllowOverride off
  TimeoutIdle $backend_timeoutidle

  TransferLog none
  WtmpLog off
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      my $client = ProFTPD::TestSuite::FTP->new('127.0.0.1', $port);
      $client->login($user, $passwd);

      # Wait for more than the frontend TimeoutIdle period
      if ($ENV{TEST_VERBOSE}) {
        print STDOUT " + sleeping for $frontend_timeout_delay secs for TimeoutIdle\n";
      }
      sleep($frontend_timeout_delay);

      eval { $client->noop() };
      unless ($@) {
        die("NOOP succeeded unexpectedly");
      }

      my $resp_code = $client->response_code();
      my $resp_msg = $client->response_msg();

      my $expected;
      $expected = 421;
      $self->assert($expected == $resp_code,
        test_msg("Expected response code $expected, got $resp_code"));

      $expected = "Idle timeout ($frontend_timeoutidle seconds): closing control connection";
      $self->assert($expected eq $resp_msg,
        test_msg("Expected response message '$expected', got '$resp_msg'"));
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh, $backend_timeoutidle + 2) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_reverse_config_timeoutidle_backend {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 12;

  my $proxy_config = get_reverse_proxy_config($tmpdir, $log_file, $vhost_port);

  my $frontend_timeoutidle = 10;
  my $frontend_timeout_delay = $frontend_timeoutidle - 2;
  my $backend_timeoutidle = 4;

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20',

    AuthUserFile => $auth_user_file,
    AuthGroupFile => $auth_group_file,
    SocketBindTight => 'on',

    TimeoutIdle => $frontend_timeoutidle,

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },
  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  AuthUserFile $auth_user_file
  AuthGroupFile $auth_group_file
  AuthOrder mod_auth_file.c

  AllowOverride off
  TimeoutIdle $backend_timeoutidle

  TransferLog none
  WtmpLog off
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      my $client = ProFTPD::TestSuite::FTP->new('127.0.0.1', $port);
      $client->login($user, $passwd);

      # Wait for more than the frontend TimeoutIdle period
      if ($ENV{TEST_VERBOSE}) {
        print STDOUT " + sleeping for $frontend_timeout_delay secs for TimeoutIdle\n";
      }
      sleep($frontend_timeout_delay);

      eval { $client->noop() };
      unless ($@) {
        die("NOOP succeeded unexpectedly");
      }

      my $resp_code = $client->response_code();
      my $resp_msg = $client->response_msg();

      my $expected;
      $expected = 421;
      $self->assert($expected == $resp_code,
        test_msg("Expected response code $expected, got $resp_code"));

      $expected = "Idle timeout ($backend_timeoutidle seconds): closing control connection";
      $self->assert($expected eq $resp_msg,
        test_msg("Expected response message '$expected', got '$resp_msg'"));
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh, $frontend_timeoutidle + 2) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_reverse_config_timeoutlogin_frontend {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 12;

  my $proxy_config = get_reverse_proxy_config($tmpdir, $log_file, $vhost_port);

  my $frontend_timeoutidle = 10;
  my $frontend_timeoutlogin = 2;
  my $frontend_timeout_delay = $frontend_timeoutlogin + 2;

  my $backend_timeoutidle = 10;

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20',

    AuthUserFile => $auth_user_file,
    AuthGroupFile => $auth_group_file,
    SocketBindTight => 'on',

    TimeoutIdle => $frontend_timeoutidle,
    TimeoutLogin => $frontend_timeoutlogin,

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },
  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  AuthUserFile $auth_user_file
  AuthGroupFile $auth_group_file
  AuthOrder mod_auth_file.c

  AllowOverride off
  TimeoutIdle $backend_timeoutidle

  TransferLog none
  WtmpLog off
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      my $client = ProFTPD::TestSuite::FTP->new('127.0.0.1', $port);
      $client->login($user, $passwd);

      # Wait for more than the frontend TimeoutLogin period
      if ($ENV{TEST_VERBOSE}) {
        print STDOUT " + sleeping for $frontend_timeout_delay secs for TimeoutLogin\n";
      }
      sleep($frontend_timeout_delay);

      # Since we've authenticated to the backend, the frontend's TimeoutLogin
      # should not kick in; mod_proxy should have removed it.  Which means
      # that this NOOP should work.
      $client->noop();

      $client->quit();
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh, $frontend_timeoutidle + 2) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_reverse_config_timeoutnoxfer_frontend {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 12;

  my $proxy_config = get_reverse_proxy_config($tmpdir, $log_file, $vhost_port);

  my $frontend_timeoutnoxfer = 2;
  my $frontend_timeout_delay = $frontend_timeoutnoxfer + 2;
  my $backend_timeoutnoxfer = 10;

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20',

    AuthUserFile => $auth_user_file,
    AuthGroupFile => $auth_group_file,
    SocketBindTight => 'on',

    TimeoutNoTransfer => $frontend_timeoutnoxfer,

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },
  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  AuthUserFile $auth_user_file
  AuthGroupFile $auth_group_file
  AuthOrder mod_auth_file.c

  AllowOverride off
  TimeoutNoTransfer $backend_timeoutnoxfer

  TransferLog none
  WtmpLog off
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      my $client = ProFTPD::TestSuite::FTP->new('127.0.0.1', $port);
      $client->login($user, $passwd);

      # Wait for more than the frontend TimeoutNoTransfer period
      if ($ENV{TEST_VERBOSE}) {
        print STDOUT " + sleeping for $frontend_timeout_delay secs for TimeoutNoTransfer\n";
      }
      sleep($frontend_timeout_delay);

      my $conn = $client->list_raw();
      if ($conn) {
        die("LIST succeeded unexpectedly");
      }

      my $resp_code = $client->response_code();
      my $resp_msg = $client->response_msg();

      my $expected;
      $expected = 421;
      $self->assert($expected == $resp_code,
        test_msg("Expected response code $expected, got $resp_code"));

      $expected = "No transfer timeout ($frontend_timeoutnoxfer seconds): closing control connection";
      $self->assert($expected eq $resp_msg,
        test_msg("Expected response message '$expected', got '$resp_msg'"));
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh, $backend_timeoutnoxfer + 2) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_reverse_config_timeoutnoxfer_backend {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 12;

  my $proxy_config = get_reverse_proxy_config($tmpdir, $log_file, $vhost_port);

  my $frontend_timeoutnoxfer = 10;
  my $frontend_timeout_delay = $frontend_timeoutnoxfer - 2;
  my $backend_timeoutnoxfer = 2;

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20',

    AuthUserFile => $auth_user_file,
    AuthGroupFile => $auth_group_file,
    SocketBindTight => 'on',

    TimeoutNoTransfer => $frontend_timeoutnoxfer,

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },
  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  AuthUserFile $auth_user_file
  AuthGroupFile $auth_group_file
  AuthOrder mod_auth_file.c

  AllowOverride off
  TimeoutNoTransfer $backend_timeoutnoxfer

  TransferLog none
  WtmpLog off
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      my $client = ProFTPD::TestSuite::FTP->new('127.0.0.1', $port);
      $client->login($user, $passwd);

      # Wait for more than the frontend TimeoutNoTransfer period
      if ($ENV{TEST_VERBOSE}) {
        print STDOUT " + sleeping for $frontend_timeout_delay secs for TimeoutNoTransfer\n";
      }
      sleep($frontend_timeout_delay);

      my $conn = $client->list_raw();
      if ($conn) {
        die("LIST succeeded unexpectedly");
      }

      my $resp_code = $client->response_code();
      my $resp_msg = $client->response_msg();

      my $expected;
      $expected = 421;
      $self->assert($expected == $resp_code,
        test_msg("Expected response code $expected, got $resp_code"));

      $expected = "No transfer timeout ($backend_timeoutnoxfer seconds): closing control connection";
      $self->assert($expected eq $resp_msg,
        test_msg("Expected response message '$expected', got '$resp_msg'"));
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh, $frontend_timeoutnoxfer + 2) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_reverse_config_timeoutstalled_frontend {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 12;

  my $proxy_config = get_reverse_proxy_config($tmpdir, $log_file, $vhost_port);

  my $frontend_timeoutstalled = 2;
  my $frontend_timeout_delay = $frontend_timeoutstalled + 2;
  my $backend_timeoutstalled = 10;

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20',

    AuthUserFile => $auth_user_file,
    AuthGroupFile => $auth_group_file,
    SocketBindTight => 'on',

    TimeoutStalled => $frontend_timeoutstalled,

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },
  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  AuthUserFile $auth_user_file
  AuthGroupFile $auth_group_file
  AuthOrder mod_auth_file.c

  AllowOverride off
  TimeoutStalled $backend_timeoutstalled

  TransferLog none
  WtmpLog off
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      my $client = ProFTPD::TestSuite::FTP->new('127.0.0.1', $port);
      $client->login($user, $passwd);

      my $conn = $client->stor_raw('test.txt');
      unless ($conn) {
        die("STOR failed: " . $client->response_code() . " " .
          $client->response_msg());
      }

      # Wait for more than the frontend TimeoutStalled period
      if ($ENV{TEST_VERBOSE}) {
        print STDOUT " + sleeping for $frontend_timeout_delay secs for TimeoutStalled\n";
      }
      sleep($frontend_timeout_delay);

      my $buf = "Hello, World!\n";
      $conn->write($buf, length($buf), 25);
      eval { $conn->close() };

      eval { $client->noop() };
      unless ($@) {
        die("NOOP succeeded unexpectedly");
      }

      my $resp_code = $client->response_code();
      my $resp_msg = $client->response_msg();

      my $expected;

      # Perl's Net::Cmd module uses a very non-standard 599 code to indicate
      # that the connection is closed
      $expected = 599;
      $self->assert($expected == $resp_code,
        test_msg("Expected response code $expected, got $resp_code"));

      $expected = "Connection closed";
      $self->assert($expected eq $resp_msg,
        test_msg("Expected response message '$expected', got '$resp_msg'"));
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh, $backend_timeoutstalled + 2) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_reverse_config_timeoutstalled_backend {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 12;

  my $proxy_config = get_reverse_proxy_config($tmpdir, $log_file, $vhost_port);

  my $frontend_timeoutstalled = 12;
  my $backend_timeoutstalled = 2;
  my $frontend_timeout_delay = $backend_timeoutstalled + 2;

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20',

    AuthUserFile => $auth_user_file,
    AuthGroupFile => $auth_group_file,
    SocketBindTight => 'on',

    TimeoutStalled => $frontend_timeoutstalled,

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },
  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  AuthUserFile $auth_user_file
  AuthGroupFile $auth_group_file
  AuthOrder mod_auth_file.c

  AllowOverride off
  TimeoutStalled $backend_timeoutstalled

  TransferLog none
  WtmpLog off
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      my $client = ProFTPD::TestSuite::FTP->new('127.0.0.1', $port);
      $client->login($user, $passwd);

      my $conn = $client->stor_raw('test.txt');
      unless ($conn) {
        die("STOR failed: " . $client->response_code() . " " .
          $client->response_msg());
      }

      # Wait for more than the backend TimeoutStalled period
      if ($ENV{TEST_VERBOSE}) {
        print STDOUT " + sleeping for $frontend_timeout_delay secs for TimeoutStalled\n";
      }
      sleep($frontend_timeout_delay);

      my $buf = "Hello, World!\n";
      $conn->write($buf, length($buf), 25);
      eval { $conn->close() };

      eval { $client->noop() };
      unless ($@) {
        die("NOOP succeeded unexpectedly");
      }

      my $resp_code = $client->response_code();
      my $resp_msg = $client->response_msg();

      my $expected;

      # Perl's Net::Cmd module uses a very non-standard 599 code to indicate
      # that the connection is closed
      $expected = 599;
      $self->assert($expected == $resp_code,
        test_msg("Expected response code $expected, got $resp_code"));

      $expected = "Connection closed";
      $self->assert($expected eq $resp_msg,
        test_msg("Expected response message '$expected', got '$resp_msg'"));
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh, $frontend_timeoutstalled + 2) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_reverse_config_datatransferpolicy_pasv_list_pasv {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 12;

  my $proxy_config = get_reverse_proxy_config($tmpdir, $log_file, $vhost_port);
  $proxy_config->{ProxyDataTransferPolicy} = 'PASV';

  my $timeout_idle = 10;

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20',

    AuthUserFile => $auth_user_file,
    AuthGroupFile => $auth_group_file,
    SocketBindTight => 'on',
    TimeoutIdle => $timeout_idle,

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },

    Limit => {
      LOGIN => {
        DenyUser => $user,
      },
    },

  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  AuthUserFile $auth_user_file
  AuthGroupFile $auth_group_file
  AuthOrder mod_auth_file.c

  AllowOverride off
  TimeoutIdle $timeout_idle

  TransferLog none
  WtmpLog off
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      my $client = ProFTPD::TestSuite::FTP->new('127.0.0.1', $port);
      $client->login($user, $passwd);

      my $conn = $client->list_raw();
      unless ($conn) {
        die("Failed to LIST: " . $client->response_code() . ' ' .
          $client->response_msg());
      }

      my $buf;
      $conn->read($buf, 8192, 10);
      eval { $conn->close() };

      my $resp_code = $client->response_code();
      my $resp_msg = $client->response_msg();
      $self->assert_transfer_ok($resp_code, $resp_msg);

      ($resp_code, $resp_msg) = $client->quit();

      my $expected = 221;
      $self->assert($expected == $resp_code,
        test_msg("Expected response code $expected, got $resp_code"));

      $expected = 'Goodbye.';
      $self->assert($expected eq $resp_msg,
        test_msg("Expected response message '$expected', got '$resp_msg'"));
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh, $timeout_idle + 2) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_reverse_config_datatransferpolicy_pasv_list_port {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 12;

  my $proxy_config = get_reverse_proxy_config($tmpdir, $log_file, $vhost_port);
  $proxy_config->{ProxyDataTransferPolicy} = 'PASV';

  my $timeout_idle = 10;

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20',

    AuthUserFile => $auth_user_file,
    AuthGroupFile => $auth_group_file,
    SocketBindTight => 'on',
    TimeoutIdle => $timeout_idle,

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },

    Limit => {
      LOGIN => {
        DenyUser => $user,
      },
    },

  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  AuthUserFile $auth_user_file
  AuthGroupFile $auth_group_file
  AuthOrder mod_auth_file.c

  AllowOverride off
  TimeoutIdle $timeout_idle

  TransferLog none
  WtmpLog off
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      my $client = ProFTPD::TestSuite::FTP->new('127.0.0.1', $port, 1);
      $client->login($user, $passwd);

      my $conn = $client->list_raw();
      unless ($conn) {
        die("Failed to LIST: " . $client->response_code() . ' ' .
          $client->response_msg());
      }

      my $buf;
      $conn->read($buf, 8192, 10);
      eval { $conn->close() };

      my $resp_code = $client->response_code();
      my $resp_msg = $client->response_msg();
      $self->assert_transfer_ok($resp_code, $resp_msg);

      ($resp_code, $resp_msg) = $client->quit();

      my $expected = 221;
      $self->assert($expected == $resp_code,
        test_msg("Expected response code $expected, got $resp_code"));

      $expected = 'Goodbye.';
      $self->assert($expected eq $resp_msg,
        test_msg("Expected response message '$expected', got '$resp_msg'"));
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh, $timeout_idle + 2) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_reverse_config_datatransferpolicy_port_list_pasv {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 12;

  my $proxy_config = get_reverse_proxy_config($tmpdir, $log_file, $vhost_port);
  $proxy_config->{ProxyDataTransferPolicy} = 'PORT';

  my $timeout_idle = 10;

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20',

    AuthUserFile => $auth_user_file,
    AuthGroupFile => $auth_group_file,
    SocketBindTight => 'on',
    TimeoutIdle => $timeout_idle,

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },

    Limit => {
      LOGIN => {
        DenyUser => $user,
      },
    },

  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  AuthUserFile $auth_user_file
  AuthGroupFile $auth_group_file
  AuthOrder mod_auth_file.c

  AllowOverride off
  TimeoutIdle $timeout_idle

  TransferLog none
  WtmpLog off
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      my $client = ProFTPD::TestSuite::FTP->new('127.0.0.1', $port);
      $client->login($user, $passwd);

      my $conn = $client->list_raw();
      unless ($conn) {
        die("Failed to LIST: " . $client->response_code() . ' ' .
          $client->response_msg());
      }

      my $buf;
      $conn->read($buf, 8192, 10);
      eval { $conn->close() };

      my $resp_code = $client->response_code();
      my $resp_msg = $client->response_msg();
      $self->assert_transfer_ok($resp_code, $resp_msg);

      ($resp_code, $resp_msg) = $client->quit();

      my $expected = 221;
      $self->assert($expected == $resp_code,
        test_msg("Expected response code $expected, got $resp_code"));

      $expected = 'Goodbye.';
      $self->assert($expected eq $resp_msg,
        test_msg("Expected response message '$expected', got '$resp_msg'"));
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh, $timeout_idle + 2) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_reverse_config_datatransferpolicy_port_list_port {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 12;

  my $proxy_config = get_reverse_proxy_config($tmpdir, $log_file, $vhost_port);
  $proxy_config->{ProxyDataTransferPolicy} = 'PORT';

  my $timeout_idle = 10;

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20',

    AuthUserFile => $auth_user_file,
    AuthGroupFile => $auth_group_file,
    SocketBindTight => 'on',
    TimeoutIdle => $timeout_idle,

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },

    Limit => {
      LOGIN => {
        DenyUser => $user,
      },
    },

  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  AuthUserFile $auth_user_file
  AuthGroupFile $auth_group_file
  AuthOrder mod_auth_file.c

  AllowOverride off
  TimeoutIdle $timeout_idle

  TransferLog none
  WtmpLog off
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      my $client = ProFTPD::TestSuite::FTP->new('127.0.0.1', $port, 1);
      $client->login($user, $passwd);

      my $conn = $client->list_raw();
      unless ($conn) {
        die("Failed to LIST: " . $client->response_code() . ' ' .
          $client->response_msg());
      }

      my $buf;
      $conn->read($buf, 8192, 10);
      eval { $conn->close() };

      my $resp_code = $client->response_code();
      my $resp_msg = $client->response_msg();
      $self->assert_transfer_ok($resp_code, $resp_msg);

      ($resp_code, $resp_msg) = $client->quit();

      my $expected = 221;
      $self->assert($expected == $resp_code,
        test_msg("Expected response code $expected, got $resp_code"));

      $expected = 'Goodbye.';
      $self->assert($expected eq $resp_msg,
        test_msg("Expected response message '$expected', got '$resp_msg'"));
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh, $timeout_idle + 2) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_reverse_config_datatransferpolicy_epsv_list_pasv {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 12;

  my $proxy_config = get_reverse_proxy_config($tmpdir, $log_file, $vhost_port);
  $proxy_config->{ProxyDataTransferPolicy} = 'EPSV';

  my $timeout_idle = 10;

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20',

    AuthUserFile => $auth_user_file,
    AuthGroupFile => $auth_group_file,
    SocketBindTight => 'on',
    TimeoutIdle => $timeout_idle,

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },

    Limit => {
      LOGIN => {
        DenyUser => $user,
      },
    },

  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  AuthUserFile $auth_user_file
  AuthGroupFile $auth_group_file
  AuthOrder mod_auth_file.c

  AllowOverride off
  TimeoutIdle $timeout_idle

  TransferLog none
  WtmpLog off
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      my $client = ProFTPD::TestSuite::FTP->new('127.0.0.1', $port);
      $client->login($user, $passwd);

      my $conn = $client->list_raw();
      unless ($conn) {
        die("Failed to LIST: " . $client->response_code() . ' ' .
          $client->response_msg());
      }

      my $buf;
      $conn->read($buf, 8192, 10);
      eval { $conn->close() };

      my $resp_code = $client->response_code();
      my $resp_msg = $client->response_msg();
      $self->assert_transfer_ok($resp_code, $resp_msg);

      ($resp_code, $resp_msg) = $client->quit();

      my $expected = 221;
      $self->assert($expected == $resp_code,
        test_msg("Expected response code $expected, got $resp_code"));

      $expected = 'Goodbye.';
      $self->assert($expected eq $resp_msg,
        test_msg("Expected response message '$expected', got '$resp_msg'"));
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh, $timeout_idle + 2) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_reverse_config_datatransferpolicy_epsv_list_port {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 12;

  my $proxy_config = get_reverse_proxy_config($tmpdir, $log_file, $vhost_port);
  $proxy_config->{ProxyDataTransferPolicy} = 'EPSV';

  my $timeout_idle = 10;

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20 proxy.ftp.xfer:20',

    AuthUserFile => $auth_user_file,
    AuthGroupFile => $auth_group_file,
    SocketBindTight => 'on',
    TimeoutIdle => $timeout_idle,

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },

    Limit => {
      LOGIN => {
        DenyUser => $user,
      },
    },

  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  AuthUserFile $auth_user_file
  AuthGroupFile $auth_group_file
  AuthOrder mod_auth_file.c

  AllowOverride off
  TimeoutIdle $timeout_idle

  TransferLog none
  WtmpLog off
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      my $client = ProFTPD::TestSuite::FTP->new('127.0.0.1', $port, 1);
      $client->login($user, $passwd);

      my $conn = $client->list_raw();
      unless ($conn) {
        die("Failed to LIST: " . $client->response_code() . ' ' .
          $client->response_msg());
      }

      my $buf;
      $conn->read($buf, 8192, 10);
      eval { $conn->close() };

      my $resp_code = $client->response_code();
      my $resp_msg = $client->response_msg();
      $self->assert_transfer_ok($resp_code, $resp_msg);

      ($resp_code, $resp_msg) = $client->quit();

      my $expected = 221;
      $self->assert($expected == $resp_code,
        test_msg("Expected response code $expected, got $resp_code"));

      $expected = 'Goodbye.';
      $self->assert($expected eq $resp_msg,
        test_msg("Expected response message '$expected', got '$resp_msg'"));
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh, $timeout_idle + 2) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_reverse_config_datatransferpolicy_eprt_list_pasv {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 12;

  my $proxy_config = get_reverse_proxy_config($tmpdir, $log_file, $vhost_port);
  $proxy_config->{ProxyDataTransferPolicy} = 'EPRT';

  my $timeout_idle = 10;

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20',

    AuthUserFile => $auth_user_file,
    AuthGroupFile => $auth_group_file,
    SocketBindTight => 'on',
    TimeoutIdle => $timeout_idle,

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },

    Limit => {
      LOGIN => {
        DenyUser => $user,
      },
    },

  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  AuthUserFile $auth_user_file
  AuthGroupFile $auth_group_file
  AuthOrder mod_auth_file.c

  AllowOverride off
  TimeoutIdle $timeout_idle

  TransferLog none
  WtmpLog off
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      my $client = ProFTPD::TestSuite::FTP->new('127.0.0.1', $port);
      $client->login($user, $passwd);

      my $conn = $client->list_raw();
      unless ($conn) {
        die("Failed to LIST: " . $client->response_code() . ' ' .
          $client->response_msg());
      }

      my $buf;
      $conn->read($buf, 8192, 10);
      eval { $conn->close() };

      my $resp_code = $client->response_code();
      my $resp_msg = $client->response_msg();
      $self->assert_transfer_ok($resp_code, $resp_msg);

      ($resp_code, $resp_msg) = $client->quit();

      my $expected = 221;
      $self->assert($expected == $resp_code,
        test_msg("Expected response code $expected, got $resp_code"));

      $expected = 'Goodbye.';
      $self->assert($expected eq $resp_msg,
        test_msg("Expected response message '$expected', got '$resp_msg'"));
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh, $timeout_idle + 2) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_reverse_config_datatransferpolicy_eprt_list_port {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 12;

  my $proxy_config = get_reverse_proxy_config($tmpdir, $log_file, $vhost_port);
  $proxy_config->{ProxyDataTransferPolicy} = 'EPRT';

  my $timeout_idle = 10;

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20',

    AuthUserFile => $auth_user_file,
    AuthGroupFile => $auth_group_file,
    SocketBindTight => 'on',
    TimeoutIdle => $timeout_idle,

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },

    Limit => {
      LOGIN => {
        DenyUser => $user,
      },
    },

  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  AuthUserFile $auth_user_file
  AuthGroupFile $auth_group_file
  AuthOrder mod_auth_file.c

  AllowOverride off
  TimeoutIdle $timeout_idle

  TransferLog none
  WtmpLog off
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      my $client = ProFTPD::TestSuite::FTP->new('127.0.0.1', $port, 1);
      $client->login($user, $passwd);

      my $conn = $client->list_raw();
      unless ($conn) {
        die("Failed to LIST: " . $client->response_code() . ' ' .
          $client->response_msg());
      }

      my $buf;
      $conn->read($buf, 8192, 10);
      eval { $conn->close() };

      my $resp_code = $client->response_code();
      my $resp_msg = $client->response_msg();
      $self->assert_transfer_ok($resp_code, $resp_msg);

      ($resp_code, $resp_msg) = $client->quit();

      my $expected = 221;
      $self->assert($expected == $resp_code,
        test_msg("Expected response code $expected, got $resp_code"));

      $expected = 'Goodbye.';
      $self->assert($expected eq $resp_msg,
        test_msg("Expected response message '$expected', got '$resp_msg'"));
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh, $timeout_idle + 2) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_reverse_config_datatransferpolicy_active_list_pasv {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 12;

  my $proxy_config = get_reverse_proxy_config($tmpdir, $log_file, $vhost_port);
  $proxy_config->{ProxyDataTransferPolicy} = 'active';

  my $timeout_idle = 10;

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20',

    AuthUserFile => $auth_user_file,
    AuthGroupFile => $auth_group_file,
    SocketBindTight => 'on',
    TimeoutIdle => $timeout_idle,

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },

    Limit => {
      LOGIN => {
        DenyUser => $user,
      },
    },

  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  AuthUserFile $auth_user_file
  AuthGroupFile $auth_group_file
  AuthOrder mod_auth_file.c

  AllowOverride off
  TimeoutIdle $timeout_idle

  TransferLog none
  WtmpLog off
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      my $client = ProFTPD::TestSuite::FTP->new('127.0.0.1', $port);
      $client->login($user, $passwd);

      my $conn = $client->list_raw();
      unless ($conn) {
        die("Failed to LIST: " . $client->response_code() . ' ' .
          $client->response_msg());
      }

      my $buf;
      $conn->read($buf, 8192, 10);
      eval { $conn->close() };

      my $resp_code = $client->response_code();
      my $resp_msg = $client->response_msg();
      $self->assert_transfer_ok($resp_code, $resp_msg);

      ($resp_code, $resp_msg) = $client->quit();

      my $expected = 221;
      $self->assert($expected == $resp_code,
        test_msg("Expected response code $expected, got $resp_code"));

      $expected = 'Goodbye.';
      $self->assert($expected eq $resp_msg,
        test_msg("Expected response message '$expected', got '$resp_msg'"));
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh, $timeout_idle + 2) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_reverse_config_datatransferpolicy_active_list_port {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 12;

  my $proxy_config = get_reverse_proxy_config($tmpdir, $log_file, $vhost_port);
  $proxy_config->{ProxyDataTransferPolicy} = 'active';

  my $timeout_idle = 10;

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20',

    AuthUserFile => $auth_user_file,
    AuthGroupFile => $auth_group_file,
    SocketBindTight => 'on',
    TimeoutIdle => $timeout_idle,

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },

    Limit => {
      LOGIN => {
        DenyUser => $user,
      },
    },

  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  AuthUserFile $auth_user_file
  AuthGroupFile $auth_group_file
  AuthOrder mod_auth_file.c

  AllowOverride off
  TimeoutIdle $timeout_idle

  TransferLog none
  WtmpLog off
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      my $client = ProFTPD::TestSuite::FTP->new('127.0.0.1', $port, 1);
      $client->login($user, $passwd);

      my $conn = $client->list_raw();
      unless ($conn) {
        die("Failed to LIST: " . $client->response_code() . ' ' .
          $client->response_msg());
      }

      my $buf;
      $conn->read($buf, 8192, 10);
      eval { $conn->close() };

      my $resp_code = $client->response_code();
      my $resp_msg = $client->response_msg();
      $self->assert_transfer_ok($resp_code, $resp_msg);

      ($resp_code, $resp_msg) = $client->quit();

      my $expected = 221;
      $self->assert($expected == $resp_code,
        test_msg("Expected response code $expected, got $resp_code"));

      $expected = 'Goodbye.';
      $self->assert($expected eq $resp_msg,
        test_msg("Expected response message '$expected', got '$resp_msg'"));
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh, $timeout_idle + 2) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_reverse_config_datatransferpolicy_passive_list_pasv {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 12;

  my $proxy_config = get_reverse_proxy_config($tmpdir, $log_file, $vhost_port);
  $proxy_config->{ProxyDataTransferPolicy} = 'passive';

  my $timeout_idle = 10;

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20',

    AuthUserFile => $auth_user_file,
    AuthGroupFile => $auth_group_file,
    SocketBindTight => 'on',
    TimeoutIdle => $timeout_idle,

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },

    Limit => {
      LOGIN => {
        DenyUser => $user,
      },
    },

  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  AuthUserFile $auth_user_file
  AuthGroupFile $auth_group_file
  AuthOrder mod_auth_file.c

  AllowOverride off
  TimeoutIdle $timeout_idle

  TransferLog none
  WtmpLog off
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      my $client = ProFTPD::TestSuite::FTP->new('127.0.0.1', $port);
      $client->login($user, $passwd);

      my $conn = $client->list_raw();
      unless ($conn) {
        die("Failed to LIST: " . $client->response_code() . ' ' .
          $client->response_msg());
      }

      my $buf;
      $conn->read($buf, 8192, 10);
      eval { $conn->close() };

      my $resp_code = $client->response_code();
      my $resp_msg = $client->response_msg();
      $self->assert_transfer_ok($resp_code, $resp_msg);

      ($resp_code, $resp_msg) = $client->quit();

      my $expected = 221;
      $self->assert($expected == $resp_code,
        test_msg("Expected response code $expected, got $resp_code"));

      $expected = 'Goodbye.';
      $self->assert($expected eq $resp_msg,
        test_msg("Expected response message '$expected', got '$resp_msg'"));
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh, $timeout_idle + 2) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_reverse_config_datatransferpolicy_passive_list_port {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 12;

  my $proxy_config = get_reverse_proxy_config($tmpdir, $log_file, $vhost_port);
  $proxy_config->{ProxyDataTransferPolicy} = 'passive';

  my $timeout_idle = 10;

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20',

    AuthUserFile => $auth_user_file,
    AuthGroupFile => $auth_group_file,
    SocketBindTight => 'on',
    TimeoutIdle => $timeout_idle,

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },

    Limit => {
      LOGIN => {
        DenyUser => $user,
      },
    },

  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  AuthUserFile $auth_user_file
  AuthGroupFile $auth_group_file
  AuthOrder mod_auth_file.c

  AllowOverride off
  TimeoutIdle $timeout_idle

  TransferLog none
  WtmpLog off
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      my $client = ProFTPD::TestSuite::FTP->new('127.0.0.1', $port, 1);
      $client->login($user, $passwd);

      my $conn = $client->list_raw();
      unless ($conn) {
        die("Failed to LIST: " . $client->response_code() . ' ' .
          $client->response_msg());
      }

      my $buf;
      $conn->read($buf, 8192, 10);
      eval { $conn->close() };

      my $resp_code = $client->response_code();
      my $resp_msg = $client->response_msg();
      $self->assert_transfer_ok($resp_code, $resp_msg);

      ($resp_code, $resp_msg) = $client->quit();

      my $expected = 221;
      $self->assert($expected == $resp_code,
        test_msg("Expected response code $expected, got $resp_code"));

      $expected = 'Goodbye.';
      $self->assert($expected eq $resp_msg,
        test_msg("Expected response message '$expected', got '$resp_msg'"));
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh, $timeout_idle + 2) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_reverse_config_datatransferpolicy_client {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 12;

  my $proxy_config = get_reverse_proxy_config($tmpdir, $log_file, $vhost_port);
  $proxy_config->{ProxyDataTransferPolicy} = 'client';

  my $timeout_idle = 10;

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20',

    AuthUserFile => $auth_user_file,
    AuthGroupFile => $auth_group_file,
    SocketBindTight => 'on',
    TimeoutIdle => $timeout_idle,

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },

    Limit => {
      LOGIN => {
        DenyUser => $user,
      },
    },

  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  AuthUserFile $auth_user_file
  AuthGroupFile $auth_group_file
  AuthOrder mod_auth_file.c

  AllowOverride off
  TimeoutIdle $timeout_idle

  TransferLog none
  WtmpLog off
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      my $client = ProFTPD::TestSuite::FTP->new('127.0.0.1', $port, 1);
      $client->login($user, $passwd);

      my $conn = $client->list_raw();
      unless ($conn) {
        die("Failed to LIST: " . $client->response_code() . ' ' .
          $client->response_msg());
      }

      my $buf;
      $conn->read($buf, 8192, 10);
      eval { $conn->close() };

      my $resp_code = $client->response_code();
      my $resp_msg = $client->response_msg();
      $self->assert_transfer_ok($resp_code, $resp_msg);

      ($resp_code, $resp_msg) = $client->quit();

      my $expected = 221;
      $self->assert($expected == $resp_code,
        test_msg("Expected response code $expected, got $resp_code"));

      $expected = 'Goodbye.';
      $self->assert($expected eq $resp_msg,
        test_msg("Expected response message '$expected', got '$resp_msg'"));
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh, $timeout_idle + 2) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_reverse_config_selection_random {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 12;

  my $proxy_config = get_reverse_proxy_config($tmpdir, $log_file, $vhost_port);
  $proxy_config->{ProxyReverseSelection} = 'random';

  # For now, we cheat and simply repeat the same vhost three times
  $proxy_config->{ProxyReverseServers} = "ftp://127.0.0.1:$vhost_port ftp://127.0.0.1:$vhost_port ftp://127.0.0.1:$vhost_port";

  my $timeout_idle = 10;

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.reverse:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20',

    AuthUserFile => $auth_user_file,
    AuthGroupFile => $auth_group_file,
    SocketBindTight => 'on',
    TimeoutIdle => $timeout_idle,

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },

    Limit => {
      LOGIN => {
        DenyUser => $user,
      },
    },

  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  AuthUserFile $auth_user_file
  AuthGroupFile $auth_group_file
  AuthOrder mod_auth_file.c

  AllowOverride off
  TimeoutIdle $timeout_idle

  TransferLog none
  WtmpLog off
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      my $client = ProFTPD::TestSuite::FTP->new('127.0.0.1', $port, 1);
      $client->login($user, $passwd);

      my $conn = $client->list_raw();
      unless ($conn) {
        die("Failed to LIST: " . $client->response_code() . ' ' .
          $client->response_msg());
      }

      my $buf;
      $conn->read($buf, 8192, 10);
      eval { $conn->close() };

      my $resp_code = $client->response_code();
      my $resp_msg = $client->response_msg();
      $self->assert_transfer_ok($resp_code, $resp_msg);

      ($resp_code, $resp_msg) = $client->quit();

      my $expected = 221;
      $self->assert($expected == $resp_code,
        test_msg("Expected response code $expected, got $resp_code"));

      $expected = 'Goodbye.';
      $self->assert($expected eq $resp_msg,
        test_msg("Expected response message '$expected', got '$resp_msg'"));
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh, $timeout_idle + 2) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_reverse_xferlog_retr_ascii_ok {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  my $test_data = "Hello, Proxying World!\n";
  my $test_file = File::Spec->rel2abs("$tmpdir/test.txt");
  if (open(my $fh, "> $test_file")) {
    print $fh $test_data;

    unless (close($fh)) {
      die("Unable to write $test_file: $!");
    }

  } else {
    die("Unable to open $test_file: $!");
  }

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 12;

  my $proxy_config = get_reverse_proxy_config($tmpdir, $log_file, $vhost_port);

  my $timeout_idle = 10;
  my $xfer_log = File::Spec->rel2abs("$tmpdir/xfer.log");

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20',

    AuthUserFile => $auth_user_file,
    AuthGroupFile => $auth_group_file,
    SocketBindTight => 'on',
    TimeoutIdle => $timeout_idle,

    TransferLog => $xfer_log,

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },

    Limit => {
      LOGIN => {
        DenyUser => $user,
      },
    },

  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  AuthUserFile $auth_user_file
  AuthGroupFile $auth_group_file
  AuthOrder mod_auth_file.c

  AllowOverride off
  TimeoutIdle $timeout_idle

  TransferLog none
  WtmpLog off
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      my $client = ProFTPD::TestSuite::FTP->new('127.0.0.1', $port);
      $client->login($user, $passwd);
      $client->type('ascii');

      my $conn = $client->retr_raw($test_file);
      unless ($conn) {
        die("RETR failed: " . $client->response_code() . " " .
          $client->response_msg());
      }

      my $buf;
      $conn->read($buf, 8192, 30);
      my $size = $conn->bytes_read();
      eval { $conn->close() };

      my $resp_code = $client->response_code();
      my $resp_msg = $client->response_msg();
      $self->assert_transfer_ok($resp_code, $resp_msg);

      $client->quit();

      # The length of 'Hello, Proxying World!\n' is 23, but we expect 24
      # here because of the ASCII conversion of the bare LF to a CRLF.
      my $expected = length($test_data) + 1;
      $self->assert($expected == $size,
        test_msg("Expected $expected, got $size"));
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh, $timeout_idle + 2) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  eval {
    if (open(my $fh, "< $xfer_log")) {
      my $line = <$fh>;
      chomp($line);
      close($fh);

      my $expected = '^\S+\s+\S+\s+\d+\s+\d+:\d+:\d+\s+\d+\s+\d+\s+(\S+)\s+(\d+)\s+(\S+)\s+(\S+)\s+_\s+o\s+r\s+(\S+)\s+ftp\s+0\s+\*\s+c$';

      $self->assert(qr/$expected/, $line,
        test_msg("Expected '$expected', got '$line'"));

      if ($line =~ /$expected/) {
        my $remote_host = $1;
        my $filesz = $2;
        my $filename = $3;
        my $xfer_type = $4;
        my $user_name = $5;

        $expected = '127.0.0.1';
        $self->assert($expected eq $remote_host,
          test_msg("Expected host '$expected', got '$remote_host'"));

        # The length of 'Hello, Proxying World!\n' is 23, but we expect 24
        # here because of the ASCII conversion of the bare LF to a CRLF.
        $expected = length($test_data) + 1;
        $self->assert($expected == $filesz,
          test_msg("Expected file size '$expected', got '$filesz'"));

        $expected = $test_file;
        $self->assert($expected eq $filename,
          test_msg("Expected file name '$expected', got '$filename'"));
  
        $expected = 'a';
        $self->assert($expected eq $xfer_type,
          test_msg("Expected transfer type '$expected', got '$xfer_type'"));

        $expected = $user;
        $self->assert($expected eq $user_name,
          test_msg("Expected user '$expected', got '$user_name'"));
      }

    } else {
      die("Can't read $xfer_log: $!");
    }
  };
  if ($@) {
    $ex = $@;
  }

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_reverse_xferlog_retr_binary_ok {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  my $test_data = "Hello, Proxying World!\n";
  my $test_file = File::Spec->rel2abs("$tmpdir/test.txt");
  if (open(my $fh, "> $test_file")) {
    print $fh $test_data;

    unless (close($fh)) {
      die("Unable to write $test_file: $!");
    }

  } else {
    die("Unable to open $test_file: $!");
  }

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 12;

  my $proxy_config = get_reverse_proxy_config($tmpdir, $log_file, $vhost_port);

  my $timeout_idle = 10;
  my $xfer_log = File::Spec->rel2abs("$tmpdir/xfer.log");

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20',

    AuthUserFile => $auth_user_file,
    AuthGroupFile => $auth_group_file,
    SocketBindTight => 'on',
    TimeoutIdle => $timeout_idle,

    TransferLog => $xfer_log,

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },

    Limit => {
      LOGIN => {
        DenyUser => $user,
      },
    },

  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  AuthUserFile $auth_user_file
  AuthGroupFile $auth_group_file
  AuthOrder mod_auth_file.c

  AllowOverride off
  TimeoutIdle $timeout_idle

  TransferLog none
  WtmpLog off
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      my $client = ProFTPD::TestSuite::FTP->new('127.0.0.1', $port);
      $client->login($user, $passwd);
      $client->type('binary');

      my $conn = $client->retr_raw($test_file);
      unless ($conn) {
        die("RETR failed: " . $client->response_code() . " " .
          $client->response_msg());
      }

      my $buf;
      $conn->read($buf, 8192, 30);
      my $size = $conn->bytes_read();
      eval { $conn->close() };

      my $resp_code = $client->response_code();
      my $resp_msg = $client->response_msg();
      $self->assert_transfer_ok($resp_code, $resp_msg);

      $client->quit();

      # The length of 'Hello, Proxying World!\n' is 23, so that is what
      # we expect here; no ASCII conversion to change things.
      my $expected = length($test_data);
      $self->assert($expected == $size,
        test_msg("Expected $expected, got $size"));
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh, $timeout_idle + 2) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  eval {
    if (open(my $fh, "< $xfer_log")) {
      my $line = <$fh>;
      chomp($line);
      close($fh);

      my $expected = '^\S+\s+\S+\s+\d+\s+\d+:\d+:\d+\s+\d+\s+\d+\s+(\S+)\s+(\d+)\s+(\S+)\s+(\S+)\s+_\s+o\s+r\s+(\S+)\s+ftp\s+0\s+\*\s+c$';

      $self->assert(qr/$expected/, $line,
        test_msg("Expected '$expected', got '$line'"));

      if ($line =~ /$expected/) {
        my $remote_host = $1;
        my $filesz = $2;
        my $filename = $3;
        my $xfer_type = $4;
        my $user_name = $5;

        $expected = '127.0.0.1';
        $self->assert($expected eq $remote_host,
          test_msg("Expected host '$expected', got '$remote_host'"));

        # The length of 'Hello, Proxying World!\n' is 23, so that is what
        # we expect here; no ASCII conversion to change things.
        $expected = length($test_data);
        $self->assert($expected == $filesz,
          test_msg("Expected file size '$expected', got '$filesz'"));

        $expected = $test_file;
        $self->assert($expected eq $filename,
          test_msg("Expected file name '$expected', got '$filename'"));
  
        $expected = 'b';
        $self->assert($expected eq $xfer_type,
          test_msg("Expected transfer type '$expected', got '$xfer_type'"));

        $expected = $user;
        $self->assert($expected eq $user_name,
          test_msg("Expected user '$expected', got '$user_name'"));
      }

    } else {
      die("Can't read $xfer_log: $!");
    }
  };
  if ($@) {
    $ex = $@;
  }

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_reverse_xferlog_stor_ascii_ok {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  my $test_data = "Hello, Proxying World!\n";
  my $test_file = File::Spec->rel2abs("$tmpdir/test.txt");

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 12;

  my $proxy_config = get_reverse_proxy_config($tmpdir, $log_file, $vhost_port);

  my $timeout_idle = 10;
  my $xfer_log = File::Spec->rel2abs("$tmpdir/xfer.log");

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20',

    AuthUserFile => $auth_user_file,
    AuthGroupFile => $auth_group_file,
    SocketBindTight => 'on',
    TimeoutIdle => $timeout_idle,

    TransferLog => $xfer_log,

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },

    Limit => {
      LOGIN => {
        DenyUser => $user,
      },
    },

  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  AuthUserFile $auth_user_file
  AuthGroupFile $auth_group_file
  AuthOrder mod_auth_file.c

  AllowOverride off
  TimeoutIdle $timeout_idle

  TransferLog none
  WtmpLog off
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      my $client = ProFTPD::TestSuite::FTP->new('127.0.0.1', $port);
      $client->login($user, $passwd);
      $client->type('ascii');

      my $conn = $client->stor_raw($test_file);
      unless ($conn) {
        die("STOR failed: " . $client->response_code() . " " .
          $client->response_msg());
      }

      my $buf = $test_data;
      $conn->write($buf, length($buf), 30);
      eval { $conn->close() };

      my $resp_code = $client->response_code();
      my $resp_msg = $client->response_msg();
      $self->assert_transfer_ok($resp_code, $resp_msg);

      $client->quit();
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh, $timeout_idle + 2) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  eval {
    if (open(my $fh, "< $xfer_log")) {
      my $line = <$fh>;
      chomp($line);
      close($fh);

      my $expected = '^\S+\s+\S+\s+\d+\s+\d+:\d+:\d+\s+\d+\s+\d+\s+(\S+)\s+(\d+)\s+(\S+)\s+(\S+)\s+_\s+i\s+r\s+(\S+)\s+ftp\s+0\s+\*\s+c$';

      $self->assert(qr/$expected/, $line,
        test_msg("Expected '$expected', got '$line'"));

      if ($line =~ /$expected/) {
        my $remote_host = $1;
        my $filesz = $2;
        my $filename = $3;
        my $xfer_type = $4;
        my $user_name = $5;

        $expected = '127.0.0.1';
        $self->assert($expected eq $remote_host,
          test_msg("Expected host '$expected', got '$remote_host'"));

        # The length of 'Hello, Proxying World!\n' is 23, but we expect 24
        # here because of the ASCII conversion of the bare LF to a CRLF.
        $expected = length($test_data) + 1;
        $self->assert($expected == $filesz,
          test_msg("Expected file size '$expected', got '$filesz'"));

        $expected = $test_file;
        $self->assert($expected eq $filename,
          test_msg("Expected file name '$expected', got '$filename'"));
  
        $expected = 'a';
        $self->assert($expected eq $xfer_type,
          test_msg("Expected transfer type '$expected', got '$xfer_type'"));

        $expected = $user;
        $self->assert($expected eq $user_name,
          test_msg("Expected user '$expected', got '$user_name'"));
      }

    } else {
      die("Can't read $xfer_log: $!");
    }
  };
  if ($@) {
    $ex = $@;
  }

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_reverse_xferlog_stor_binary_ok {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  my $test_data = "Hello, Proxying World!\n";
  my $test_file = File::Spec->rel2abs("$tmpdir/test.txt");

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 12;

  my $proxy_config = get_reverse_proxy_config($tmpdir, $log_file, $vhost_port);

  my $timeout_idle = 10;
  my $xfer_log = File::Spec->rel2abs("$tmpdir/xfer.log");

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20',

    AuthUserFile => $auth_user_file,
    AuthGroupFile => $auth_group_file,
    SocketBindTight => 'on',
    TimeoutIdle => $timeout_idle,

    TransferLog => $xfer_log,

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },

    Limit => {
      LOGIN => {
        DenyUser => $user,
      },
    },

  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  AuthUserFile $auth_user_file
  AuthGroupFile $auth_group_file
  AuthOrder mod_auth_file.c

  AllowOverride off
  TimeoutIdle $timeout_idle

  TransferLog none
  WtmpLog off
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      my $client = ProFTPD::TestSuite::FTP->new('127.0.0.1', $port);
      $client->login($user, $passwd);
      $client->type('binary');

      my $conn = $client->stor_raw($test_file);
      unless ($conn) {
        die("STOR failed: " . $client->response_code() . " " .
          $client->response_msg());
      }

      my $buf = $test_data;
      $conn->write($buf, length($buf), 30);
      eval { $conn->close() };

      my $resp_code = $client->response_code();
      my $resp_msg = $client->response_msg();
      $self->assert_transfer_ok($resp_code, $resp_msg);

      $client->quit();
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh, $timeout_idle + 2) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  eval {
    if (open(my $fh, "< $xfer_log")) {
      my $line = <$fh>;
      chomp($line);
      close($fh);

      my $expected = '^\S+\s+\S+\s+\d+\s+\d+:\d+:\d+\s+\d+\s+\d+\s+(\S+)\s+(\d+)\s+(\S+)\s+(\S+)\s+_\s+i\s+r\s+(\S+)\s+ftp\s+0\s+\*\s+c$';

      $self->assert(qr/$expected/, $line,
        test_msg("Expected '$expected', got '$line'"));

      if ($line =~ /$expected/) {
        my $remote_host = $1;
        my $filesz = $2;
        my $filename = $3;
        my $xfer_type = $4;
        my $user_name = $5;

        $expected = '127.0.0.1';
        $self->assert($expected eq $remote_host,
          test_msg("Expected host '$expected', got '$remote_host'"));

        # The length of 'Hello, Proxying World!\n' is 23, so that is what
        # we expect here; no ASCII conversion to change things.
        $expected = length($test_data);
        $self->assert($expected == $filesz,
          test_msg("Expected file size '$expected', got '$filesz'"));

        $expected = $test_file;
        $self->assert($expected eq $filename,
          test_msg("Expected file name '$expected', got '$filename'"));
  
        $expected = 'b';
        $self->assert($expected eq $xfer_type,
          test_msg("Expected transfer type '$expected', got '$xfer_type'"));

        $expected = $user;
        $self->assert($expected eq $user_name,
          test_msg("Expected user '$expected', got '$user_name'"));
      }

    } else {
      die("Can't read $xfer_log: $!");
    }
  };
  if ($@) {
    $ex = $@;
  }

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_reverse_extlog_retr_var_F_f {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  my $test_data = "Hello, Proxying World!\n";
  my $test_file = File::Spec->rel2abs("$tmpdir/test.txt");
  if (open(my $fh, "> $test_file")) {
    print $fh $test_data;

    unless (close($fh)) {
      die("Unable to write $test_file: $!");
    }

  } else {
    die("Unable to open $test_file: $!");
  }

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 12;

  my $proxy_config = get_reverse_proxy_config($tmpdir, $log_file, $vhost_port);

  my $timeout_idle = 10;
  my $ext_log = File::Spec->rel2abs("$tmpdir/ext.log");

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20',

    AuthUserFile => $auth_user_file,
    AuthGroupFile => $auth_group_file,
    SocketBindTight => 'on',
    TimeoutIdle => $timeout_idle,

    LogFormat => 'custom "%F|%f"',
    ExtendedLog => "$ext_log READ custom",

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },

    Limit => {
      LOGIN => {
        DenyUser => $user,
      },
    },

  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  AuthUserFile $auth_user_file
  AuthGroupFile $auth_group_file
  AuthOrder mod_auth_file.c

  AllowOverride off
  TimeoutIdle $timeout_idle

  TransferLog none
  WtmpLog off
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      my $client = ProFTPD::TestSuite::FTP->new('127.0.0.1', $port);
      $client->login($user, $passwd);
      $client->type('binary');

      my $conn = $client->retr_raw($test_file);
      unless ($conn) {
        die("RETR failed: " . $client->response_code() . " " .
          $client->response_msg());
      }

      my $buf;
      $conn->read($buf, 8192, 30);
      my $size = $conn->bytes_read();
      eval { $conn->close() };

      my $resp_code = $client->response_code();
      my $resp_msg = $client->response_msg();
      $self->assert_transfer_ok($resp_code, $resp_msg);

      $client->quit();

      # The length of 'Hello, Proxying World!\n' is 23, so that is what
      # we expect here; no ASCII conversion to change things.
      my $expected = length($test_data);
      $self->assert($expected == $size,
        test_msg("Expected $expected, got $size"));
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh, $timeout_idle + 2) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  eval {
    if (open(my $fh, "< $ext_log")) {
      my $line = <$fh>;
      chomp($line);
      close($fh);

      # Due to the fact that these tests run both the proxy server and the
      # backend server on the same box, it means that the proxy server's
      # mod_log IS in a position to get the full path for %f.  But in other
      # cases, the proxy server won't have that file present (or it might
      # even be the wrong file).  Thus %F/%f are to be distrusted in the
      # ExtendedLog entries generated by mod_proxy.

    } else {
      die("Can't read $ext_log: $!");
    }
  };
  if ($@) {
    $ex = $@;
  }

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_reverse_extlog_stor_var_F_f {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  my $test_data = "Hello, Proxying World!\n";
  my $test_file = File::Spec->rel2abs("$tmpdir/test.txt");

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 12;

  my $proxy_config = get_reverse_proxy_config($tmpdir, $log_file, $vhost_port);

  my $timeout_idle = 10;
  my $ext_log = File::Spec->rel2abs("$tmpdir/ext.log");

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20',

    AuthUserFile => $auth_user_file,
    AuthGroupFile => $auth_group_file,
    SocketBindTight => 'on',
    TimeoutIdle => $timeout_idle,

    LogFormat => 'custom "%F|%f"',
    ExtendedLog => "$ext_log WRITE custom",

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },

    Limit => {
      LOGIN => {
        DenyUser => $user,
      },
    },

  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  AuthUserFile $auth_user_file
  AuthGroupFile $auth_group_file
  AuthOrder mod_auth_file.c

  AllowOverride off
  TimeoutIdle $timeout_idle

  TransferLog none
  WtmpLog off
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      my $client = ProFTPD::TestSuite::FTP->new('127.0.0.1', $port);
      $client->login($user, $passwd);
      $client->type('binary');

      my $conn = $client->stor_raw($test_file);
      unless ($conn) {
        die("STOR failed: " . $client->response_code() . " " .
          $client->response_msg());
      }

      my $buf = $test_data;
      $conn->write($buf, length($test_data), 30);
      eval { $conn->close() };

      my $resp_code = $client->response_code();
      my $resp_msg = $client->response_msg();
      $self->assert_transfer_ok($resp_code, $resp_msg);

      $client->quit();
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh, $timeout_idle + 2) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  eval {
    if (open(my $fh, "< $ext_log")) {
      my $line = <$fh>;
      chomp($line);
      close($fh);

      # Due to the fact that these tests run both the proxy server and the
      # backend server on the same box, it means that the proxy server's
      # mod_log IS in a position to get the full path for %f.  But in other
      # cases, the proxy server won't have that file present (or it might
      # even be the wrong file).  Thus %F/%f are to be distrusted in the
      # ExtendedLog entries generated by mod_proxy.

    } else {
      die("Can't read $ext_log: $!");
    }
  };
  if ($@) {
    $ex = $@;
  }

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_reverse_extlog_list_var_D_d {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 12;

  my $proxy_config = get_reverse_proxy_config($tmpdir, $log_file, $vhost_port);

  my $timeout_idle = 10;
  my $ext_log = File::Spec->rel2abs("$tmpdir/ext.log");

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20',

    AuthUserFile => $auth_user_file,
    AuthGroupFile => $auth_group_file,
    SocketBindTight => 'on',
    TimeoutIdle => $timeout_idle,

    LogFormat => 'custom "%D|%d"',
    ExtendedLog => "$ext_log DIRS custom",

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },

    Limit => {
      LOGIN => {
        DenyUser => $user,
      },
    },

  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  AuthUserFile $auth_user_file
  AuthGroupFile $auth_group_file
  AuthOrder mod_auth_file.c

  AllowOverride off
  TimeoutIdle $timeout_idle

  TransferLog none
  WtmpLog off
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      my $client = ProFTPD::TestSuite::FTP->new('127.0.0.1', $port);
      $client->login($user, $passwd);

      my $conn = $client->list_raw();
      unless ($conn) {
        die("LIST failed: " . $client->response_code() . " " .
          $client->response_msg());
      }

      my $buf;
      $conn->read($buf, 8192, 30);
      eval { $conn->close() };

      my $resp_code = $client->response_code();
      my $resp_msg = $client->response_msg();
      $self->assert_transfer_ok($resp_code, $resp_msg);

      $client->quit();
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh, $timeout_idle + 2) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  eval {
    if (open(my $fh, "< $ext_log")) {
      my $line = <$fh>;
      chomp($line);
      close($fh);

      # Due to the fact that these tests run both the proxy server and the
      # backend server on the same box, it means that the proxy server's
      # mod_log IS in a position to get the full path for %d.  But in other
      # cases, the proxy server won't have that file present (or it might
      # even be the wrong file).  Thus %D/%d are to be distrusted in the
      # ExtendedLog entries generated by mod_proxy.

    } else {
      die("Can't read $ext_log: $!");
    }
  };
  if ($@) {
    $ex = $@;
  }

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_reverse_proxy_protocol_ipv4 {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 12;

  my $proxy_config = get_reverse_proxy_config($tmpdir, $log_file, $vhost_port);
  $proxy_config->{ProxyOptions} = 'UseProxyProtocol';

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.conn:10 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20 proxy_protocol:20',

    AuthUserFile => $auth_user_file,
    AuthGroupFile => $auth_group_file,
    SocketBindTight => 'on',

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },

  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  AuthUserFile $auth_user_file
  AuthGroupFile $auth_group_file
  AuthOrder mod_auth_file.c

  AllowOverride off
  IdentLookups off
  TransferLog none
  WtmpLog off

  <IfModule mod_proxy_protocol.c>
    ProxyProtocolEngine on
  </IfModule>
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      my $client = ProFTPD::TestSuite::FTP->new('127.0.0.1', $port);
      $client->login($user, $passwd);
      $client->quit();
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_reverse_proxy_protocol_ipv6 {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 12;

  my $proxy_config = get_reverse_proxy_config($tmpdir, $log_file, $vhost_port);
  $proxy_config->{ProxyReverseServers} = "ftp://[::1]:$vhost_port";
  $proxy_config->{ProxyOptions} = 'UseProxyProtocol';

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.conn:10 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20 proxy_protocol:20',

    AuthUserFile => $auth_user_file,
    AuthGroupFile => $auth_group_file,
    SocketBindTight => 'on',
    UseIPv6 => 'on',

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },

  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost ::1>
  Port $vhost_port
  ServerName "Real Server"

  AuthUserFile $auth_user_file
  AuthGroupFile $auth_group_file
  AuthOrder mod_auth_file.c

  AllowOverride off
  IdentLookups off
  TransferLog none
  WtmpLog off

  <IfModule mod_proxy_protocol.c>
    ProxyProtocolEngine on
  </IfModule>
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      my $client = ProFTPD::TestSuite::FTP->new('127.0.0.1', $port);
      $client->login($user, $passwd);
      $client->quit();
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_tls_reverse_login {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  my $cert_file = File::Spec->rel2abs('t/etc/modules/mod_tls/server-cert.pem');
  my $ca_file = File::Spec->rel2abs('t/etc/modules/mod_tls/ca-cert.pem');

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 12;

  my $proxy_config = get_reverse_proxy_config($tmpdir, $log_file, $vhost_port);

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20',

    AuthUserFile => $auth_user_file,
    AuthGroupFile => $auth_group_file,
    SocketBindTight => 'on',

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_tls.c' => {
        TLSEngine => 'on',
        TLSLog => $log_file,
        TLSProtocol => 'SSLv3 TLSv1',
        TLSRequired => 'on',
        TLSRSACertificateFile => $cert_file,
        TLSCACertificateFile => $ca_file,
      },

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },
  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  AuthUserFile $auth_user_file
  AuthGroupFile $auth_group_file
  AuthOrder mod_auth_file.c

  AllowOverride off
  WtmpLog off
  TransferLog none
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  require Net::FTPSSL;

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      # Give the server a chance to start up
      sleep(2);
 
      my $client_opts = {
        Encryption => 'E',
        Port => $port,
      };

      if ($ENV{TEST_VERBOSE}) {
        $client_opts->{Debug} = 1;
      }

      my $client = Net::FTPSSL->new('127.0.0.1', %$client_opts);

      unless ($client) {
        die("Can't connect to FTPS server: " . IO::Socket::SSL::errstr());
      }

      unless ($client->login($user, $passwd)) {
        die("Can't login: " . $client->last_message());
      }

      $client->quit();
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_tls_reverse_login_failed {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  my $cert_file = File::Spec->rel2abs('t/etc/modules/mod_tls/server-cert.pem');
  my $ca_file = File::Spec->rel2abs('t/etc/modules/mod_tls/ca-cert.pem');

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 12;

  my $proxy_config = get_reverse_proxy_config($tmpdir, $log_file, $vhost_port);

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20',

    AuthUserFile => $auth_user_file,
    AuthGroupFile => $auth_group_file,
    SocketBindTight => 'on',

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_tls.c' => {
        TLSEngine => 'on',
        TLSLog => $log_file,
        TLSProtocol => 'SSLv3 TLSv1',
        TLSRequired => 'on',
        TLSRSACertificateFile => $cert_file,
        TLSCACertificateFile => $ca_file,
      },

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },
  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  AuthUserFile $auth_user_file
  AuthGroupFile $auth_group_file
  AuthOrder mod_auth_file.c

  AllowOverride off
  WtmpLog off
  TransferLog none
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  require Net::FTPSSL;

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      # Give the server a chance to start up
      sleep(2);
 
      my $client_opts = {
        Encryption => 'E',
        Port => $port,
      };

      if ($ENV{TEST_VERBOSE}) {
        $client_opts->{Debug} = 1;
      }

      my $client = Net::FTPSSL->new('127.0.0.1', %$client_opts);

      unless ($client) {
        die("Can't connect to FTPS server: " . IO::Socket::SSL::errstr());
      }

      if ($client->login($user, 'foobar')) {
        die("Login succeeded unexpectedly");
      }

      my $resp_msg = $client->last_message();
      $client->quit();

      my $expected = '530 Login incorrect.';
      $self->assert($expected eq $resp_msg,
        test_msg("Expected response message '$expected', got '$resp_msg'"));
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_tls_reverse_login_tlslogin {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  my $server_cert_file = File::Spec->rel2abs('t/etc/modules/mod_tls/server-cert.pem');
  my $client_cert_file = File::Spec->rel2abs('t/etc/modules/mod_tls/client-cert.pem');
  my $ca_file = File::Spec->rel2abs('t/etc/modules/mod_tls/ca-cert.pem');

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 12;

  my $proxy_config = get_reverse_proxy_config($tmpdir, $log_file, $vhost_port);

  my $tlslogin_file = File::Spec->rel2abs("$tmpdir/.tlslogin");
  unless (copy($client_cert_file, $tlslogin_file)) {
    die("Can't copy $client_cert_file to $tlslogin_file: $!");
  }

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 auth:10 proxy:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20',

    AuthUserFile => $auth_user_file,
    AuthGroupFile => $auth_group_file,
    SocketBindTight => 'on',

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_tls.c' => {
        TLSEngine => 'on',
        TLSLog => $log_file,
        TLSProtocol => 'SSLv3 TLSv1',
        TLSRequired => 'on',
        TLSRSACertificateFile => $server_cert_file,
        TLSCACertificateFile => $ca_file,
        TLSOptions => 'AllowDotLogin',
      },

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },
  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  AuthUserFile $auth_user_file
  AuthGroupFile $auth_group_file
  AuthOrder mod_auth_file.c

  AllowOverride off
  WtmpLog off
  TransferLog none
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  require Net::FTPSSL;

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      # Give the server a chance to start up
      sleep(2);

      # IO::Socket::SSL options
      my $ssl_opts = {
        SSL_use_cert => 1,
        SSL_cert_file => $client_cert_file,
        SSL_key_file => $client_cert_file,
      };
 
      my $client_opts = {
        Encryption => 'E',
        Port => $port,
        SSL_Client_Certificate => $ssl_opts,
      };

      if ($ENV{TEST_VERBOSE}) {
        $client_opts->{Debug} = 1;
      }

      my $client = Net::FTPSSL->new('127.0.0.1', %$client_opts);

      unless ($client) {
        die("Can't connect to FTPS server: " . IO::Socket::SSL::errstr());
      }

      unless ($client->_user($user)) {
        die("USER error: " . $client->last_message());
      }

      my $resp_msg = $client->last_message();
      $client->quit();

      # Even though we configured mod_tls on the proxy to allow .tlslogin,
      # mod_proxy does not actually invoke that functionality.  And for good
      # reason.  If mod_tls/mod_proxy allowed the DotLogin, then the client
      # would not need to send a password.  But the backend FTP session is NOT
      # configured for DotLogin, which means that that WILL need a password.
      #
      # Thus expecting the 331 response code here is correct.
      my $expected = "331 Password required for $user";
      $self->assert($expected eq $resp_msg,
        test_msg("Expected response message '$expected', got '$resp_msg'"));
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_tls_reverse_list_pasv {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  my $cert_file = File::Spec->rel2abs('t/etc/modules/mod_tls/server-cert.pem');
  my $ca_file = File::Spec->rel2abs('t/etc/modules/mod_tls/ca-cert.pem');

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 12;

  my $proxy_config = get_reverse_proxy_config($tmpdir, $log_file, $vhost_port);

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20',

    AuthUserFile => $auth_user_file,
    AuthGroupFile => $auth_group_file,
    SocketBindTight => 'on',

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_tls.c' => {
        TLSEngine => 'on',
        TLSLog => $log_file,
        TLSProtocol => 'SSLv3 TLSv1',
        TLSRequired => 'on',
        TLSRSACertificateFile => $cert_file,
        TLSCACertificateFile => $ca_file,
        TLSOptions => 'NoSessionReuseRequired',
      },

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },
  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  AuthUserFile $auth_user_file
  AuthGroupFile $auth_group_file
  AuthOrder mod_auth_file.c

  AllowOverride off
  WtmpLog off
  TransferLog none
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  require Net::FTPSSL;

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      # Give the server a chance to start up
      sleep(2);
 
      my $client_opts = {
        Encryption => 'E',
        Port => $port,
      };

      if ($ENV{TEST_VERBOSE}) {
        $client_opts->{Debug} = 1;
      }

      my $client = Net::FTPSSL->new('127.0.0.1', %$client_opts);

      unless ($client) {
        die("Can't connect to FTPS server: " . IO::Socket::SSL::errstr());
      }

      unless ($client->login($user, $passwd)) {
        die("Can't login: " . $client->last_message());
      }

      my $res = $client->list('.');
      unless ($res) {
        die("LIST failed unexpectedly: " . $client->last_message());
      }

      $client->quit();

use Data::Dumper;
print STDERR "res: ", Dumper($res), "\n";
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_reverse_config_reverseservers_file {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 12;

  my $proxy_config = get_reverse_proxy_config($tmpdir, $log_file, $vhost_port);

  my $proxy_servers_file = File::Spec->rel2abs("$tmpdir/backends.txt");
  if (open(my $fh, "> $proxy_servers_file")) {
    print $fh "ftp://127.0.0.1:$vhost_port\n";

    unless (close($fh)) {
      die("Can't write $proxy_servers_file: $!");
    }

  } else {
    die("Can't open $proxy_servers_file: $!");
  }

  # Make sure that mod_proxy correctly handles a list of backend servers
  # read from a file.
  $proxy_config->{ProxyReverseServers} = "file:$proxy_servers_file";

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20',

    AuthUserFile => $auth_user_file,
    AuthGroupFile => $auth_group_file,
    SocketBindTight => 'on',

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },

    Limit => {
      LOGIN => {
        DenyUser => $user,
      },
    },

  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  AuthUserFile $auth_user_file
  AuthGroupFile $auth_group_file
  AuthOrder mod_auth_file.c

  AllowOverride off
  WtmpLog off
  TransferLog none
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      my $client = ProFTPD::TestSuite::FTP->new('127.0.0.1', $port);
      $client->login($user, $passwd);
      $client->quit();
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_forward_connect {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 17;

  my $proxy_config = get_forward_proxy_config($tmpdir, $log_file, $vhost_port);

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.forward:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20',

    AuthUserFile => $auth_user_file,
    AuthGroupFile => $auth_group_file,
    ServerIdent => 'on "Forward Proxy Server"',
    SocketBindTight => 'on',

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },
  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  WtmpLog off
  TransferLog none
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      my $client = ProFTPD::TestSuite::FTP->new('127.0.0.1', $port);

      my $resp_code = $client->response_code();
      my $resp_msg = $client->response_msg();

      $client->quit();

      my $expected;

      $expected = 220;
      $self->assert($expected == $resp_code,
        test_msg("Expected response code $expected, got $resp_code"));

      $expected = 'Forward Proxy Server';
      $self->assert(qr/$expected/, $resp_msg,
        test_msg("Expected response message '$expected', got '$resp_msg'"));
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_forward_noproxyauth_login {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 17;

  my $proxy_config = get_forward_proxy_config($tmpdir, $log_file, $vhost_port);
  $proxy_config->{ProxyForwardMethod} = 'user@host';

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.conn:20 proxy.uri:20 proxy.forward:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20',

    AuthUserFile => $auth_user_file,
    AuthGroupFile => $auth_group_file,
    ServerIdent => 'on "Forward Proxy Server"',
    SocketBindTight => 'on',

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },
  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  AuthUserFile $auth_user_file
  AuthGroupFile $auth_group_file
  AuthOrder mod_auth_file.c

  AllowOverride off
  WtmpLog off
  TransferLog none
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      my $client = ProFTPD::TestSuite::FTP->new('127.0.0.1', $port);
      $client->login("$user\@127.0.0.1:$vhost_port", $passwd);
      $client->quit();
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_forward_noproxyauth_login_netftp_fw_type_1 {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 17;

  my $proxy_config = get_forward_proxy_config($tmpdir, $log_file, $vhost_port);
  $proxy_config->{ProxyForwardMethod} = 'user@host';

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.conn:20 proxy.uri:20 proxy.forward:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20',

    AuthUserFile => $auth_user_file,
    AuthGroupFile => $auth_group_file,
    ServerIdent => 'on "Forward Proxy Server"',
    SocketBindTight => 'on',

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },
  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  AuthUserFile $auth_user_file
  AuthGroupFile $auth_group_file
  AuthOrder mod_auth_file.c

  AllowOverride off
  WtmpLog off
  TransferLog none
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      # Set the appropriate Net::FTP environment variables for "FTP firewalls".
      $ENV{FTP_FIREWALL} = "127.0.0.1:$vhost_port";
      $ENV{FTP_FIREWALL_TYPE} = 1;

      my $client = ProFTPD::TestSuite::FTP->new('127.0.0.1', $port);
      $client->login($user, $passwd);
      $client->quit();
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_forward_noproxyauth_login_failed_bad_dst_addr {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 17;

  my $proxy_config = get_forward_proxy_config($tmpdir, $log_file, $vhost_port);
  $proxy_config->{ProxyForwardMethod} = 'user@host';

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.conn:20 proxy.uri:20 proxy.forward:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20',

    AuthUserFile => $auth_user_file,
    AuthGroupFile => $auth_group_file,
    ServerIdent => 'on "Forward Proxy Server"',
    SocketBindTight => 'on',

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },
  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  AuthUserFile $auth_user_file
  AuthGroupFile $auth_group_file
  AuthOrder mod_auth_file.c

  AllowOverride off
  WtmpLog off
  TransferLog none
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      my $client = ProFTPD::TestSuite::FTP->new('127.0.0.1', $port);

      my $bad_addr = '1.2.3.4:5678';
      eval { $client->login("$user\@$bad_addr", $passwd) };
      unless ($@) {
        die("Login succeeded unexpectedly");
      }

      my $resp_code = $client->response_code();
      my $resp_msg = $client->response_msg();

      my $expected;

      $expected = 530;
      $self->assert($expected == $resp_code,
        test_msg("Expected response code $expected, got $resp_code"));

      $expected = "Unable to connect to $bad_addr: Network is unreachable";
      $self->assert($expected eq $resp_msg,
        test_msg("Expected response message '$expected', got '$resp_msg'"));

      $client->quit();
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_forward_noproxyauth_login_failed_non2xx {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 17;

  my $proxy_config = get_forward_proxy_config($tmpdir, $log_file, $vhost_port);
  $proxy_config->{ProxyForwardMethod} = 'user@host';

  my $allow_file = File::Spec->rel2abs("$tmpdir/wrap2.allow");
  if (open(my $fh, "> $allow_file")) {
    unless (close($fh)) {
      die("Can't write $allow_file: $!");
    }

  } else {
    die("Can't open $allow_file: $!");
  }

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.conn:20 proxy.uri:20 proxy.forward:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20',

    AuthUserFile => $auth_user_file,
    AuthGroupFile => $auth_group_file,
    ServerIdent => 'on "Forward Proxy Server"',
    SocketBindTight => 'on',

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },
  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  AuthUserFile $auth_user_file
  AuthGroupFile $auth_group_file
  AuthOrder mod_auth_file.c

  AllowOverride off
  WtmpLog off
  TransferLog none

  <IfModule mod_wrap2_file.c>
    WrapEngine on
    WrapLog $log_file
    WrapTables file:$allow_file builtin:all
    WrapOptions CheckOnConnect
  </IfModule>
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      my $client = ProFTPD::TestSuite::FTP->new('127.0.0.1', $port);
      eval { $client->login("$user\@127.0.0.1:$vhost_port", $passwd) };
      unless ($@) {
        die("Login succeeded unexpectedly");
      }

      my $resp_code = $client->response_code();
      my $resp_msg = $client->response_msg();

      my $expected;

      $expected = 530;
      $self->assert($expected == $resp_code,
        test_msg("Expected response code $expected, got $resp_code"));

      $expected = 'Access denied';
      $self->assert($expected eq $resp_msg,
        test_msg("Expected response message '$expected', got '$resp_msg'"));

      $client->quit();
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_forward_noproxyauth_login_failed_login_limit {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 17;

  my $proxy_config = get_forward_proxy_config($tmpdir, $log_file, $vhost_port);
  $proxy_config->{ProxyForwardMethod} = 'user@host';

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.conn:20 proxy.uri:20 proxy.forward:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20',

    AuthUserFile => $auth_user_file,
    AuthGroupFile => $auth_group_file,
    ServerIdent => 'on "Forward Proxy Server"',
    SocketBindTight => 'on',

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },
  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  AuthUserFile $auth_user_file
  AuthGroupFile $auth_group_file
  AuthOrder mod_auth_file.c

  AllowOverride off
  WtmpLog off
  TransferLog none

  <Limit LOGIN>
    DenyAll
  </Limit>
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      my $client = ProFTPD::TestSuite::FTP->new('127.0.0.1', $port);
      eval { $client->login("$user\@127.0.0.1:$vhost_port", $passwd) };
      unless ($@) {
        die("Login succeeded unexpectedly");
      }

      my $resp_code = $client->response_code();
      my $resp_msg = $client->response_msg();

      my $expected;

      $expected = 530;
      $self->assert($expected == $resp_code,
        test_msg("Expected response code $expected, got $resp_code"));

      $expected = "Unable to connect to 127.0.0.1:$vhost_port: Operation not permitted";
      $self->assert($expected eq $resp_msg,
        test_msg("Expected response message '$expected', got '$resp_msg'"));

      $client->quit();
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_forward_noproxyauth_login_failed_bad_sequence {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 17;

  my $proxy_config = get_forward_proxy_config($tmpdir, $log_file, $vhost_port);
  $proxy_config->{ProxyForwardMethod} = 'user@host';

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.conn:20 proxy.uri:20 proxy.forward:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20',

    AuthUserFile => $auth_user_file,
    AuthGroupFile => $auth_group_file,
    ServerIdent => 'on "Forward Proxy Server"',
    SocketBindTight => 'on',

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },
  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  AuthUserFile $auth_user_file
  AuthGroupFile $auth_group_file
  AuthOrder mod_auth_file.c

  AllowOverride off
  WtmpLog off
  TransferLog none
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      my $client = ProFTPD::TestSuite::FTP->new('127.0.0.1', $port);
      $client->user("$user\@127.0.0.1:$vhost_port");
      eval { $client->pwd() };
      unless ($@) {
        die("Out-of-sequence command succeeded unexpectedly");
      }

      my $resp_code = $client->response_code();
      my $resp_msg = $client->response_msg();

      my $expected;

      $expected = 530;
      $self->assert($expected == $resp_code,
        test_msg("Expected response code $expected, got $resp_code"));

      $expected = 'Please login with USER and PASS';
      $self->assert($expected eq $resp_msg,
        test_msg("Expected response message '$expected', got '$resp_msg'"));

      $client->quit();
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_forward_noproxyauth_login_failed_bad_dst_passwd {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 17;

  my $proxy_config = get_forward_proxy_config($tmpdir, $log_file, $vhost_port);
  $proxy_config->{ProxyForwardMethod} = 'user@host';

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.conn:20 proxy.uri:20 proxy.forward:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20',

    AuthUserFile => $auth_user_file,
    AuthGroupFile => $auth_group_file,
    ServerIdent => 'on "Forward Proxy Server"',
    SocketBindTight => 'on',

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },
  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  AuthUserFile $auth_user_file
  AuthGroupFile $auth_group_file
  AuthOrder mod_auth_file.c

  AllowOverride off
  WtmpLog off
  TransferLog none
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      my $client = ProFTPD::TestSuite::FTP->new('127.0.0.1', $port);

      my $bad_passwd = "BadPassword";
      eval { $client->login("$user\@127.0.0.1:$vhost_port", $bad_passwd) };
      unless ($@) {
        die("Login succeeded unexpectedly");
      }

      my $resp_code = $client->response_code();
      my $resp_msg = $client->response_msg();

      my $expected;

      $expected = 530;
      $self->assert($expected == $resp_code,
        test_msg("Expected response code $expected, got $resp_code"));

      $expected = 'Login incorrect.';
      $self->assert($expected eq $resp_msg,
        test_msg("Expected response message '$expected', got '$resp_msg'"));

      $client->quit();
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_forward_login_feat_first {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 17;

  my $proxy_config = get_forward_proxy_config($tmpdir, $log_file, $vhost_port);
  $proxy_config->{ProxyForwardMethod} = 'user@host';

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.conn:20 proxy.uri:20 proxy.forward:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20',

    AuthUserFile => $auth_user_file,
    AuthGroupFile => $auth_group_file,
    ServerIdent => 'on "Forward Proxy Server"',
    SocketBindTight => 'on',

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },
  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  AuthUserFile $auth_user_file
  AuthGroupFile $auth_group_file
  AuthOrder mod_auth_file.c

  AllowOverride off
  WtmpLog off
  TransferLog none
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      my $client = ProFTPD::TestSuite::FTP->new('127.0.0.1', $port);
      my ($resp_code, $resp_msg) = $client->feat();

      my $expected;

      $expected = 211;
      $self->assert($expected == $resp_code,
        test_msg("Expected response code $expected, got $resp_code"));

      $client->login("$user\@127.0.0.1:$vhost_port", $passwd);
      $client->quit();
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_forward_list_pasv {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 17;

  my $proxy_config = get_forward_proxy_config($tmpdir, $log_file, $vhost_port);
  $proxy_config->{ProxyForwardMethod} = 'user@host';

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.conn:20 proxy.uri:20 proxy.forward:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20',

    AuthUserFile => $auth_user_file,
    AuthGroupFile => $auth_group_file,
    ServerIdent => 'on "Forward Proxy Server"',
    SocketBindTight => 'on',

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },
  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  AuthUserFile $auth_user_file
  AuthGroupFile $auth_group_file
  AuthOrder mod_auth_file.c

  AllowOverride off
  WtmpLog off
  TransferLog none
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      my $client = ProFTPD::TestSuite::FTP->new('127.0.0.1', $port);
      $client->login("$user\@127.0.0.1:$vhost_port", $passwd);

      my $conn = $client->list_raw();
      unless ($conn) {
        die("Failed to LIST: " . $client->response_code() . ' ' .
          $client->response_msg());
      }

      my $buf;
      $conn->read($buf, 8192, 10);
      eval { $conn->close() };

      my $resp_code = $client->response_code();
      my $resp_msg = $client->response_msg();
      $self->assert_transfer_ok($resp_code, $resp_msg);

      ($resp_code, $resp_msg) = $client->quit();

      my $expected = 221;
      $self->assert($expected == $resp_code,
        test_msg("Expected response code $expected, got $resp_code"));

      $expected = 'Goodbye.';
      $self->assert($expected eq $resp_msg,
        test_msg("Expected response message '$expected', got '$resp_msg'"));
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_forward_list_port {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 17;

  my $proxy_config = get_forward_proxy_config($tmpdir, $log_file, $vhost_port);
  $proxy_config->{ProxyForwardMethod} = 'user@host';

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.conn:20 proxy.uri:20 proxy.forward:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20',

    AuthUserFile => $auth_user_file,
    AuthGroupFile => $auth_group_file,
    ServerIdent => 'on "Forward Proxy Server"',
    SocketBindTight => 'on',

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },
  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  AuthUserFile $auth_user_file
  AuthGroupFile $auth_group_file
  AuthOrder mod_auth_file.c

  AllowOverride off
  WtmpLog off
  TransferLog none
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      my $client = ProFTPD::TestSuite::FTP->new('127.0.0.1', $port, 1);
      $client->login("$user\@127.0.0.1:$vhost_port", $passwd);

      my $conn = $client->list_raw();
      unless ($conn) {
        die("Failed to LIST: " . $client->response_code() . ' ' .
          $client->response_msg());
      }

      my $buf;
      $conn->read($buf, 8192, 10);
      eval { $conn->close() };

      my $resp_code = $client->response_code();
      my $resp_msg = $client->response_msg();
      $self->assert_transfer_ok($resp_code, $resp_msg);

      ($resp_code, $resp_msg) = $client->quit();

      my $expected = 221;
      $self->assert($expected == $resp_code,
        test_msg("Expected response code $expected, got $resp_code"));

      $expected = 'Goodbye.';
      $self->assert($expected eq $resp_msg,
        test_msg("Expected response message '$expected', got '$resp_msg'"));
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_forward_epsv {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 17;

  my $proxy_config = get_forward_proxy_config($tmpdir, $log_file, $vhost_port);
  $proxy_config->{ProxyForwardMethod} = 'user@host';

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.conn:20 proxy.uri:20 proxy.forward:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20',

    AuthUserFile => $auth_user_file,
    AuthGroupFile => $auth_group_file,
    ServerIdent => 'on "Forward Proxy Server"',
    SocketBindTight => 'on',

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },
  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  AuthUserFile $auth_user_file
  AuthGroupFile $auth_group_file
  AuthOrder mod_auth_file.c

  AllowOverride off
  WtmpLog off
  TransferLog none
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      my $client = ProFTPD::TestSuite::FTP->new('127.0.0.1', $port);
      $client->login("$user\@127.0.0.1:$vhost_port", $passwd);

      my ($resp_code, $resp_msg) = $client->epsv();

      my $expected = 229;
      $self->assert($expected == $resp_code,
        test_msg("Expected response code $expected, got $resp_code"));

      $expected = '^Entering Extended Passive Mode \(\|\|\|\d+\|\)';
      $self->assert(qr/$expected/, $resp_msg,
        test_msg("Expected response message '$expected', got '$resp_msg'"));

      $client->quit();
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_forward_eprt_ipv4 {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 17;

  my $proxy_config = get_forward_proxy_config($tmpdir, $log_file, $vhost_port);
  $proxy_config->{ProxyForwardMethod} = 'user@host';

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.conn:20 proxy.uri:20 proxy.forward:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20',

    AuthUserFile => $auth_user_file,
    AuthGroupFile => $auth_group_file,
    ServerIdent => 'on "Forward Proxy Server"',
    SocketBindTight => 'on',

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },
  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  AuthUserFile $auth_user_file
  AuthGroupFile $auth_group_file
  AuthOrder mod_auth_file.c

  AllowOverride off
  WtmpLog off
  TransferLog none
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      my $client = ProFTPD::TestSuite::FTP->new('127.0.0.1', $port);
      $client->login("$user\@127.0.0.1:$vhost_port", $passwd);

      my ($resp_code, $resp_msg) = $client->eprt('|1|127.0.0.1|4856|');

      my $expected;

      $expected = 200;
      $self->assert($expected == $resp_code,
        test_msg("Expected $expected, got $resp_code"));

      $expected = "EPRT command successful";
      $self->assert($expected eq $resp_msg,
        test_msg("Expected '$expected', got '$resp_msg'"));

      $client->quit();
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_forward_eprt_ipv6 {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 17;

  my $proxy_config = get_forward_proxy_config($tmpdir, $log_file, $vhost_port);
  $proxy_config->{ProxyForwardMethod} = 'user@host';

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.conn:20 proxy.uri:20 proxy.forward:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20',

    AuthUserFile => $auth_user_file,
    AuthGroupFile => $auth_group_file,
    ServerIdent => 'on "Forward Proxy Server"',
    SocketBindTight => 'on',
    UseIPv6 => 'on',

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },
  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  AuthUserFile $auth_user_file
  AuthGroupFile $auth_group_file
  AuthOrder mod_auth_file.c

  AllowOverride off
  WtmpLog off
  TransferLog none
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      my $client = ProFTPD::TestSuite::FTP->new('127.0.0.1', $port);
      $client->login("$user\@127.0.0.1:$vhost_port", $passwd);

      my ($resp_code, $resp_msg) = $client->eprt('|2|::ffff:127.0.0.1|4856|');

      my $expected;

      $expected = 200;
      $self->assert($expected == $resp_code,
        test_msg("Expected $expected, got $resp_code"));

      $expected = "EPRT command successful";
      $self->assert($expected eq $resp_msg,
        test_msg("Expected '$expected', got '$resp_msg'"));

      $client->quit();
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_forward_stor_pasv {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 17;

  my $proxy_config = get_forward_proxy_config($tmpdir, $log_file, $vhost_port);
  $proxy_config->{ProxyForwardMethod} = 'user@host';

  my $test_data = "Hello, Proxying World!\n";
  my $test_file = File::Spec->rel2abs("$tmpdir/test.txt");

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.conn:20 proxy.uri:20 proxy.forward:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20',

    AuthUserFile => $auth_user_file,
    AuthGroupFile => $auth_group_file,
    ServerIdent => 'on "Forward Proxy Server"',
    SocketBindTight => 'on',

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },
  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  AuthUserFile $auth_user_file
  AuthGroupFile $auth_group_file
  AuthOrder mod_auth_file.c

  AllowOverride off
  WtmpLog off
  TransferLog none
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      my $client = ProFTPD::TestSuite::FTP->new('127.0.0.1', $port);
      $client->login("$user\@127.0.0.1:$vhost_port", $passwd);

      my $conn = $client->stor_raw($test_file);
      unless ($conn) {
        die("STOR failed: " . $client->response_code() . " " .
          $client->response_msg());
      }

      my $buf = $test_data;
      $conn->write($buf, length($buf), 30);
      eval { $conn->close() };

      my $resp_code = $client->response_code();
      my $resp_msg = $client->response_msg();
      $self->assert_transfer_ok($resp_code, $resp_msg);

      $client->quit();

      $self->assert(-f $test_file,
        test_msg("File $test_file does not exist as expected"));

      my $expected = length($test_data);
      my $size = -s $test_file;
      $self->assert($expected == $size,
        test_msg("Expected size $expected, got $size"));
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_forward_userwithproxyauth_login {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/vhost.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/vhost.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  # Have separate Auth files for the proxy
  my $proxy_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $proxy_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $proxy_user = 'proxy-user';
  my $proxy_passwd = 'proxy-test';

  auth_user_write($proxy_user_file, $proxy_user, $proxy_passwd, $uid, $gid,
    $home_dir, '/bin/bash');
  auth_group_write($proxy_group_file, $group, $gid, $proxy_user);

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 17;

  my $proxy_config = get_forward_proxy_config($tmpdir, $log_file, $vhost_port);
  $proxy_config->{ProxyForwardMethod} = 'proxyuser,user@host';

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.conn:20 proxy.uri:20 proxy.forward:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20',

    AuthUserFile => $proxy_user_file,
    AuthGroupFile => $proxy_group_file,
    AuthOrder => 'mod_auth_file.c',
    ServerIdent => 'on "Forward Proxy Server"',
    SocketBindTight => 'on',

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },
  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  AuthUserFile $auth_user_file
  AuthGroupFile $auth_group_file
  AuthOrder mod_auth_file.c

  AllowOverride off
  WtmpLog off
  TransferLog none
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      my $client = ProFTPD::TestSuite::FTP->new('127.0.0.1', $port);
      $client->login($proxy_user, $proxy_passwd);
      $client->login("$user\@127.0.0.1:$vhost_port", $passwd);
      $client->quit();
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_forward_userwithproxyauth_login_user_incl_at_symbol {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/vhost.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/vhost.group");

  my $user = 'proftpd@proftpd.org';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  # Have separate Auth files for the proxy
  my $proxy_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $proxy_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $proxy_user = 'proxy-user';
  my $proxy_passwd = 'proxy-test';

  auth_user_write($proxy_user_file, $proxy_user, $proxy_passwd, $uid, $gid,
    $home_dir, '/bin/bash');
  auth_group_write($proxy_group_file, $group, $gid, $proxy_user);

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 17;

  my $proxy_config = get_forward_proxy_config($tmpdir, $log_file, $vhost_port);
  $proxy_config->{ProxyForwardMethod} = 'proxyuser,user@host';

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.conn:20 proxy.uri:20 proxy.forward:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20',

    AuthUserFile => $proxy_user_file,
    AuthGroupFile => $proxy_group_file,
    AuthOrder => 'mod_auth_file.c',
    ServerIdent => 'on "Forward Proxy Server"',
    SocketBindTight => 'on',

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },
  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  AuthUserFile $auth_user_file
  AuthGroupFile $auth_group_file
  AuthOrder mod_auth_file.c

  AllowOverride off
  WtmpLog off
  TransferLog none
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      my $client = ProFTPD::TestSuite::FTP->new('127.0.0.1', $port);
      $client->login($proxy_user, $proxy_passwd);
      $client->login("$user\@127.0.0.1:$vhost_port", $passwd);
      $client->quit();
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_forward_userwithproxyauth_login_failed_bad_dst_addr {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/vhost.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/vhost.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  # Have separate Auth files for the proxy
  my $proxy_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $proxy_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $proxy_user = 'proxy-user';
  my $proxy_passwd = 'proxy-test';

  auth_user_write($proxy_user_file, $proxy_user, $proxy_passwd, $uid, $gid,
    $home_dir, '/bin/bash');
  auth_group_write($proxy_group_file, $group, $gid, $proxy_user);

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 17;

  my $proxy_config = get_forward_proxy_config($tmpdir, $log_file, $vhost_port);
  $proxy_config->{ProxyForwardMethod} = 'proxyuser,user@host';

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.conn:20 proxy.uri:20 proxy.forward:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20',

    AuthUserFile => $proxy_user_file,
    AuthGroupFile => $proxy_group_file,
    AuthOrder => 'mod_auth_file.c',
    ServerIdent => 'on "Forward Proxy Server"',
    SocketBindTight => 'on',

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },
  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  AuthUserFile $auth_user_file
  AuthGroupFile $auth_group_file
  AuthOrder mod_auth_file.c

  AllowOverride off
  WtmpLog off
  TransferLog none
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      my $client = ProFTPD::TestSuite::FTP->new('127.0.0.1', $port);
      $client->login($proxy_user, $proxy_passwd);

      my $bad_addr = '1.2.3.4:5678';
      eval { $client->login("$user\@$bad_addr", $passwd) };
      unless ($@) {
        die("Destination login succeeded unexpectedly");
      }

      my $resp_code = $client->response_code();
      my $resp_msg = $client->response_msg();

      my $expected;

      $expected = 530;
      $self->assert($expected == $resp_code,
        test_msg("Expected response code $expected, got $resp_code"));

      $expected = "Unable to connect to $bad_addr: Network is unreachable";
      $self->assert($expected eq $resp_msg,
        test_msg("Expected response message '$expected', got '$resp_msg'"));

      $client->quit();
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_forward_userwithproxyauth_login_failed_non2xx {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/vhost.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/vhost.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  # Have separate Auth files for the proxy
  my $proxy_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $proxy_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $proxy_user = 'proxy-user';
  my $proxy_passwd = 'proxy-test';

  auth_user_write($proxy_user_file, $proxy_user, $proxy_passwd, $uid, $gid,
    $home_dir, '/bin/bash');
  auth_group_write($proxy_group_file, $group, $gid, $proxy_user);

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 17;

  my $proxy_config = get_forward_proxy_config($tmpdir, $log_file, $vhost_port);
  $proxy_config->{ProxyForwardMethod} = 'proxyuser,user@host';

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.conn:20 proxy.uri:20 proxy.forward:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20',

    AuthUserFile => $proxy_user_file,
    AuthGroupFile => $proxy_group_file,
    AuthOrder => 'mod_auth_file.c',
    ServerIdent => 'on "Forward Proxy Server"',
    SocketBindTight => 'on',

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },
  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  AuthUserFile $auth_user_file
  AuthGroupFile $auth_group_file
  AuthOrder mod_auth_file.c

  AllowOverride off
  WtmpLog off
  TransferLog none

  <Limit LOGIN>
    DenyUser $user
  </Limit>
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      my $client = ProFTPD::TestSuite::FTP->new('127.0.0.1', $port);
      $client->login($proxy_user, $proxy_passwd);

      eval { $client->login("$user\@127.0.0.1:$vhost_port", $passwd) };
      unless ($@) {
        die("Destination login succeeded unexpectedly");
      }

      my $resp_code = $client->response_code();
      my $resp_msg = $client->response_msg();

      my $expected;

      $expected = 530;
      $self->assert($expected == $resp_code,
        test_msg("Expected response code $expected, got $resp_code"));

      $expected = 'Login incorrect.';
      $self->assert($expected eq $resp_msg,
        test_msg("Expected response message '$expected', got '$resp_msg'"));

      $client->quit();
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_forward_userwithproxyauth_login_failed_limit_login {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/vhost.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/vhost.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  # Have separate Auth files for the proxy
  my $proxy_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $proxy_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $proxy_user = 'proxy-user';
  my $proxy_passwd = 'proxy-test';

  auth_user_write($proxy_user_file, $proxy_user, $proxy_passwd, $uid, $gid,
    $home_dir, '/bin/bash');
  auth_group_write($proxy_group_file, $group, $gid, $proxy_user);

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 17;

  my $proxy_config = get_forward_proxy_config($tmpdir, $log_file, $vhost_port);
  $proxy_config->{ProxyForwardMethod} = 'proxyuser,user@host';

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.conn:20 proxy.uri:20 proxy.forward:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20',

    AuthUserFile => $proxy_user_file,
    AuthGroupFile => $proxy_group_file,
    AuthOrder => 'mod_auth_file.c',
    ServerIdent => 'on "Forward Proxy Server"',
    SocketBindTight => 'on',

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },
  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  AuthUserFile $auth_user_file
  AuthGroupFile $auth_group_file
  AuthOrder mod_auth_file.c

  AllowOverride off
  WtmpLog off
  TransferLog none

  <Limit LOGIN>
    DenyAll
  </Limit>
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      my $client = ProFTPD::TestSuite::FTP->new('127.0.0.1', $port);
      $client->login($proxy_user, $proxy_passwd);

      eval { $client->login("$user\@127.0.0.1:$vhost_port", $passwd) };
      unless ($@) {
        die("Destination login succeeded unexpectedly");
      }

      my $resp_code = $client->response_code();
      my $resp_msg = $client->response_msg();

      my $expected;

      $expected = 530;
      $self->assert($expected == $resp_code,
        test_msg("Expected response code $expected, got $resp_code"));

      $expected = "Unable to connect to 127.0.0.1:$vhost_port: Operation not permitted";
      $self->assert($expected eq $resp_msg,
        test_msg("Expected response message '$expected', got '$resp_msg'"));

      $client->quit();
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_forward_userwithproxyauth_login_failed_bad_sequence {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/vhost.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/vhost.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  # Have separate Auth files for the proxy
  my $proxy_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $proxy_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $proxy_user = 'proxy-user';
  my $proxy_passwd = 'proxy-test';

  auth_user_write($proxy_user_file, $proxy_user, $proxy_passwd, $uid, $gid,
    $home_dir, '/bin/bash');
  auth_group_write($proxy_group_file, $group, $gid, $proxy_user);

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 17;

  my $proxy_config = get_forward_proxy_config($tmpdir, $log_file, $vhost_port);
  $proxy_config->{ProxyForwardMethod} = 'proxyuser,user@host';

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.conn:20 proxy.uri:20 proxy.forward:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20',

    AuthUserFile => $proxy_user_file,
    AuthGroupFile => $proxy_group_file,
    AuthOrder => 'mod_auth_file.c',
    ServerIdent => 'on "Forward Proxy Server"',
    SocketBindTight => 'on',

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },
  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  AuthUserFile $auth_user_file
  AuthGroupFile $auth_group_file
  AuthOrder mod_auth_file.c

  AllowOverride off
  WtmpLog off
  TransferLog none
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      my $client = ProFTPD::TestSuite::FTP->new('127.0.0.1', $port);

      $client->user($proxy_user);

      eval { $client->pwd() };
      unless ($@) {
        die("PWD after proxy USER succeeded unexpectedly");
      }

      my $resp_code = $client->response_code();
      my $resp_msg = $client->response_msg();

      my $expected;

      $expected = 530;
      $self->assert($expected == $resp_code,
        test_msg("Expected response code $expected, got $resp_code"));

      $expected = 'Please login with USER and PASS';
      $self->assert($expected eq $resp_msg,
        test_msg("Expected response message '$expected', got '$resp_msg'"));

      # Finish frontend authentication
      $client->pass($proxy_passwd);

      eval { $client->cwd("/") };
      unless ($@) {
        die("CWD after proxy PASS succeeded unexpectedly");
      }

      $resp_code = $client->response_code();
      $resp_msg = $client->response_msg();

      $expected = 530;
      $self->assert($expected == $resp_code,
        test_msg("Expected response code $expected, got $resp_code"));

      $expected = 'Access denied';
      $self->assert($expected eq $resp_msg,
        test_msg("Expected response message '$expected', got '$resp_msg'"));

      eval { $client->list() };
      unless ($@) {
        die("LIST after proxy PASS succeeded unexpectedly");
      }

      $resp_code = $client->response_code();
      $resp_msg = $client->response_msg();

      $expected = 530;
      $self->assert($expected == $resp_code,
        test_msg("Expected response code $expected, got $resp_code"));

      $expected = 'Access denied';
      $self->assert($expected eq $resp_msg,
        test_msg("Expected response message '$expected', got '$resp_msg'"));

      eval { $client->pwd() };
      unless ($@) {
        die("PWD after proxy PASS succeeded unexpectedly");
      }

      $resp_code = $client->response_code();
      $resp_msg = $client->response_msg();

      $expected = 530;
      $self->assert($expected == $resp_code,
        test_msg("Expected response code $expected, got $resp_code"));

      $expected = 'Access denied';
      $self->assert($expected eq $resp_msg,
        test_msg("Expected response message '$expected', got '$resp_msg'"));

      $client->user("$user\@127.0.0.1:$vhost_port");

      eval { $client->pwd() };
      unless ($@) {
        die("PWD after destination USER succeeded unexpectedly");
      }

      $resp_code = $client->response_code();
      $resp_msg = $client->response_msg();

      $expected = 530;
      $self->assert($expected == $resp_code,
        test_msg("Expected response code $expected, got $resp_code"));

      $expected = 'Please login with USER and PASS';
      $self->assert($expected eq $resp_msg,
        test_msg("Expected response message '$expected', got '$resp_msg'"));

      # Finish target authentication
      $client->pass($passwd);

      ($resp_code, $resp_msg) = $client->pwd();

      $expected = 257;
      $self->assert($expected == $resp_code,
        test_msg("Expected response code $expected, got $resp_code"));

      $client->quit();
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_forward_userwithproxyauth_login_failed_bad_proxy_passwd {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/vhost.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/vhost.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  # Have separate Auth files for the proxy
  my $proxy_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $proxy_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $proxy_user = 'proxy-user';
  my $proxy_passwd = 'proxy-test';

  auth_user_write($proxy_user_file, $proxy_user, $proxy_passwd, $uid, $gid,
    $home_dir, '/bin/bash');
  auth_group_write($proxy_group_file, $group, $gid, $proxy_user);

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 17;

  my $proxy_config = get_forward_proxy_config($tmpdir, $log_file, $vhost_port);
  $proxy_config->{ProxyForwardMethod} = 'proxyuser,user@host';

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.conn:20 proxy.uri:20 proxy.forward:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20',

    AuthUserFile => $proxy_user_file,
    AuthGroupFile => $proxy_group_file,
    AuthOrder => 'mod_auth_file.c',
    ServerIdent => 'on "Forward Proxy Server"',
    SocketBindTight => 'on',

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },
  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  AuthUserFile $auth_user_file
  AuthGroupFile $auth_group_file
  AuthOrder mod_auth_file.c

  AllowOverride off
  WtmpLog off
  TransferLog none
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      my $client = ProFTPD::TestSuite::FTP->new('127.0.0.1', $port);

      my $bad_passwd = "BadPassword";
      eval { $client->login($proxy_user, $bad_passwd) };
      unless ($@) {
        die("Proxy login succeeded unexpectedly");
      }

      my $resp_code = $client->response_code();
      my $resp_msg = $client->response_msg();

      my $expected = 530;
      $self->assert($expected == $resp_code,
        test_msg("Expected response code $expected, got $resp_code"));

      $expected = 'Login incorrect.';
      $self->assert($expected eq $resp_msg,
        test_msg("Expected response message '$expected', got '$resp_msg'"));

      eval { $client->login("$user\@127.0.0.1:$vhost_port", $passwd) };
      unless ($@) {
        die("Second login succeeded unexpectedly");
      }

      $resp_code = $client->response_code();
      $resp_msg = $client->response_msg();

      $expected = 530;
      $self->assert($expected == $resp_code,
        test_msg("Expected response code $expected, got $resp_code"));
      
      $expected = 'Login incorrect.';
      $self->assert($expected eq $resp_msg,
        test_msg("Expected response message '$expected', got '$resp_msg'"));
      
      $client->quit();
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_forward_userwithproxyauth_login_failed_bad_dst_passwd {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/vhost.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/vhost.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  # Have separate Auth files for the proxy
  my $proxy_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $proxy_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $proxy_user = 'proxy-user';
  my $proxy_passwd = 'proxy-test';

  auth_user_write($proxy_user_file, $proxy_user, $proxy_passwd, $uid, $gid,
    $home_dir, '/bin/bash');
  auth_group_write($proxy_group_file, $group, $gid, $proxy_user);

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 17;

  my $proxy_config = get_forward_proxy_config($tmpdir, $log_file, $vhost_port);
  $proxy_config->{ProxyForwardMethod} = 'proxyuser,user@host';

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.conn:20 proxy.uri:20 proxy.forward:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20',

    AuthUserFile => $proxy_user_file,
    AuthGroupFile => $proxy_group_file,
    AuthOrder => 'mod_auth_file.c',
    ServerIdent => 'on "Forward Proxy Server"',
    SocketBindTight => 'on',

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },
  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  AuthUserFile $auth_user_file
  AuthGroupFile $auth_group_file
  AuthOrder mod_auth_file.c

  AllowOverride off
  WtmpLog off
  TransferLog none
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      my $client = ProFTPD::TestSuite::FTP->new('127.0.0.1', $port);
      $client->login($proxy_user, $proxy_passwd);

      my $bad_passwd = "BadPassword";
      eval { $client->login("$user\@127.0.0.1:$vhost_port", $bad_passwd) };
      unless ($@) {
        die("Destination login succeeded unexpectedly");
      }

      my $resp_code = $client->response_code();
      my $resp_msg = $client->response_msg();

      my $expected = 530;
      $self->assert($expected == $resp_code,
        test_msg("Expected response code $expected, got $resp_code"));
      
      $expected = 'Login incorrect.';
      $self->assert($expected eq $resp_msg,
        test_msg("Expected response message '$expected', got '$resp_msg'"));
      
      $client->quit();
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_forward_userwithproxyauth_bad_sequence_no_dst_login {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/vhost.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/vhost.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  # Have separate Auth files for the proxy
  my $proxy_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $proxy_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $proxy_user = 'proxy-user';
  my $proxy_passwd = 'proxy-test';

  auth_user_write($proxy_user_file, $proxy_user, $proxy_passwd, $uid, $gid,
    $home_dir, '/bin/bash');
  auth_group_write($proxy_group_file, $group, $gid, $proxy_user);

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 17;

  my $proxy_config = get_forward_proxy_config($tmpdir, $log_file, $vhost_port);
  $proxy_config->{ProxyForwardMethod} = 'proxyuser,user@host';

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.conn:20 proxy.uri:20 proxy.forward:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20',

    AuthUserFile => $proxy_user_file,
    AuthGroupFile => $proxy_group_file,
    AuthOrder => 'mod_auth_file.c',
    ServerIdent => 'on "Forward Proxy Server"',
    SocketBindTight => 'on',

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },
  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  AuthUserFile $auth_user_file
  AuthGroupFile $auth_group_file
  AuthOrder mod_auth_file.c

  AllowOverride off
  WtmpLog off
  TransferLog none
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      my $client = ProFTPD::TestSuite::FTP->new('127.0.0.1', $port);
      $client->login($proxy_user, $proxy_passwd);

      my $bad_user = "BadUser";
      eval { $client->login("$bad_user\@127.0.0.1:$vhost_port", $passwd) };
      unless ($@) {
        die("Destination login succeeded unexpectedly");
      }

      my $resp_code = $client->response_code();
      my $resp_msg = $client->response_msg();

      my $expected = 530;
      $self->assert($expected == $resp_code,
        test_msg("Expected response code $expected, got $resp_code"));
      
      $expected = 'Login incorrect.';
      $self->assert($expected eq $resp_msg,
        test_msg("Expected response message '$expected', got '$resp_msg'"));
      
      $client->quit();
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_forward_proxyuserwithproxyauth_login {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/vhost.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/vhost.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  # Have separate Auth files for the proxy
  my $proxy_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $proxy_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $proxy_user = 'proxy-user';
  my $proxy_passwd = 'proxy-test';

  auth_user_write($proxy_user_file, $proxy_user, $proxy_passwd, $uid, $gid,
    $home_dir, '/bin/bash');
  auth_group_write($proxy_group_file, $group, $gid, $proxy_user);

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 17;

  my $proxy_config = get_forward_proxy_config($tmpdir, $log_file, $vhost_port);
  $proxy_config->{ProxyForwardMethod} = 'proxyuser@host,user';

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.conn:20 proxy.uri:20 proxy.forward:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20',

    AuthUserFile => $proxy_user_file,
    AuthGroupFile => $proxy_group_file,
    AuthOrder => 'mod_auth_file.c',
    ServerIdent => 'on "Forward Proxy Server"',
    SocketBindTight => 'on',

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },
  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  AuthUserFile $auth_user_file
  AuthGroupFile $auth_group_file
  AuthOrder mod_auth_file.c

  AllowOverride off
  WtmpLog off
  TransferLog none
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      my $client = ProFTPD::TestSuite::FTP->new('127.0.0.1', $port);
      $client->login("$proxy_user\@127.0.0.1:$vhost_port", $proxy_passwd);
      $client->login($user, $passwd);
      $client->quit();
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_forward_proxyuserwithproxyauth_login_user_incl_at_symbol {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/vhost.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/vhost.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  # Have separate Auth files for the proxy
  my $proxy_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $proxy_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $proxy_user = 'proxy-user@proftpd.org';
  my $proxy_passwd = 'proxy-test';

  auth_user_write($proxy_user_file, $proxy_user, $proxy_passwd, $uid, $gid,
    $home_dir, '/bin/bash');
  auth_group_write($proxy_group_file, $group, $gid, $proxy_user);

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 17;

  my $proxy_config = get_forward_proxy_config($tmpdir, $log_file, $vhost_port);
  $proxy_config->{ProxyForwardMethod} = 'proxyuser@host,user';

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.conn:20 proxy.uri:20 proxy.forward:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20',

    AuthUserFile => $proxy_user_file,
    AuthGroupFile => $proxy_group_file,
    AuthOrder => 'mod_auth_file.c',
    ServerIdent => 'on "Forward Proxy Server"',
    SocketBindTight => 'on',

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },
  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  AuthUserFile $auth_user_file
  AuthGroupFile $auth_group_file
  AuthOrder mod_auth_file.c

  AllowOverride off
  WtmpLog off
  TransferLog none
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      my $client = ProFTPD::TestSuite::FTP->new('127.0.0.1', $port);
      $client->login("$proxy_user\@127.0.0.1:$vhost_port", $proxy_passwd);
      $client->login($user, $passwd);
      $client->quit();
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_forward_proxyuserwithproxyauth_login_failed_bad_dst_addr {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/vhost.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/vhost.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  # Have separate Auth files for the proxy
  my $proxy_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $proxy_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $proxy_user = 'proxy-user';
  my $proxy_passwd = 'proxy-test';

  auth_user_write($proxy_user_file, $proxy_user, $proxy_passwd, $uid, $gid,
    $home_dir, '/bin/bash');
  auth_group_write($proxy_group_file, $group, $gid, $proxy_user);

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 17;

  my $proxy_config = get_forward_proxy_config($tmpdir, $log_file, $vhost_port);
  $proxy_config->{ProxyForwardMethod} = 'proxyuser@host,user';

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.conn:20 proxy.uri:20 proxy.forward:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20',

    AuthUserFile => $proxy_user_file,
    AuthGroupFile => $proxy_group_file,
    AuthOrder => 'mod_auth_file.c',
    ServerIdent => 'on "Forward Proxy Server"',
    SocketBindTight => 'on',

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },
  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  AuthUserFile $auth_user_file
  AuthGroupFile $auth_group_file
  AuthOrder mod_auth_file.c

  AllowOverride off
  WtmpLog off
  TransferLog none
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      my $client = ProFTPD::TestSuite::FTP->new('127.0.0.1', $port);

      my $bad_addr = '1.2.3.4:5678';
      $client->login("$proxy_user\@$bad_addr", $proxy_passwd);

      eval { $client->login($user, $passwd) };
      unless ($@) {
        die("Destination login succeeded unexpectedly");
      }

      my $resp_code = $client->response_code();
      my $resp_msg = $client->response_msg();

      my $expected;

      $expected = 530;
      $self->assert($expected == $resp_code,
        test_msg("Expected response code $expected, got $resp_code"));

      $expected = "Unable to connect to $bad_addr: Network is unreachable";
      $self->assert($expected eq $resp_msg,
        test_msg("Expected response message '$expected', got '$resp_msg'"));

      $client->quit();
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_forward_proxyuserwithproxyauth_login_failed_non2xx {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/vhost.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/vhost.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  # Have separate Auth files for the proxy
  my $proxy_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $proxy_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $proxy_user = 'proxy-user';
  my $proxy_passwd = 'proxy-test';

  auth_user_write($proxy_user_file, $proxy_user, $proxy_passwd, $uid, $gid,
    $home_dir, '/bin/bash');
  auth_group_write($proxy_group_file, $group, $gid, $proxy_user);

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 17;

  my $proxy_config = get_forward_proxy_config($tmpdir, $log_file, $vhost_port);
  $proxy_config->{ProxyForwardMethod} = 'proxyuser@host,user';

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.conn:20 proxy.uri:20 proxy.forward:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20',

    AuthUserFile => $proxy_user_file,
    AuthGroupFile => $proxy_group_file,
    AuthOrder => 'mod_auth_file.c',
    ServerIdent => 'on "Forward Proxy Server"',
    SocketBindTight => 'on',

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },
  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  AuthUserFile $auth_user_file
  AuthGroupFile $auth_group_file
  AuthOrder mod_auth_file.c

  AllowOverride off
  WtmpLog off
  TransferLog none

  <Limit LOGIN>
    DenyUser $user
  </Limit>
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      my $client = ProFTPD::TestSuite::FTP->new('127.0.0.1', $port);
      $client->login("$proxy_user\@127.0.0.1:$vhost_port", $proxy_passwd);

      eval { $client->login($user, $passwd) };
      unless ($@) {
        die("Destination login succeeded unexpectedly");
      }

      my $resp_code = $client->response_code();
      my $resp_msg = $client->response_msg();

      my $expected;

      $expected = 530;
      $self->assert($expected == $resp_code,
        test_msg("Expected response code $expected, got $resp_code"));

      $expected = 'Login incorrect.';
      $self->assert($expected eq $resp_msg,
        test_msg("Expected response message '$expected', got '$resp_msg'"));

      $client->quit();
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_forward_proxyuserwithproxyauth_login_failed_limit_login {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/vhost.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/vhost.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  # Have separate Auth files for the proxy
  my $proxy_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $proxy_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $proxy_user = 'proxy-user';
  my $proxy_passwd = 'proxy-test';

  auth_user_write($proxy_user_file, $proxy_user, $proxy_passwd, $uid, $gid,
    $home_dir, '/bin/bash');
  auth_group_write($proxy_group_file, $group, $gid, $proxy_user);

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 17;

  my $proxy_config = get_forward_proxy_config($tmpdir, $log_file, $vhost_port);
  $proxy_config->{ProxyForwardMethod} = 'proxyuser@host,user';

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.conn:20 proxy.uri:20 proxy.forward:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20',

    AuthUserFile => $proxy_user_file,
    AuthGroupFile => $proxy_group_file,
    AuthOrder => 'mod_auth_file.c',
    ServerIdent => 'on "Forward Proxy Server"',
    SocketBindTight => 'on',

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },
  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  AuthUserFile $auth_user_file
  AuthGroupFile $auth_group_file
  AuthOrder mod_auth_file.c

  AllowOverride off
  WtmpLog off
  TransferLog none

  <Limit LOGIN>
    DenyAll
  </Limit>
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      my $client = ProFTPD::TestSuite::FTP->new('127.0.0.1', $port);
      $client->login("$proxy_user\@127.0.0.1:$vhost_port", $proxy_passwd);

      eval { $client->login($user, $passwd) };
      unless ($@) {
        die("Destination login succeeded unexpectedly");
      }

      my $resp_code = $client->response_code();
      my $resp_msg = $client->response_msg();

      my $expected;

      $expected = 530;
      $self->assert($expected == $resp_code,
        test_msg("Expected response code $expected, got $resp_code"));

      $expected = "Unable to connect to 127.0.0.1:$vhost_port: Operation not permitted";
      $self->assert($expected eq $resp_msg,
        test_msg("Expected response message '$expected', got '$resp_msg'"));

      $client->quit();
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_forward_proxyuserwithproxyauth_login_failed_bad_sequence {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/vhost.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/vhost.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  # Have separate Auth files for the proxy
  my $proxy_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $proxy_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $proxy_user = 'proxy-user';
  my $proxy_passwd = 'proxy-test';

  auth_user_write($proxy_user_file, $proxy_user, $proxy_passwd, $uid, $gid,
    $home_dir, '/bin/bash');
  auth_group_write($proxy_group_file, $group, $gid, $proxy_user);

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 17;

  my $proxy_config = get_forward_proxy_config($tmpdir, $log_file, $vhost_port);
  $proxy_config->{ProxyForwardMethod} = 'proxyuser@host,user';

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.conn:20 proxy.uri:20 proxy.forward:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20',

    AuthUserFile => $proxy_user_file,
    AuthGroupFile => $proxy_group_file,
    AuthOrder => 'mod_auth_file.c',
    ServerIdent => 'on "Forward Proxy Server"',
    SocketBindTight => 'on',

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },
  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  AuthUserFile $auth_user_file
  AuthGroupFile $auth_group_file
  AuthOrder mod_auth_file.c

  AllowOverride off
  WtmpLog off
  TransferLog none
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      my $client = ProFTPD::TestSuite::FTP->new('127.0.0.1', $port);

      $client->user("$proxy_user\@127.0.0.1:$vhost_port");

      eval { $client->pwd() };
      unless ($@) {
        die("PWD after proxy USER succeeded unexpectedly");
      }

      my $resp_code = $client->response_code();
      my $resp_msg = $client->response_msg();

      my $expected;

      $expected = 530;
      $self->assert($expected == $resp_code,
        test_msg("Expected response code $expected, got $resp_code"));

      $expected = 'Please login with USER and PASS';
      $self->assert($expected eq $resp_msg,
        test_msg("Expected response message '$expected', got '$resp_msg'"));

      # Finish frontend authentication
      $client->pass($proxy_passwd);

      eval { $client->cwd("/") };
      unless ($@) {
        die("CWD after proxy PASS succeeded unexpectedly");
      }

      $resp_code = $client->response_code();
      $resp_msg = $client->response_msg();

      $expected = 530;
      $self->assert($expected == $resp_code,
        test_msg("Expected response code $expected, got $resp_code"));

      $expected = 'Access denied';
      $self->assert($expected eq $resp_msg,
        test_msg("Expected response message '$expected', got '$resp_msg'"));

      eval { $client->list() };
      unless ($@) {
        die("LIST after proxy PASS succeeded unexpectedly");
      }

      $resp_code = $client->response_code();
      $resp_msg = $client->response_msg();

      $expected = 530;
      $self->assert($expected == $resp_code,
        test_msg("Expected response code $expected, got $resp_code"));

      $expected = 'Access denied';
      $self->assert($expected eq $resp_msg,
        test_msg("Expected response message '$expected', got '$resp_msg'"));

      eval { $client->pwd() };
      unless ($@) {
        die("PWD after proxy PASS succeeded unexpectedly");
      }

      $resp_code = $client->response_code();
      $resp_msg = $client->response_msg();

      $expected = 530;
      $self->assert($expected == $resp_code,
        test_msg("Expected response code $expected, got $resp_code"));

      $expected = 'Access denied';
      $self->assert($expected eq $resp_msg,
        test_msg("Expected response message '$expected', got '$resp_msg'"));

      $client->user($user);

      eval { $client->pwd() };
      unless ($@) {
        die("PWD after destination USER succeeded unexpectedly");
      }

      $resp_code = $client->response_code();
      $resp_msg = $client->response_msg();

      $expected = 530;
      $self->assert($expected == $resp_code,
        test_msg("Expected response code $expected, got $resp_code"));

      $expected = 'Please login with USER and PASS';
      $self->assert($expected eq $resp_msg,
        test_msg("Expected response message '$expected', got '$resp_msg'"));

      # Finish target authentication
      $client->pass($passwd);

      ($resp_code, $resp_msg) = $client->pwd();

      $expected = 257;
      $self->assert($expected == $resp_code,
        test_msg("Expected response code $expected, got $resp_code"));

      $client->quit();
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_forward_proxyuserwithproxyauth_login_failed_bad_proxy_passwd {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/vhost.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/vhost.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  # Have separate Auth files for the proxy
  my $proxy_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $proxy_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $proxy_user = 'proxy-user';
  my $proxy_passwd = 'proxy-test';

  auth_user_write($proxy_user_file, $proxy_user, $proxy_passwd, $uid, $gid,
    $home_dir, '/bin/bash');
  auth_group_write($proxy_group_file, $group, $gid, $proxy_user);

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 17;

  my $proxy_config = get_forward_proxy_config($tmpdir, $log_file, $vhost_port);
  $proxy_config->{ProxyForwardMethod} = 'proxyuser@host,user';

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.conn:20 proxy.uri:20 proxy.forward:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20',

    AuthUserFile => $proxy_user_file,
    AuthGroupFile => $proxy_group_file,
    AuthOrder => 'mod_auth_file.c',
    ServerIdent => 'on "Forward Proxy Server"',
    SocketBindTight => 'on',

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },
  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  AuthUserFile $auth_user_file
  AuthGroupFile $auth_group_file
  AuthOrder mod_auth_file.c

  AllowOverride off
  WtmpLog off
  TransferLog none
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      my $client = ProFTPD::TestSuite::FTP->new('127.0.0.1', $port);

      my $bad_passwd = "BadPassword";
      eval { $client->login("$proxy_user\@127.0.0.1:$vhost_port", $bad_passwd) };
      unless ($@) {
        die("Proxy login succeeded unexpectedly");
      }

      my $resp_code = $client->response_code();
      my $resp_msg = $client->response_msg();

      my $expected = 530;
      $self->assert($expected == $resp_code,
        test_msg("Expected response code $expected, got $resp_code"));

      $expected = 'Login incorrect.';
      $self->assert($expected eq $resp_msg,
        test_msg("Expected response message '$expected', got '$resp_msg'"));

      eval { $client->login($user, $passwd) };
      unless ($@) {
        die("Second login succeeded unexpectedly");
      }

      $resp_code = $client->response_code();
      $resp_msg = $client->response_msg();

      $expected = 530;
      $self->assert($expected == $resp_code,
        test_msg("Expected response code $expected, got $resp_code"));
      
      $expected = 'Login incorrect.';
      $self->assert($expected eq $resp_msg,
        test_msg("Expected response message '$expected', got '$resp_msg'"));
      
      $client->quit();
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_forward_proxyuserwithproxyauth_login_failed_bad_dst_passwd {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/vhost.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/vhost.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  # Have separate Auth files for the proxy
  my $proxy_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $proxy_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $proxy_user = 'proxy-user';
  my $proxy_passwd = 'proxy-test';

  auth_user_write($proxy_user_file, $proxy_user, $proxy_passwd, $uid, $gid,
    $home_dir, '/bin/bash');
  auth_group_write($proxy_group_file, $group, $gid, $proxy_user);

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 17;

  my $proxy_config = get_forward_proxy_config($tmpdir, $log_file, $vhost_port);
  $proxy_config->{ProxyForwardMethod} = 'proxyuser@host,user';

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.conn:20 proxy.uri:20 proxy.forward:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20',

    AuthUserFile => $proxy_user_file,
    AuthGroupFile => $proxy_group_file,
    AuthOrder => 'mod_auth_file.c',
    ServerIdent => 'on "Forward Proxy Server"',
    SocketBindTight => 'on',

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },
  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  AuthUserFile $auth_user_file
  AuthGroupFile $auth_group_file
  AuthOrder mod_auth_file.c

  AllowOverride off
  WtmpLog off
  TransferLog none
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      my $client = ProFTPD::TestSuite::FTP->new('127.0.0.1', $port);
      $client->login("$proxy_user\@127.0.0.1:$vhost_port", $proxy_passwd);

      my $bad_passwd = "BadPassword";
      eval { $client->login($user, $bad_passwd) };
      unless ($@) {
        die("Destination login succeeded unexpectedly");
      }

      my $resp_code = $client->response_code();
      my $resp_msg = $client->response_msg();

      my $expected = 530;
      $self->assert($expected == $resp_code,
        test_msg("Expected response code $expected, got $resp_code"));
      
      $expected = 'Login incorrect.';
      $self->assert($expected eq $resp_msg,
        test_msg("Expected response message '$expected', got '$resp_msg'"));
      
      $client->quit();
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

sub proxy_forward_proxyuserwithproxyauth_bad_sequence_no_dst_login {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};

  my $config_file = "$tmpdir/proxy.conf";
  my $pid_file = File::Spec->rel2abs("$tmpdir/proxy.pid");
  my $scoreboard_file = File::Spec->rel2abs("$tmpdir/proxy.scoreboard");

  my $log_file = test_get_logfile();

  my $auth_user_file = File::Spec->rel2abs("$tmpdir/vhost.passwd");
  my $auth_group_file = File::Spec->rel2abs("$tmpdir/vhost.group");

  my $user = 'proftpd';
  my $passwd = 'test';
  my $group = 'ftpd';
  my $home_dir = File::Spec->rel2abs($tmpdir);
  my $uid = 500;
  my $gid = 500;

  # Make sure that, if we're running as root, that the home directory has
  # permissions/privs set for the account we create
  if ($< == 0) {
    unless (chmod(0755, $home_dir)) {
      die("Can't set perms on $home_dir to 0755: $!");
    }

    unless (chown($uid, $gid, $home_dir)) {
      die("Can't set owner of $home_dir to $uid/$gid: $!");
    }
  }

  auth_user_write($auth_user_file, $user, $passwd, $uid, $gid, $home_dir,
    '/bin/bash');
  auth_group_write($auth_group_file, $group, $gid, $user);

  # Have separate Auth files for the proxy
  my $proxy_user_file = File::Spec->rel2abs("$tmpdir/proxy.passwd");
  my $proxy_group_file = File::Spec->rel2abs("$tmpdir/proxy.group");

  my $proxy_user = 'proxy-user';
  my $proxy_passwd = 'proxy-test';

  auth_user_write($proxy_user_file, $proxy_user, $proxy_passwd, $uid, $gid,
    $home_dir, '/bin/bash');
  auth_group_write($proxy_group_file, $group, $gid, $proxy_user);

  my $vhost_port = ProFTPD::TestSuite::Utils::get_high_numbered_port();
  $vhost_port += 17;

  my $proxy_config = get_forward_proxy_config($tmpdir, $log_file, $vhost_port);
  $proxy_config->{ProxyForwardMethod} = 'proxyuser@host,user';

  my $config = {
    PidFile => $pid_file,
    ScoreboardFile => $scoreboard_file,
    SystemLog => $log_file,
    TraceLog => $log_file,
    Trace => 'DEFAULT:10 event:0 lock:0 scoreboard:0 signal:0 proxy:20 proxy.conn:20 proxy.uri:20 proxy.forward:20 proxy.ftp.conn:20 proxy.ftp.ctrl:20 proxy.ftp.data:20 proxy.ftp.msg:20',

    AuthUserFile => $proxy_user_file,
    AuthGroupFile => $proxy_group_file,
    AuthOrder => 'mod_auth_file.c',
    ServerIdent => 'on "Forward Proxy Server"',
    SocketBindTight => 'on',

    IfModules => {
      'mod_proxy.c' => $proxy_config,

      'mod_delay.c' => {
        DelayEngine => 'off',
      },
    },
  };

  my ($port, $config_user, $config_group) = config_write($config_file, $config);

  if (open(my $fh, ">> $config_file")) {
    print $fh <<EOC;
<VirtualHost 127.0.0.1>
  Port $vhost_port
  ServerName "Real Server"

  AuthUserFile $auth_user_file
  AuthGroupFile $auth_group_file
  AuthOrder mod_auth_file.c

  AllowOverride off
  WtmpLog off
  TransferLog none
</VirtualHost>
EOC
    unless (close($fh)) {
      die("Can't write $config_file: $!");
    }

  } else {
    die("Can't open $config_file: $!");
  }

  # Open pipes, for use between the parent and child processes.  Specifically,
  # the child will indicate when it's done with its test by writing a message
  # to the parent.
  my ($rfh, $wfh);
  unless (pipe($rfh, $wfh)) {
    die("Can't open pipe: $!");
  }

  my $ex;

  # Fork child
  $self->handle_sigchld();
  defined(my $pid = fork()) or die("Can't fork: $!");
  if ($pid) {
    eval {
      my $client = ProFTPD::TestSuite::FTP->new('127.0.0.1', $port);
      $client->login("$proxy_user\@127.0.0.1:$vhost_port", $proxy_passwd);

      my $bad_user = "BadUser";
      eval { $client->login($bad_user, $passwd) };
      unless ($@) {
        die("Destination login succeeded unexpectedly");
      }

      my $resp_code = $client->response_code();
      my $resp_msg = $client->response_msg();

      my $expected = 530;
      $self->assert($expected == $resp_code,
        test_msg("Expected response code $expected, got $resp_code"));
      
      $expected = 'Login incorrect.';
      $self->assert($expected eq $resp_msg,
        test_msg("Expected response message '$expected', got '$resp_msg'"));
      
      $client->quit();
    };

    if ($@) {
      $ex = $@;
    }

    $wfh->print("done\n");
    $wfh->flush();

  } else {
    eval { server_wait($config_file, $rfh) };
    if ($@) {
      warn($@);
      exit 1;
    }

    exit 0;
  }

  # Stop server
  server_stop($pid_file);

  $self->assert_child_ok($pid);

  if ($ex) {
    test_append_logfile($log_file, $ex);
    unlink($log_file);

    die($ex);
  }

  unlink($log_file);
}

1;
