:: Should be run as admin to setup the symlinks
git submodule update --init

del "%UserProfile%\_vimrc"
mklink /H vimrc "%UserProfile%\_vimrc"

rmdir /s /q "%UserProfile%\vimfiles"
mklink /J vim "%UserProfile%\vimfiles"

vim +BundleInstall +qall
