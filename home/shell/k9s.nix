{ pkgs-unstable, ... }:
let

  cnpg-repo = pkgs-unstable.fetchFromGitHub {
    owner = "cloudnative-pg";
    repo = "cloudnative-pg";
    rev = "v1.28.0";
    sha256 = "sha256-WIcT4LfoIZ8BctwrUgn+mLbqwJ2NZx6Sc5sJeT9fsut=";
  };

  k9s-repo = pkgs-unstable.fetchFromGitHub {
    owner = "derailed";
    repo = "k9s";
    rev = "${pkgs-unstable.k9s.version}";
    sha256 = "sha256-WIcT4LfoIZ8BctwrUgn+mLbqwJ2NZx6Sc5sJeT9fsus=";
  };

  additionalPlugins = {
    officials = [
      "argocd"
      "argo-workflows"
      "remove-finalizers"
      "pvc-debug-container"
    ];
    dir = ".config/k9s/plugins";
  };

  files = (
    builtins.listToAttrs (
      (map (p: {
        name = "${additionalPlugins.dir}/${p}.yaml";
        value = {
          source = "${k9s-repo}/plugins/${p}.yaml";
        };
      }) additionalPlugins.officials)
      ++ [
        {
          name = "${additionalPlugins.dir}/cnpg.yaml";
          value = {
            source = "${cnpg-repo}/docs/src/samples/k9s/plugins.yml";
          };
        }
      ]
    )
  );
in
{
  programs.k9s = {
    enable = true;
    package = pkgs-unstable.k9s;

    aliases = {
      dp = "deployments";
      sec = "v1/secrets";
      jo = "jobs";
      cr = "clusterroles";
      crb = "clusterrolebindings";
      ro = "roles";
      rb = "rolebindings";
      np = "networkpolicies";

      # custom aliases for padoa clusters
      med = "pod postgres-operator.crunchydata.com/role=master,pg.stackinfo.padoa.fr/medical=true";
      fargo = "pod postgres-operator.crunchydata.com/role=master,pg.stackinfo.padoa.fr/fargo=true";
      stats = "pod postgres-operator.crunchydata.com/role=master,pg.stackinfo.padoa.fr/stats=true";
    };

    plugins = {
      ### Custom CNPG Plugin for K9s ###
      cnpg-backup = {
        shortCut = "b";
        description = "Backup";
        scopes = [ "cluster" ];
        command = "bash";
        confirm = true;
        background = false;
        args = [
          "-c"
          "kubectl cnpg backup $NAME -n $NAMESPACE --context \"$CONTEXT\" 2>&1 | less -R"
        ];
      };

      cnpg-hibernate-status = {
        shortCut = "h";
        description = "Hibernate status";
        scopes = [ "cluster" ];
        command = "bash";
        background = false;
        args = [
          "-c"
          "kubectl cnpg hibernate status $NAME -n $NAMESPACE --context \"$CONTEXT\" 2>&1 | less -R"
        ];
      };

      cnpg-hibernate = {
        shortCut = "Shift-H";
        description = "Hibernate";
        confirm = true;
        scopes = [ "cluster" ];
        command = "bash";
        background = false;
        args = [
          "-c"
          "kubectl cnpg hibernate on $NAME -n $NAMESPACE --context \"$CONTEXT\" 2>&1 | less -R"
        ];
      };

      cnpg-hibernate-off = {
        shortCut = "Shift-H";
        description = "Wake up hibernated cluster in this namespace";
        confirm = true;
        scopes = [ "namespace" ];
        command = "bash";
        background = false;
        args = [
          "-c"
          "kubectl cnpg hibernate off $NAME -n $NAME --context \"$CONTEXT\" 2>&1 | less -R"
        ];
      };

      cnpg-logs = {
        shortCut = "l";
        description = "Logs";
        scopes = [ "cluster" ];
        command = "bash";
        background = false;
        args = [
          "-c"
          "kubectl cnpg logs cluster $NAME -f -n $NAMESPACE --context $CONTEXT"
        ];
      };

      cnpg-logs-pretty = {
        shortCut = "Shift-L";
        description = "Logs pretty";
        scopes = [ "cluster" ];
        command = "bash";
        background = false;
        args = [
          "-c"
          "kubectl cnpg logs cluster $NAME -f -n $NAMESPACE --context $CONTEXT | kubectl cnpg logs pretty"
        ];
      };

      cnpg-psql = {
        shortCut = "p";
        description = "PSQL shell";
        scopes = [ "cluster" ];
        command = "bash";
        background = false;
        args = [
          "-c"
          "kubectl cnpg psql $NAME -n $NAMESPACE --context $CONTEXT"
        ];
      };

      cnpg-reload = {
        shortCut = "r";
        description = "Reload";
        confirm = true;
        scopes = [ "cluster" ];
        command = "bash";
        background = false;
        args = [
          "-c"
          "kubectl cnpg reload $NAME -n $NAMESPACE --context \"$CONTEXT\" 2>&1 | less -R"
        ];
      };

      cnpg-restart = {
        shortCut = "Shift-R";
        description = "Restart";
        confirm = true;
        scopes = [ "cluster" ];
        command = "bash";
        background = false;
        args = [
          "-c"
          "kubectl cnpg restart $NAME -n $NAMESPACE --context \"$CONTEXT\" 2>&1 | less -R"
        ];
      };

      cnpg-status = {
        shortCut = "st";
        description = "Status";
        scopes = [ "cluster" ];
        command = "bash";
        background = false;
        args = [
          "-c"
          "kubectl cnpg status $NAME -n $NAMESPACE --context \"$CONTEXT\" 2>&1 | less -R"
        ];
      };

      cnpg-status-verbose = {
        shortCut = "Shift-S";
        description = "Status (verbose)";
        scopes = [ "cluster" ];
        command = "bash";
        background = false;
        args = [
          "-c"
          "kubectl cnpg status $NAME -n $NAMESPACE --context \"$CONTEXT\" --verbose 2>&1 | less -R"
        ];
      };

      ### crunchy-pgo commands ###
      pgo-exec-master = {
        shortCut = "P";
        description = "PGO Exec Master";
        scopes = [ "postgrescluster" ];
        command = "bash";
        background = false;
        args = [
          "-c"
          "kubectl exec -it $(kubectl get pods -n \"$NAMESPACE\" -l postgres-operator.crunchydata.com/cluster==$NAME,postgres-operator.crunchydata.com/role=master -o jsonpath='{.items[0].metadata.name}') -n \"$NAMESPACE\" --context \"$CONTEXT\" -- bash"
        ];
      };
    };
  };

  home.file = files;
}
