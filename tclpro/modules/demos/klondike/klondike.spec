Summary: Klondike solitare game
Name: klondike
Version: 1.9
Release: 1
Copyright: GPL
Group: Games
Source: http://www.isi.edu/~johnh/SOFTWARE/JACOBY/klondike-1.9.tar.gz

%description
Klondike is a solitaire game for X11.  It's strongly influenced
by the user interface of Klondike for the Macintosh.

Features of klondike include:
	- time-based and Casino-style scoring
	- persistent high score list
	- on-line help


%prep
%setup

%build
./configure --bindir=/usr/games --datadir=/usr/lib/games --mandir=/usr/man
make

%install
make install

%files
%doc README
/usr/games/klondike
/usr/lib/games/klondike
/usr/man/man6/klondike.6
