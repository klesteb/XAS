
use lib '../lib';
use Config::IniFiles;
use Data::Dumper;
use XAS::Factory;

our $MESSAGES;

use XAS::Class
  version    => '0.01',
  base       => 'XAS::Base',
  utils      => 'dir_walk',
  import     => 'class CLASS',
  filesystem => 'Dir',
;

my $env = XAS::Factory->module('environment');

sub load_msgs {

    my $messages;

    foreach my $path (@INC) {

        my $dir = Dir($path, 'XAS', 'Msgs');

        if ($dir->exists) {

            printf("found: %s\n", $dir->path);

            dir_walk(
                -directory => $dir, 
                -filter    => $env->msgs, 
                -callback  => sub {
                    my $file = shift;

                    my $cfg = Config::IniFiles->new(-file => $file->path);
                    if (my @names = $cfg->Parameters('messages')) {
                        
                        foreach my $name (@names) {
                            
                            $messages->{$name} = $cfg->val('messages', $name);

                        }

                    }

                }
            );

        }

    }

    class->vars('MESSAGES', $messages);

}

load_msgs();

my $msgs = class->var('MESSAGES');
warn Dumper($msgs);

CLASS->log->info_msg('exception', 'first', 'second');
CLASS->throw_msg('testing', 'exception', 'first', 'second');

