Name:           harbour-mygame
Version:        1.0.0
Release:        1
Summary:        Your game's one-line description here
License:        Proprietary

# The binary is a pre-built Godot SailfishOS export template.
# rpmbuild is only used for packaging, not compilation.
# Binary is already stripped; skip brp/strip to avoid failure on cross-arch build host.
%define __strip /bin/true
%define __os_install_post %{nil}

# SDL2 is linked by the Godot SailfishOS template binary.
Requires:       SDL2
# EGL and GLES are NOT listed here: they are provided by the hybris GPU driver
# stack on SailfishOS devices and are not registered as RPM capabilities, so
# declaring them as Requires causes "nothing provides" install failures.

%description
Your longer game description here.

%prep
# Nothing to build — binary and pck are pre-exported by the Godot headless step.

%install
install -Dm 755 harbour-mygame \
    %{buildroot}%{_bindir}/harbour-mygame
install -Dm 644 harbour-mygame.pck \
    %{buildroot}%{_datadir}/harbour-mygame/harbour-mygame.pck
install -Dm 644 harbour-mygame.desktop \
    %{buildroot}%{_datadir}/applications/harbour-mygame.desktop
install -Dm 644 harbour-mygame.profile \
    %{buildroot}/etc/sailjail/permissions/harbour-mygame.profile
install -Dm 644 icons/86x86.png \
    %{buildroot}%{_datadir}/icons/hicolor/86x86/apps/harbour-mygame.png
install -Dm 644 icons/108x108.png \
    %{buildroot}%{_datadir}/icons/hicolor/108x108/apps/harbour-mygame.png
install -Dm 644 icons/128x128.png \
    %{buildroot}%{_datadir}/icons/hicolor/128x128/apps/harbour-mygame.png
install -Dm 644 icons/172x172.png \
    %{buildroot}%{_datadir}/icons/hicolor/172x172/apps/harbour-mygame.png

%files
/etc/sailjail/permissions/harbour-mygame.profile
%{_bindir}/harbour-mygame
%{_datadir}/harbour-mygame/harbour-mygame.pck
%{_datadir}/applications/harbour-mygame.desktop
%{_datadir}/icons/hicolor/86x86/apps/harbour-mygame.png
%{_datadir}/icons/hicolor/108x108/apps/harbour-mygame.png
%{_datadir}/icons/hicolor/128x128/apps/harbour-mygame.png
%{_datadir}/icons/hicolor/172x172/apps/harbour-mygame.png

%changelog
* Wed Jan 01 2025 Your Name <your@email.com> - 1.0.0-1
- Initial release
