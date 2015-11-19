
use lib '../lib';
use XAS::Lib::Modules::Environment;

my $env = XAS::Lib::Modules::Environment->new();

printf("+------------------------------+\n");
printf("| System                       |\n");
printf("+------------------------------+\n");
printf("host     = %s\n", $env->host);
printf("domain   = %s\n", $env->domain);
printf("username = %s\n", $env->username);
printf("mqserver = %s\n", $env->mqserver);
printf("mqport   = %s\n", $env->mqport);
printf("mqlevel  = %s\n", $env->mqlevel);
printf("mxserver = %s\n", $env->mxserver);
printf("mxport   = %s\n", $env->mxport);
printf("mxmailer = %s\n", $env->mxmailer);
printf("+------------------------------+\n");
printf("| Environment                  |\n");
printf("+------------------------------+\n");
printf("ROOT   = %s\n", $env->root);
printf("ETC    = %s\n", $env->etc);
printf("SBIN   = %s\n", $env->sbin);
printf("BIN    = %s\n", $env->bin);
printf("TMP    = %s\n", $env->tmp);
printf("VAR    = %s\n", $env->var);
printf("LIB    = %s\n", $env->lib);
printf("LOG    = %s\n", $env->log);
printf("RUN    = %s\n", $env->run);
printf("SPOOL  = %s\n", $env->spool);
printf("+------------------------------+\n");
printf("| Files                        |\n");
printf("+------------------------------+\n");
printf("logfile = %s\n", $env->log_file);
printf("pidfile = %s\n", $env->pid_file);
printf("cfgfile = %s\n", $env->cfg_file);
printf("+------------------------------+\n");
printf("| Other                        |\n");
printf("+------------------------------+\n");
printf("alerts      = %s\n", $env->alerts);
printf("xdebug      = %s\n", $env->xdebug);
printf("script      = %s\n", $env->script);
printf("commandline = %s\n", $env->commandline);
printf("path        = %s\n", $env->path);

