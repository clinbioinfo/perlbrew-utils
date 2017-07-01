package Perlbrew::Utils::Manager;

use Moose;
use Cwd;
use Data::Dumper;
use File::Path;
use File::Compare;
use File::Copy;
use FindBin;
use File::Slurp;
use Term::ANSIColor;

use Perlbrew::Utils::Logger;
use Perlbrew::Utils::Config::Manager;

use constant TRUE  => 1;

use constant FALSE => 0;

use constant DEFAULT_TEST_MODE => FALSE;

use constant DEFAULT_USERNAME =>  getlogin || getpwuid($<) || $ENV{USER} || "sundaramj";

use constant DEFAULT_OUTDIR => '/tmp/' . DEFAULT_USERNAME . '/' . File::Basename::basename($0) . '/' . time();

use constant DEFAULT_INDIR => File::Spec->rel2abs(cwd());


## Singleton support
my $instance;

has 'test_mode' => (
    is       => 'rw',
    isa      => 'Bool',
    writer   => 'setTestMode',
    reader   => 'getTestMode',
    required => FALSE,
    default  => DEFAULT_TEST_MODE
    );

has 'config_file' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setConfigfile',
    reader   => 'getConfigfile',
    required => FALSE,
    );

has 'outdir' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setOutdir',
    reader   => 'getOutdir',
    required => FALSE,
    default  => DEFAULT_OUTDIR
    );

has 'indir' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setIndir',
    reader   => 'getIndir',
    required => FALSE,
    default  => DEFAULT_INDIR
    );


sub getInstance {

    if (!defined($instance)){

        $instance = new Perlbrew::Utils::Manager(@_);

        if (!defined($instance)){

            confess "Could not instantiate Perlbrew::Utils::Manager";
        }
    }
    return $instance;
}

sub BUILD {

    my $self = shift;

    $self->_initLogger(@_);

    $self->_initConfigManager(@_);

    $self->{_logger}->info("Instantiated ". __PACKAGE__);
}

sub _initLogger {

    my $self = shift;

    my $logger = Log::Log4perl->get_logger(__PACKAGE__);

    if (!defined($logger)){
        confess "logger was not defined";
    }

    $self->{_logger} = $logger;
}

sub _initConfigManager {

    my $self = shift;

    my $manager = Perlbrew::Utils::Config::Manager::getInstance(@_);
    if (!defined($manager)){
        $self->{_logger}->logconfess("Could not instantiate Perlbrew::Utils::Config::Manager");
    }

    $self->{_config_manager} = $manager;
}

sub run {

    my $self = shift;

    $self->_display_perlbrew_info();
    
    $self->_display_options();
}

sub _display_perlbrew_info {

    my $self = shift;
    
    my $cmd = "perlbrew info";

    my $results = $self->_execute_cmd($cmd);

    # $self->_print_blue_banner($cmd);

    printBrightBlue("Here is the current info:\n\n");

    printBrightBlue(join("\n", @{$results})) . "\n";
}


sub _display_options {

    my $self = shift;
    
    my $options_list = [
    'Perl - List all available versions of Perl',
    'Perl - List all installed versions of Perl',
    'Perl - Install a new version of Perl',
    'Venv - List all virtual environments',
    'Venv - Use a virtual environment',
    'Venv - Create a new virtual environment',
    'Venv - List all modules installed in a virtual environment',
    'Venv - Generate modules list file for a virtual environment',
    'Quit'
    ];

    my $option_lookup = {};

    my $option_ctr = 0;

    print "\n";

    foreach my $option (@{$options_list}){

        $option_ctr++;
        
        print $option_ctr . '. ' . $option . "\n";


        $option_lookup->{$option_ctr} = $option;
    }

    my $try_ctr = 0;

    my $answer;

    while (1){

        print "\nPlease choose an option : ";

        $answer = <STDIN>;

        chomp $answer;

        if (exists $option_lookup->{$answer}){
            last;
        }

        if ($try_ctr > 3){
            printBoldRed("You have issues.");
            exit(1);
        }

        $try_ctr++;
    }


    my $val = $option_lookup->{$answer};
    
    if ($val eq 'Quit'){
        print "Bye.\n";
        exit(0);
    } 
    elsif ($val eq 'Perl - List all available versions of Perl'){
        $self->_display_all_available_versions_of_perl();
    }
    elsif ($val eq 'Perl - List all installed versions of Perl'){
        $self->_display_all_installed_versions_of_perl();
    }    
    elsif ($val eq 'Perl - Install a new version of Perl'){
        $self->_install_new_version_of_perl()
    }
    elsif ($val eq 'Venv - List all virtual environments'){
        $self->_list_all_virtual_environments();
    }
    elsif ($val eq 'Venv - Use a virtual environment'){
        $self->_use_virtual_environment();
    }
    elsif ($val eq 'Venv - Create a new virtual environment'){
        $self->_create_new_virtual_environment();
    }
    elsif ($val eq 'Venv - List all modules installed in a virtual environment'){
        $self->_list_all_modules_installed_in_virtual_environment();
    }
    elsif ($val eq 'Venv - Generate modules list file for a virtual environment'){
        $self->_generate_modules_list_file_for_virtual_environment();
    }
    else {
        $self->{_logger}->logconfess("Unexpected option '$val'");
    }
}

sub _display_all_available_versions_of_perl {

    my $self = shift;
    
    my $cmd = 'perlbrew available';

    my $results = $self->_execute_cmd($cmd);

    printBrightBlue("Print here are the available versions of Perl:\n");

    print join("\n", @{$results}) . "\n\n";

    $self->_display_options();
}

sub _display_all_installed_versions_of_perl {

    my $self = shift;
    
    my $cmd = 'perlbrew list';

    my $results = $self->_execute_cmd($cmd);

    printBrightBlue("Print here are the installed versions of Perl:\n");

    print join("\n", @{$results}) . "\n\n";

    $self->_display_options();
}

sub _install_new_version_of_perl {

    my $self = shift;

    my $cmd = 'perlbrew list';

    my $results = $self->_execute_cmd($cmd);

    printBrightBlue("Print here are the available versions of Perl:\n");


    my $option_lookup = {};

    my $option_ctr = 0;

    foreach my $version (@{$results}){

        $option_ctr++;

        print $option_ctr . '. ' . $version . "\n";

        $option_lookup->{$option_ctr} = $version;
    }

    my $try_ctr = 0;

    my $answer;

    while (1){

        print "\nWhich would you like to install? ";

        $answer = <STDIN>;

        chomp $answer;

        if (exists $option_lookup->{$answer}){
            last;
        }

        $try_ctr++;

        if ($try_ctr > 3){
            printBoldRed("Seriously?");
            exit(1);
        }
    }

    my $val = $option_lookup->{$answer};
    
    printBrightBlue("Will install Perl version '$val'\n");

    my $cmd2 = "perlbrew install $val";

    $self->_execute_cmd($cmd2);


    printBrightBlue("Perl version '$val' has been installed\n");

    $self->_display_options();
}

sub _list_all_virtual_environments {

    my $self = shift;
    
    my $cmd = 'perlbrew lib list';

    my $results = $self->_execute_cmd($cmd);

    printBrightBlue("Print here are your virtual environments:\n");

    print join("\n", @{$results}) . "\n\n";

    $self->_display_options();

}


sub _use_virtual_environment {

    my $self = shift;

    my $cmd = 'perlbrew lib list';

    my $results = $self->_execute_cmd($cmd);

    printBrightBlue("Print here are your virtual environments:\n");


    my $option_lookup = {};

    my $option_ctr = 0;

    foreach my $version (@{$results}){

        $option_ctr++;

        print $option_ctr . '. ' . $version . "\n";

        $option_lookup->{$option_ctr} = $version;
    }

    my $try_ctr = 0;

    my $answer;

    while (1){

        print "\nWhich one do you want to use dawg? ";

        $answer = <STDIN>;

        chomp $answer;

        if (exists $option_lookup->{$answer}){
            last;
        }

        $try_ctr++;

        if ($try_ctr > 3){

            printBoldRed("Seriously?");

            exit(1);
        }
    }

    my $val = $option_lookup->{$answer};
    
    print "Use it by typing the following:\n";

    print "perlbrew use $val\n";

    exit(0);
}

sub _create_new_virtual_environment {

    my $self = shift;
    
    my $cmd = 'perlbrew list | grep -v @';

    my $results = $self->_execute_cmd($cmd);

    printBrightBlue("Print here are your installed versions of Perl:\n");

    my $option_lookup = {};

    my $option_ctr = 0;

    foreach my $version (@{$results}){

        $option_ctr++;

        print $option_ctr . '. ' . $version . "\n";

        $option_lookup->{$option_ctr} = $version;
    }

    my $try_ctr = 0;

    my $answer;

    while (1){

        print "\nWhich one do you want to use to create your new virtual environment? ";

        $answer = <STDIN>;

        chomp $answer;

        if (exists $option_lookup->{$answer}){
            
            last;
        }

        $try_ctr++;

        if ($try_ctr > 3){

            printBoldRed("Later homes.");
            
            exit(1);
        }
    }

    my $val = $option_lookup->{$answer};
    
    print "What name do you want to give your venv? (use alphabets only) ";

    my $answer2;

    while (1){

        $answer2 = <STDIN>;

        chomp $answer2;

        if ($answer2 =~ m|^[[:alpha:]]{3,15}$|){

            last;
        }
        else {
            print "Please try again\n";
        }
    }

    my $name = $val . '@' . $answer2;

    my $cmd2 = "perlbrew lib create $name";

    $self->_execute_cmd($cmd2);

    printBrightBlue("\nHave created the new virtual environment '$name'\n");

    print "Use it by typing:\n";
    
    print "perlbrew use $name\n";

    exit(0);
}

sub _list_all_modules_installed_in_virtual_environment {

    my $self = shift;

    my $cmd = 'perlbrew lib list';

    my $results = $self->_execute_cmd($cmd);

    printBrightBlue("Print here are your virtual environments:\n");


    my $option_lookup = {};

    my $option_ctr = 0;

    foreach my $version (@{$results}){

        $option_ctr++;

        print $option_ctr . '. ' . $version . "\n";

        $option_lookup->{$option_ctr} = $version;
    }

    my $try_ctr = 0;

    my $answer;

    while (1){

        print "\nWhich one's modules do you want to inspect? ";

        $answer = <STDIN>;

        chomp $answer;

        if (exists $option_lookup->{$answer}){
            last;
        }

        $try_ctr++;

        if ($try_ctr > 3){

            printBoldRed("Loser.  Get lost.");

            exit(1);
        }
    }

    my $val = $option_lookup->{$answer};
    
    my $cmd2 = 'perlbrew exec --with ' . $val . " 'perlbrew list-modules'";

    # print "Execute the following:\n";

    # print $cmd2 . "\n";

    my $results = $self->_execute_cmd($cmd2);

    printBrightBlue("\nHere are the modules installed in virtual environment $val:\n");

    print join("\n", @{$results}) . "\n";

    $self->_display_options();
}

sub _generate_modules_list_file_for_virtual_environment {

    my $self = shift;
    $self->{_logger}->fatal("NOT YET IMPLEMENTED");
}



sub printBoldRed {

    my ($msg) = @_;
    print color 'bold red';
    print $msg . "\n";
    print color 'reset';
}

sub printGreen {

    my ($msg) = @_;
    print color 'green';
    print $msg . "\n";
    print color 'reset';
}

sub printYellow {

    my ($msg) = @_;
    print color 'yellow';
    print $msg . "\n";
    print color 'reset';
}

sub printBrightBlue {

    my ($msg) = @_;
    print color 'bright_blue';
    print $msg . "\n";
    print color 'reset';
}

sub _execute_cmd {
    
    my $self = shift;

    my ($cmd) = @_;
    if (!defined($cmd)){
        $self->{_logger}->logconfess("cmd was not defined");
    }

    $self->{_logger}->info("About to execute '$cmd'");

    my @results;

    eval {
        @results = qx($cmd);
    };

    if ($?){
        $self->{_logger}->logconfess("Encountered some error while attempting to execute '$cmd' : $! $@");
    }

    chomp @results;

    return \@results;
}    


no Moose;
__PACKAGE__->meta->make_immutable;

__END__


=head1 NAME

 Perlbrew::Utils::Manager
 A module for managing perlbrew actions and activities.

=head1 VERSION

 1.0

=head1 SYNOPSIS

 use Perlbrew::Utils::Manager;
 my $manager = Perlbrew::Utils::Manager::getInstance();
 $manager->run();

=head1 AUTHOR

 Jaideep Sundaram

 Copyright Jaideep Sundaram

=head1 METHODS

=over 4

=cut