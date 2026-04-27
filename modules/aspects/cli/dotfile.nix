{ ... }:

{
  my.dotfile.homeManager = {
    home.file.editRc = {
      source = ./_dotfile/editrc;
      target = ".editrc";
    };
  };
}
