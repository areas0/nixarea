{ ... }:
{
  programs.git = {
    enable = true;
    userName = "areas0";
    userEmail = "areas0@outlook.com";
    extraConfig = {
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
