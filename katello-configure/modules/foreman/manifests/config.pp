class foreman::config {

  file { $foreman::app_root:
    ensure  => directory,
  }

  # cleans up the session entries in the database
  # if you are using fact or report importers, this creates a session per
  # request which can easily result with a lot of old and unrequired in your
  # database eventually slowing it down.
  cron{'clear_session_table':
    command => "(cd ${foreman::app_root} && rake db:sessions:clear)",
    minute  => '15',
    hour    => '23',
  }

  postgres::createuser { $foreman::db_user:
    passwd  => $foreman::db_pass,
    logfile => "${foreman::configure_log_base}/create-postgresql-foreman-user.log",
    require => [ File["${foreman::configure_log_base}"] ],
  }

  postgres::createdb {$foreman::db_name:
    owner   => $foreman::db_user,
    logfile => "${foreman::configure_log_base}/create-postgresql-foreman-database.log",
    require => [ Postgres::Createuser[$foreman::db_user], File["${foreman::log_base}"] ],
  }

  user { $foreman::user:
    ensure  => 'present',
    shell   => '/sbin/nologin',
    comment => 'Foreman',
    home    => $foreman::app_root,
  }
  
  file {
    "${foreman::log_base}":
      owner   => $foreman::user,
      group   => $foreman::group,
      mode    => 640,
      recurse => true;

    # create Rails logs in advance to get correct owners and permissions
    "${foreman::log_base}/production.log":
      owner   => $foreman::user,
      group   => $foreman::group,
      content => "",
      replace => false,
      mode    => 640,
      require => File["${foreman::log_base}"];

    "${foreman::config_dir}/settings.yaml":
      content => template('foreman/settings.yaml.erb'),
      owner   => $foreman::user;

    "${foreman::config_dir}/thin.yml":
      content => template("foreman/thin.yml.erb"),
      owner   => "root",
      group   => "root",
      mode    => "644";

    "${foreman::config_dir}/database.yml":
      content => template("foreman/database.yml.erb"),
      owner   => $foreman::user,
      group   => $foreman::user,
      mode    => "600";

    "/etc/sysconfig/foreman":
      content => template("foreman/sysconfig.erb"),
      owner   => "root",
      group   => "root",
      mode    => "644";

    "/etc/httpd/conf.d/foreman.conf":
      content => template("foreman/httpd.conf.erb"),
      owner   => $foreman::user,
      group   => $foreman::user,
      mode    => "600";
  }

  exec {"foreman_migrate_db":
    cwd         => $foreman::app_root,
    environment => "RAILS_ENV=${foreman::environment}",
    command     => "/usr/bin/env rake db:migrate --trace --verbose > ${foreman::configure_log_base}/foreman-db-migrate.log 2>&1 && touch /var/lib/katello/foreman_db_migrate_done",
    creates     => "/var/lib/katello/foreman_db_migrate_done",
    timeout     => 0,
    require     => [ Postgres::Createdb[$foreman::db_name],
                 File["${foreman::log_base}/production.log"],
                 File["${foreman::config_dir}/settings.yaml"],
                 File["${foreman::config_dir}/database.yml"]];
  } ~>

  exec {"foreman_config":
   command => "/usr/bin/ruby ${foreman::app_root}/script/foreman-config -k oauth_active -v '${foreman::oauth_active}'\
                              -k oauth_consumer_key -v '${foreman::oauth_consumer_key}'\
                              -k oauth_consumer_secret -v '${foreman::oauth_consumer_secret}'\
                              -k oauth_map_users -v '${foreman::oauth_map_users}'",
   user    => $foreman::user,
   timeout => 0,
   require => User[$foreman::user],
  }

}
