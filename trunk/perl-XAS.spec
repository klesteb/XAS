Name:           perl-XAS
Version:        0.12
Release:        1%{?dist}
Summary:        XAS - Middleware for Datacener Operations
License:        GPL+ or Artistic
Group:          Development/Libraries
URL:            http://search.cpan.org/dist/XAS/
Source0:        http://www.cpan.org/modules/by-module/XAS/XAS-%{version}.tar.gz
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildArch:      noarch
BuildRequires:  perl(Test::More)
BuildRequires:  perl(Module::Build)
Requires:       perl(Badger) >= 0.09
Requires:       perl(POE) >= 1.35
Requires:       perl(DateTime) >= 0.53
Requires:       perl(DateTime::Format::Strptime) >= 1.1
Requires:       perl(DateTime::Format::Pg) >= 0.0
Requires:       perl(Config::IniFiles) >= 2.72
Requires:       perl(Hash::Merge) >= 0.12
Requires:       perl(HTTP::Response) >= 0.0
Requires:       perl(JSON::XS) >= 2.27
Requires:       perl(LockFile::Simple) >= 0.207
Requires:       perl(MIME::Lite) >= 3.027
Requires:       perl(Params::Validate) >= 0.92
Requires:       perl(Pod::Usage) >= 1.35
Requires:       perl(Try::Tiny) >= 0.0
Requires:       perl(Try::Tiny::Retry) >= 0.0
Requires:       perl(Set::Light) >= 0.04
Requires:       perl(Net::SSH2) >= 0.44
Requires:       perl(WWW::Curl) >= 4.15
Requires:       perl(XML::LibXML) => 0.0
Requires:       perl(:MODULE_COMPAT_%(eval "`%{__perl} -V:version`"; echo $version))

%define _initrddir  %{_sysconfdir}/init.d
%define _sysconfigs %{_sysconfdir}/sysconfig
%define _logrotated %{_sysconfdir}/logrotate.d
%define _profiled   %{_sysconfdir}/profile.d

%if 0%{?rhel} == 6
%define _mandir /usr/local/share/man
%{?filter_setup: %{?perl_default_filter} }
%filter_from_requires /Win32/d
%filter_from_provides /Win32/d
%filter_setup
Requires:       perl(Pod::Usage) >= 1.51
Requires:       perl(Sys::Syslog) >= 0.27
Requires:       perl(JSON::XS) >= 2.27
%endif

%description
This is middleware for datacenter operations. It is cross platform capable.

%pre
getent group xas >/dev/null || groupadd -f -r xas
if ! getent passwd xas >/dev/null ; then
    useradd -r -g xas -d /var/lib/xas -s /sbin/nologin -c "XAS" xas
fi
exit 0

%prep
%setup -q -n XAS-%{version}

%if 0%{?rhel} == 5

cat << \EOF > %{name}-prov
#!/bin/sh
%{__perl_provides} $* | sed -e '/Win32/d'
EOF
%global __perl_provides %{_builddir}/XAS-%{version}/%{name}-prov
chmod +x %{__perl_provides}

cat << \EOF > %{name}-req
#!/bin/sh
%{__perl_requires} $* | sed -e '/Win32/d'
EOF
%global __perl_requires %{_builddir}/XAS-%{version}/%{name}-req
chmod +x %{__perl_requires}

%endif

%build
%{__perl} Build.PL --installdirs vendor
./Build

%install
rm -rf $RPM_BUILD_ROOT

install -m 755 -d %{buildroot}/etc/xas
install -m 775 -d %{buildroot}/var/lib/xas
install -m 775 -d %{buildroot}/var/run/xas
install -m 775 -d %{buildroot}/var/log/xas
install -m 775 -d %{buildroot}/var/spool/xas
install -m 775 -d %{buildroot}/var/spool/xas/alerts
install -m 775 -d %{buildroot}/var/spool/xas/logs

./Build install --destdir $RPM_BUILD_ROOT create_packlist=0
./Build redhat --destdir $RPM_BUILD_ROOT

find $RPM_BUILD_ROOT -depth -type d -exec rmdir {} 2>/dev/null \;
%{_fixperms} $RPM_BUILD_ROOT/*

%check
./Build test

%post
chown -R root.xas /etc/xas
chown -R xas.xas  /var/lib/xas
chown -R xas.xas  /var/log/xas
chown -R xas.xas  /var/run/xas
chown -R xas.xas  /var/spool/xas

chmod g+ws /var/lib/xas
chmod g+ws /var/run/xas
chmod g+ws /var/log/xas
chmod g+ws /var/spool/xas
chmod g+ws /var/spool/xas/alerts
chmod g+ws /var/spool/xas/logs

%postun
if [ "$1" = 0 ]; then
    rm -Rf /etc/xas
    rm -Rf /var/lib/xas
    rm -Rf /var/run/xas
    rm -Rf /var/log/xas
    rm -Rf /var/spool/xas
fi

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
%doc Changes perl-XAS.spec README
%{perl_vendorlib}/*
%config(noreplace) %{_profiled}/xas.sh
%{_manddir}/*
%{_sysconfdir}/*

%changelog
* Tue Sep 24 2013 kesteb 0.07-1
- Specfile autogenerated by cpanspec 1.78.
