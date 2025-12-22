{ ... }:
{
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "areas0";
        email = "areas0@outlook.com";
      };
      init.defaultBranch = "main";
      push.merge = true;
      commit.verbose = true;
      rebase = {
        autoStash = true;
        autoSquash = true;
      };
      core = {
        editor = "vim";
        autocrlf = "input";
      };
      pull.ff = "only";
    };
  };
}
