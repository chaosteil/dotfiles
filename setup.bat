:: Should be run as admin to setup the symlinks
git submodule update --init

del "%UserProfile%\_vimrc"
mklink /H "%UserProfile%\_vimrc" vimrc

rmdir /s /q "%UserProfile%\vimfiles"
mklink /J "%UserProfile%\vimfiles" vim 

vim +BundleInstall +qall
