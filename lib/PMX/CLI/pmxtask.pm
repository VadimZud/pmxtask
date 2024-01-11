package PMX::CLI::pmxtask;

use strict;
use warnings;
use PVE::RPCEnvironment;
use PVE::JSONSchema qw(get_standard_option);
use PVE::Tools;
use PVE::Cluster;
use PVE::INotify;

use base qw(PVE::CLIHandler);

sub setup_environment {
    PVE::RPCEnvironment->setup_default_cli_env();
}

__PACKAGE__->register_method ({
    name => 'pmxtask',
    path => 'pmxtask',
    method => 'POST',
    description => "Start <command> as Proxmox task.",
    parameters => {
	    additionalProperties => 0,
	    properties => {
            command => {
                description => "Command.",
                type => 'string',
            },
            'extra-args' => get_standard_option('extra-args', {
		        description => "Command arguments." }),
            notify => {
                type => 'boolean',
                description => "Send notification mail about finished task (to email address specified for user 'root\@pam').",
                optional => 1,
                default => 0,
            },
            notifyerr => {
                type => 'boolean',
                description => "Send notification mail about failed task (to email address specified for user 'root\@pam').",
                optional => 1,
                default => 0,
            },
            quiet => {
                type => 'boolean',
                description => "Only produces output suitable for logging, omitting progress indicators.",
                optional => 1,
                default => 0,
            },
            dtype => {
                description => "Task description.",
                type => 'string',
                optional => 1,
                default => 'pmxtask',
            },
            background => {
                description => "Start task in background.",
                type => 'boolean',
                optional => 1,
                default => '0',
            },
        }
    },
    returns => { type => 'object' },
    code => sub {
        my ($param) = @_;

        my $rpcenv = PVE::RPCEnvironment::get();

        my $authuser = $rpcenv->get_user();

        my $dtype = $param->{dtype} // 'pmxtask';

        my $realcmd = sub {
            my $upid = shift;

            my $cmd = [$param->{command}, @{$param->{'extra-args'}}];

            my %run_param = (noerr => 1);
            $run_param{quiet} = 1 if $param->{quiet};

            print "starting @$cmd\n" if !$param->{quiet};

            my $exitcode = PVE::Tools::run_command($cmd, %run_param);
            
            if ($param->{notify} || ($param->{notifyerr} && $exitcode)) {

                my $usercfg = PVE::Cluster::cfs_read_file("user.cfg");
                my $rootcfg = $usercfg->{users}->{'root@pam'} || {};
                my $mailto = $rootcfg->{email};

                if ($mailto) {
                    my $hostname = `hostname -f` || PVE::INotify::nodename();
                    chomp $hostname;

                    my $dcconf = eval { PVE::Cluster::cfs_read_file('datacenter.cfg') } // {};
                    my $mailfrom = $dcconf->{email_from} || "root";

                    my $subject = "pmxtask status ($hostname): $dtype ".($exitcode ? "failed" : "successful");

                    my ($task, $filename) = PVE::Tools::upid_decode($upid, 1);
                    my $tasklog;
                    if (open(my $fh, '<', $filename)) {
                        {
                            local $/;
                            $tasklog = <$fh>;
                        }
                        close($fh);
                    }

                    my $text = "Task UPID: $upid\nCommand: @$cmd\n\n".(defined($tasklog) ? 
                        "Detailed task log:\n\n$tasklog" :
                        "Detailed task log cannot be opened: $!");
                    my $html = "<b>Task UPID:</b> $upid<br /><b>Command:</b> @$cmd<br />".(defined($tasklog) ? 
                        "<b>Detailed task log:</b><br /><pre>$tasklog</pre>" :
                        "<b>Detailed task log cannot be opened:</b> $!");

                    PVE::Tools::sendmail($mailto, $subject, $text, $html, $mailfrom, '');
                }
            }

            die "command '@$cmd' failed: exit code $exitcode\n" if $exitcode;

            return;
        };

        my $upid = $rpcenv->fork_worker($dtype, undef, $authuser, $realcmd, $param->{background});
        return {
            upid => $upid,
            background => $param->{background},
        }
    }});

our $cmddef = [ __PACKAGE__, 'pmxtask', ['command', 'extra-args'], undef, sub {
                  my $res = shift;

                  print $res->{upid}, "\n";

                  unless ($res->{background}) {
                      my $status = PVE::Tools::upid_read_status($res->{upid});
                      exit(PVE::Tools::upid_status_is_error($status) ? -1 : 0);
                  }         
              }];

1;