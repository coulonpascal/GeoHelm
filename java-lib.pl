=head1 java-lib.pl

Functions for managing Oracle JDK installations.

  foreign_require("tomcat", "tomcat-lib.pl");
  @sites = tomcat::list_tomcat_websites()

=cut

#BEGIN { push(@INC, ".."); };
use warnings;
use WebminCore;

sub get_latest_jdk_version(){
	my $error;
	my $url = 'http://www.oracle.com/technetwork/java/javase/downloads/index.html';
	$tmpfile = &transname("javase.html");
	&error_setup(&text('install_err3', $url));
	&http_download("www.oracle.com", 80, "/technetwork/java/javase/downloads/index.html", $tmpfile, \$error,
					undef, 0, undef, 0, 0, 1);

	my $download_num = '';
	open(my $fh, '<', $tmpfile) or die "open:$!";
	while(my $line = <$fh>){
		if($line =~ /\/technetwork\/java\/javase\/downloads\/jdk8-downloads-([0-9]+)\.html/){
			$download_num = $1;
			last;
		}
	}
	close $fh;


	$url = "http://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-$download_num.html";
	$tmpfile = &transname("sdk.html");
	&error_setup(&text('install_err3', $url));
	my %cookie_headers = ('Cookie'=> 'oraclelicense=accept-securebackup-cookie');
	&http_download("www.oracle.com", 80,"/technetwork/java/javase/downloads/jdk8-downloads-$download_num.html",
					$tmpfile, \$error, undef, 0, undef, undef, 0, 0, 1, \%cookie_headers);

	my %java_tar_gz;
	open($fh, '<', $tmpfile) or die "open:$!";
	while(my $line = <$fh>){
		if($line =~ /"filepath":"(http:\/\/download.oracle.com\/otn-pub\/java\/jdk\/([a-z0-9-]+)\/[a-z0-9]+\/jdk-[a-z0-9-]+-linux-x64.tar.gz)/){
			$java_tar_gz{$2} = $1;
			last;
		}
	}
	close $fh;

	return %java_tar_gz;
}

sub get_installed_oracle_jdk_versions{
	my @dirs;
    opendir(DIR, '/usr/java/') or return @dirs;
    @dirs
        = grep {
	    /^jdk1.8.[0-9]+_[0-9]+/ 
          && -d "/usr/java/$_"  
	} readdir(DIR);
    closedir(DIR);

    return sort @dirs;
}

sub is_default_jdk{
	my $jdk_dir = $_[0];

	my %os_env;
	if(-f '/etc/profile.d/jdk8.sh'){
		read_env_file('/etc/profile.d/jdk8.sh', \%os_env);
	}elsif(-f '/etc/environment'){
		read_env_file('/etc/environment', \%os_env);
	}

	if($os_env{'JAVA_HOME'} eq $jdk_dir){
		return 1;
	}else{
		return 0;
	}
}

sub get_java_version(){
	local %version;
	local $out = &backquote_command('java \-version 2>&1');

	if ($out =~ /java\sversion\s\"([0-9]\.([0-9])\.[0-9]_[0-9]+)\"/) {
		$version{'major'} = $2;
		$version{'full'} = $1;
	}else {
		$version{'major'} = 0;
		$version{'full'} = $out;
	}
	return %version;
}

sub get_java_home(){
	my %jdk_ver = get_java_version();
	return '/usr/java/jdk'.$jdk_ver{'full'};
}

1;
